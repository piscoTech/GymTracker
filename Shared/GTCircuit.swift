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
	
	override var parent: GTDataObject {
		return workout!
	}
	
	var exercizeList: [GTSetsExercize] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}
	
	/// Whether or not the workout is valid.
	///
	/// The workout is valid if the underling `Workout` is valid and all exercizes in a circuit have the same number of sets.
	///
	/// An exercize has its index included in `circuitError` if it's considered invalid due to the circuit it belongs to, i.e. it has not the same number of sets as the most frequent sets count in the circuit.
	var validityStatus: (global: Bool, circuitError: Set<Int>) {
		var global = workout != nil && exercizes.count > 1
		var circuitError = Set<Int>()
		
		var circuitSetsInfo: (first: Int, counts: [Int])?
		for e in exercizes {
			global = global && e.isValid
			
			if e.isCircuit, circuitSetsInfo == nil {
				circuitSetsInfo = (Int(e.order), [])
			}
			circuitSetsInfo?.counts.append(e.sets.count)
			
			if !e.isCircuit {
				if let (start, counts) = circuitSetsInfo {
					var counter = [Int: Int]()
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
					
					circuitError.formUnion(zip(counts, 0 ..< counts.count).filter { $0.0 != mode }.map { $0.1 + start })
				}
				
				circuitSetsInfo = nil
			}
		}
		
		return (global && circuitError.isEmpty, circuitError)
	}
	
	#error("Exercizes accessors")
	
	// MARK: - iOS/watchOS interface

	#error("Override from GTDataObject")
	
}
