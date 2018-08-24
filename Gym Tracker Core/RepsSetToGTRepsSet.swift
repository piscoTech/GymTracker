//
//  RepsSetToGTRepsSet.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 23/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import CoreData

class RepsSetToGTRepsSet: NSEntityMigrationPolicy {
	
	static let idKey = "id"
	let exercizeKey = "exercize"
	
	override func createDestinationInstances(forSource src: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
		// Migrate the set
		let srcKeys = Array(src.entity.attributesByName.keys)
		let srcValues = src.dictionaryWithValues(forKeys: srcKeys)
		
		let id = src.value(forKey: RepsSetToGTRepsSet.idKey) as! String
		let dst = NSEntityDescription.insertNewObject(forEntityName: mapping.destinationEntityName!, into: manager.destinationContext)
		let dstKeys = Array(dst.entity.attributesByName.keys)
		
		for k in dstKeys {
			if let srcV = srcValues[k], !(srcV is NSNull) {
				dst.setValue(srcV, forKey: k)
			}
		}
		
		// Link to parent
		guard let p = ExercizeToGTPart.parentInfo(for: id) else {
			throw GTError.migration
		}
		dst.setValue(p, forKey: exercizeKey)
		
		manager.associate(sourceInstance: src, withDestinationInstance: dst, for: mapping)
	}

}
