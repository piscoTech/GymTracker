//
//  WorkoutIterator.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

class WorkoutIterator: IteratorProtocol {
	
	let workout: OrganizedWorkout
	
	/// Create an iterator over a workout.
	///
	/// Before starting, i.e. calling `next()` for the first time, make sure all circuit settings are valid, i.e. make sure to call `purgeInvalidSettings()`. After starting make sure not to change the workout in any manner but changing a `Set` weight.
	init(_ w: OrganizedWorkout) {
		workout = w
	}
	
	func next() -> WorkoutStep? {
		guard workout.validityStatus.global else {
			return nil
		}
		
		return nil
	}
	
}
