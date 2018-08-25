//
//  ExercizeToGTPart.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 23/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import CoreData
import MBLibrary

class ExercizeToGTPart: NSEntityMigrationPolicy {

	static let idKey = "id"
	static let orderKey = "order"
	static let isCircuitKey = "isCircuit"
	static let modifiedKey = "modified"
	let isRestKey = "isRest"
	let restKey = "rest"
	let nameKey = "name"
	let circuitKey = "circuit"
	static let workoutKey = "workout"
	let setsKey = "sets"
	
	let exercizeType = "GTSimpleSetsExercize"
	static let circuitType = "GTCircuit"
	let restType = "GTRest"
	
	private let defaultName = GTLocalizedString("EXERCIZE", comment: "Exercize")
	
	static private var setLookupTable = [String: NSManagedObject]()
	
	/// Fetch the parent for the set of the given id.
	static func parentInfo(for setId: String) -> NSManagedObject? {
		return setLookupTable[setId]
	}
	
	static func clearParentInfo() {
		setLookupTable = [:]
	}
	
	override func createDestinationInstances(forSource src: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
		// Migrate the exercize
		let srcKeys = Array(src.entity.attributesByName.keys)
		let srcValues = src.dictionaryWithValues(forKeys: srcKeys)
		
		let id = src.value(forKey: ExercizeToGTPart.idKey) as! String
		let isRest = src.value(forKey: isRestKey) as? Bool ?? true
		let dst = NSEntityDescription.insertNewObject(forEntityName: isRest ? restType : exercizeType, into: manager.destinationContext)
		let dstKeys = Array(dst.entity.attributesByName.keys).subtract([restKey, nameKey])
		if isRest {
			let rest = src.value(forKey: restKey) as? TimeInterval ?? 0
			dst.setValue(max(rest, GTRest.minRest), forKey: restKey)
		} else {
			let name = src.value(forKey: nameKey) ?? defaultName
			dst.setValue(name, forKey: nameKey)
			
			ExercizeToGTPart.setLookupTable += Dictionary(uniqueKeysWithValues: (src.value(forKey: setsKey) as! Set<NSManagedObject>).map { ($0.value(forKey: RepsSetToGTRepsSet.idKey) as! String, dst) })
		}
		
		for k in dstKeys {
			if let srcV = srcValues[k], !(srcV is NSNull) {
				dst.setValue(srcV, forKey: k)
			}
		}
		
		// Link to parent
		guard let (p, order) = WorkoutToGTWorkout.parentInfo(for: id) else {
			throw GTError.migration
		}
		
		dst.setValue(order, forKey: ExercizeToGTPart.orderKey)
		if p.entity.name == ExercizeToGTPart.circuitType {
			dst.setValue(p, forKey: circuitKey)
		} else {
			dst.setValue(p, forKey: ExercizeToGTPart.workoutKey)
		}
		
		manager.associate(sourceInstance: src, withDestinationInstance: dst, for: mapping)
	}
	
}
