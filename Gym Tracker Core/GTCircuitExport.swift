//
//  GTCircuitExport.swift
//  Gym Tracker Core iOS
//
//  Created by Marco Boschi on 18/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTCircuit {
	
	static let circuitTag = "circuit"
	static let exercisesTag = "exercizes"
	
	override func export() -> String {
		var res = "<\(GTCircuit.circuitTag)>"
		res += "<\(GTCircuit.exercisesTag)>\(self.exerciseList.map { $0.export() }.reduce("") { $0 + $1 })</\(GTCircuit.exercisesTag)>"
		res += "</\(GTCircuit.circuitTag)>"
		
		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTCircuit {
		guard xml.name == GTCircuit.circuitTag,
			let ex = xml.children.first(where: { $0.name == GTCircuit.exercisesTag })?.children else {
				throw GTError.importFailure([])
		}

		let c = dataManager.newCircuit()
		for e in ex {
			do {
				let o = try GTDataObject.import(fromXML: e, withDataManager: dataManager)
				guard let exercise = o as? GTSetsExercise else {
					throw GTError.importFailure(c.subtreeNodes.union([o]))
				}

				c.add(parts: exercise)
			} catch GTError.importFailure(let obj) {
				throw GTError.importFailure(c.subtreeNodes.union(obj))
			}
		}

		if c.isSubtreeValid {
			return c
		} else {
			throw GTError.importFailure(c.subtreeNodes)
		}
	}
}
