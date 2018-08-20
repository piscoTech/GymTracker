//
//  GTSet+CoreDataProperties.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTSet)
public class GTSet: GTDataObject {
	
	private let minRest: TimeInterval = 0
	
	final private let exercizeKey = "exercize"
	final private let orderKey = "order"
	final private let restKey = "rest"
	
    @NSManaged final var exercize: GTSimpleSetsExercize
	@NSManaged final public var order: Int32
	
	@NSManaged final public private(set) var rest: TimeInterval

	override public var isValid: Bool {
		// A low-level CoreData access is needed to check validity
		return isSubtreeValid && self.value(forKey: "exercize") is GTSimpleSetsExercize
	}
	
	override var isSubtreeValid: Bool {
		return rest >= 0
	}
	
	public func set(rest r: TimeInterval) {
		rest = max(r, minRest).rounded(to: GTRest.restStep)
	}
	
	public var mainInfo: Int {
		fatalError("Abstract property not implemented")
	}
	
	func mainInfoDescription(with change: Double) -> NSAttributedString {
		fatalError("Abstract method not implemented")
	}
	
	public var secondaryInfo: Double {
		fatalError("Abstract property not implemented")
	}
	
	public var secondaryInfoLabel: NSAttributedString {
		fatalError("Abstract property not implemented")
	}
	
	public func set(mainInfo n: Int) {
		fatalError("Abstract method not implemented")
	}
	
	public func set(secondaryInfo s: Double) {
		fatalError("Abstract method not implemented")
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[exercizeKey] = exercize.recordID.wcRepresentation
		obj[orderKey] = order
		obj[restKey] = rest
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let exercize = CDRecordID(wcRepresentation: src[exercizeKey] as? [String])?.getObject(fromDataManager: dataManager) as? GTSimpleSetsExercize,
			let order = src[orderKey] as? Int32,
			let rest = src[restKey] as? TimeInterval else {
				return false
		}
		
		self.exercize = exercize
		self.order = order
		self.rest = rest
		
		return true
	}

}
