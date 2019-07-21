//
//  GTDataObjectExport.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 14/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTDataObject {
	
	@objc func export() -> String {
		fatalError("Abstract method not implemented")
	}
	
	///Read XML data and create the corresponding `GTDataObject`, this method assumes that data is valid according to `workout.xsd`.
	///- returns: The created `GTDataObject`.
	///- throws: Throws `GTError.importFailure` in case of failure, if the error contains `GTDataObject`s they must be deleted.
	@objc class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTDataObject {
		let type: GTDataObject.Type
		switch xml.name {
		case GTRepsSet.setTag:
			type = GTRepsSet.self
		case GTSimpleSetsExercise.exerciseTag:
			type = GTSimpleSetsExercise.self
		case GTChoice.choiceTag:
			type = GTChoice.self
		case GTCircuit.circuitTag:
			type = GTCircuit.self
		case GTRest.restTag:
			type = GTRest.self
		case GTWorkout.workoutTag:
			type = GTWorkout.self
		default:
			throw GTError.importFailure([])
		}
		
		return try type.import(fromXML: xml, withDataManager: dataManager)
	}
}
