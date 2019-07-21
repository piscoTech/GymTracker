//
//  GTRest.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTRest)
final public class GTRest: GTPart {
	
	static public let restStep: TimeInterval = 30
	static let minRest: TimeInterval = 30
	static public let maxRest: TimeInterval = 10 * 60
	
	override class var objectType: String {
		return "GTRest"
	}
	
	static private let restKey = "rest"
		
	@NSManaged public private(set) var rest: TimeInterval
	
	override public var parentLevel: CompositeWorkoutLevel? {
		return workout
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTRest? {
		let req = NSFetchRequest<GTRest>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	public func set(rest r: TimeInterval) {
		rest = max(r, GTRest.minRest).rounded(to: GTRest.restStep)
	}
	
	override public var isValid: Bool {
		return workout != nil && isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		return rest >= GTRest.minRest
	}
	
	override public var subtreeNodes: Set<GTDataObject> {
		return [self]
	}
	
	public override var isPurgeableToValid: Bool {
		return false
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		return []
	}
	
	public override var shouldBePurged: Bool {
		return false
	}
	
	public override func removePurgeable() -> [GTDataObject] {
		return []
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[Self.restKey] = rest
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let rest = src[Self.restKey] as? TimeInterval else {
				return false
		}
		
		self.rest = rest
		
		return true
	}
	
}
