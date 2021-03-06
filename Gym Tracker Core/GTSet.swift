//
//  GTSet+CoreDataProperties.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(GTSet)
public class GTSet: GTDataObject {
	
	private let minRest: TimeInterval = 0
	
	static private let exerciseKey = "exercize"
	static private let orderKey = "order"
	static private let restKey = "rest"
	
    @NSManaged final var exercise: GTSimpleSetsExercise
	@NSManaged final public var order: Int32
	
	@NSManaged final public private(set) var rest: TimeInterval
	
	override public var description: String {
		fatalError("Abstract property not implemented")
	}
	
	public func descriptionWithSecondaryInfoChange(from ctrl: ExecuteWorkoutController) -> NSAttributedString {
		return NSAttributedString(string: description)
	}

	override public var isValid: Bool {
		// A low-level CoreData access is needed to check validity
		return isSubtreeValid && self.value(forKey: "exercise") is GTSimpleSetsExercise
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
		
		obj[Self.exerciseKey] = exercise.recordID.wcRepresentation
		obj[Self.orderKey] = order
		obj[Self.restKey] = rest
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let exercise = CDRecordID(wcRepresentation: src[Self.exerciseKey] as? [String])?.getObject(fromDataManager: dataManager) as? GTSimpleSetsExercise,
			let order = src[Self.orderKey] as? Int32,
			let rest = src[Self.restKey] as? TimeInterval else {
				return false
		}
		
		self.exercise = exercise
		self.order = order
		self.rest = rest
		
		return true
	}

}
