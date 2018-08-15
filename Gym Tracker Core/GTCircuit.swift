//
//  GTCircuit.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTCircuit)
final class GTCircuit: GTExercize, ExercizeCollection {
	
	override class var objectType: String {
		return "GTCircuit"
	}
	
	@NSManaged private(set) var exercizes: Set<GTSetsExercize>
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTCircuit? {
		let req = NSFetchRequest<GTCircuit>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override var isValid: Bool {
		return validityStatus.global
	}
	
	override var parentLevel: CompositeWorkoutLevel? {
		return workout
	}
	
	/// Whether or not the workout is valid.
	///
	/// The workout is valid if the underling `Workout` is valid and all exercizes in a circuit have the same number of sets.
	///
	/// An exercize has its index in `exercizeList` included in `circuitError` if it has not the same number of sets as the most frequent sets count in the circuit.
	var validityStatus: (global: Bool, circuitError: [Int]) {
		var global = workout != nil && exercizes.count > 1
		var circuitError = [Int]()
		
		let counts = exercizeList.map { e -> Int? in
			global = global && e.isValid
			
			return e.setsCount
		}
		
		if !counts.isEmpty {
			var counter = [Int?: Int]()
			var max = 0
			var mode: Int?
			
			for i in counts {
				let count = (counter[i] ?? 0) + 1
				counter[i] = count
				
				if count == max {
					mode = mode ?? max
				} else if count > max {
					mode = i
					max = count
				}
			}
			
			circuitError.append(contentsOf: (zip(counts, 0 ..< counts.count).filter { $0.0 == nil || $0.0 != mode }.map { $0.1 }))
		}
		
		return (global && !circuitError.isEmpty, circuitError)
	}
	
	// MARK: - Exercizes handling
	
	var exercizeList: [GTSetsExercize] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}
	
	func add(parts: GTSetsExercize...) {
		for se in parts {
			se.order = Int32(self.exercizes.count)
			se.set(circuit: self)
		}
	}
	
	func remove(part se: GTSetsExercize) {
		exercizes.remove(se)
		recalculatePartsOrder()
	}
	
}
