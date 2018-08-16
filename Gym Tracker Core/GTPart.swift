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
class GTPart: GTDataObject, WorkoutLevel {
	
	final private let workoutKey = "workout"
	final private let orderKey = "order"

	@NSManaged final private(set) var workout: GTWorkout?
    @NSManaged final var order: Int32
	
	/// Make the exercize a part of the given workout.
	///
	/// Unless when passing `nil`, don't call this method directly but rather call `add(parts:_)` on the workout.
	func set(workout w: GTWorkout?) {
		let old = self.workout
		
		self.workout = w
		old?.recalculatePartsOrder()
		#warning("Call recalculatePartsOrder() on old value, and test")
	}
	
	var parentLevel: CompositeWorkoutLevel? {
		fatalError("Abstract property not implemented")
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		if let w = workout?.recordID.wcRepresentation {
			obj[workoutKey] = w
		}
		obj[orderKey] = order
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let order = src[orderKey] as? Int32 else {
				return false
		}
		
		self.workout = CDRecordID(wcRepresentation: src[workoutKey] as? [String])?.getObject(fromDataManager: dataManager) as? GTWorkout
		self.order = order
		
		return true
	}

}
