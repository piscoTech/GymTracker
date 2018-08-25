//
//  WorkoutToGTWorkout.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 23/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import CoreData

class WorkoutToGTWorkout: NSEntityMigrationPolicy {
	
	static private var exercizeLookupTable = [String: (NSManagedObject, Int32)]()
	
	/// Fetch the parent (a workout or a circuit) and order for the exercize of the given id.
	static func parentInfo(for exercizeId: String) -> (NSManagedObject, Int32)? {
		return exercizeLookupTable[exercizeId]
	}
	
	static func clearParentInfo() {
		exercizeLookupTable = [:]
	}
	
	let idKey = "id"
	let exercizesKey = "exercizes"

	override func createDestinationInstances(forSource src: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
		// Migrate the workout
		let srcKeys = Array(src.entity.attributesByName.keys)
		let srcValues = src.dictionaryWithValues(forKeys: srcKeys)
		
		let dst = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)
		let dstKeys = Array(dst.entity.attributesByName.keys)
		
		for k in dstKeys {
			if let srcV = srcValues[k], !(srcV is NSNull) {
				dst.setValue(srcV, forKey: k)
			}
		}
		
		// Analyze circuits
		let now = Date()
		let ex = (src.value(forKey: exercizesKey) as! Set<NSManagedObject>).sorted { (a, b) -> Bool in
			let ordA = a.value(forKey: ExercizeToGTPart.orderKey) as! Int32
			let ordB = b.value(forKey: ExercizeToGTPart.orderKey) as! Int32
			
			return ordA < ordB
		}
		
		let wrktId = src.value(forKey: idKey) as! String
		var prevCircuit = false
		var circuit: NSManagedObject?
		var order: Int32 = 0
		var inCircuitOrder: Int32 = 0
		for e in ex {
			let isCircuit = (e.value(forKey: ExercizeToGTPart.isCircuitKey) as? Bool) ?? false
			let id = e.value(forKey: ExercizeToGTPart.idKey) as! String
			
			if isCircuit || prevCircuit {
				let circ = circuit ?? { () -> NSManagedObject in
					let c = NSEntityDescription.insertNewObject(forEntityName: ExercizeToGTPart.circuitType, into: manager.destinationContext)
					c.setValue(now, forKey: ExercizeToGTPart.modifiedKey)
					c.setValue(wrktId + "-circuit-\(order)", forKey: ExercizeToGTPart.idKey)
					c.setValue(order, forKey: ExercizeToGTPart.orderKey)
					c.setValue(dst, forKey: ExercizeToGTPart.workoutKey)
					order += 1
					
					circuit = c
					return c
				}()
				
				WorkoutToGTWorkout.exercizeLookupTable[id] = (circ, inCircuitOrder)
				inCircuitOrder += 1
			} else {
				WorkoutToGTWorkout.exercizeLookupTable[id] = (dst, order)
				order += 1
			}
			
			prevCircuit = isCircuit
			if !isCircuit {
				circuit = nil
				inCircuitOrder = 0
			}
		}
		
		manager.associate(sourceInstance: src, withDestinationInstance: dst, for: mapping)
	}
	
}
