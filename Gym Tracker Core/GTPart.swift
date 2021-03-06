//
//  GTPart.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTPart)
public class GTPart: GTDataObject, WorkoutLevel {
	
	static private let workoutKey = "workout"
	static private let orderKey = "order"

	@NSManaged final private(set) var workout: GTWorkout?
    @NSManaged final public var order: Int32
	
	/// Make the exercise a part of the given workout.
	///
	/// Unless when passing `nil`, don't call this method directly but rather call `add(parts:_)` on the workout.
	func set(workout w: GTWorkout?) {
		let old = self.workout
		
		self.workout = w
		old?.recalculatePartsOrder()
	}
	
	public var parentLevel: CompositeWorkoutLevel? {
		fatalError("Abstract property not implemented")
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		if let w = workout?.recordID.wcRepresentation {
			obj[Self.workoutKey] = w
		}
		obj[Self.orderKey] = order
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let order = src[Self.orderKey] as? Int32 else {
				return false
		}
		
		self.workout = CDRecordID(wcRepresentation: src[Self.workoutKey] as? [String])?.getObject(fromDataManager: dataManager) as? GTWorkout
		self.order = order
		
		return true
	}

}
