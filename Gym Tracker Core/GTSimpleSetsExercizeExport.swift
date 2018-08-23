//
//  GTSimpleSetsExercizeExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTSimpleSetsExercize {
	
	static let exercizeTag = "exercize"
	static let nameTag = "name"
	static let isCircuitTag = "iscircuit"
	static let hasCircuitRestTag = "hascircuitrest"
	static let setsTag = "sets"
	
	override func export() -> String {
		var res = "<\(GTSimpleSetsExercize.exercizeTag)>"
		res += "<\(GTSimpleSetsExercize.nameTag)>\(name.toXML())</\(GTSimpleSetsExercize.nameTag)>"
		if isInCircuit {
			res += "<\(GTSimpleSetsExercize.hasCircuitRestTag)>\(hasCircuitRest)</\(GTSimpleSetsExercize.hasCircuitRestTag)>"
		}
		res += "<\(GTSimpleSetsExercize.setsTag)>\(self.setList.map { $0.export() }.reduce("") { $0 + $1 })</\(GTSimpleSetsExercize.setsTag)>"
		res += "</\(GTSimpleSetsExercize.exercizeTag)>"

		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTSimpleSetsExercize {
		guard xml.name == GTSimpleSetsExercize.exercizeTag,
			let name = xml.children.first(where: { $0.name == GTSimpleSetsExercize.nameTag })?.content?.fromXML(),
			let sets = xml.children.first(where: { $0.name == GTSimpleSetsExercize.setsTag })?.children else {
				throw GTError.importFailure([])
		}
		let hasCircuitRest = xml.children.first(where: { $0.name == GTSimpleSetsExercize.hasCircuitRestTag })?.content ?? "false" == "true"
		
		let e = dataManager.newExercize()
		e.set(name: name)
		e.forceEnableCircuitRest(hasCircuitRest)
		for s in sets {
			do {
				let o = try GTDataObject.import(fromXML: s, withDataManager: dataManager)
				guard let repSet = o as? GTSet else {
					throw GTError.importFailure(e.subtreeNodes.union([o]))
				}
				
				e.add(set: repSet)
			} catch GTError.importFailure(let obj) {
				throw GTError.importFailure(e.subtreeNodes.union(obj))
			}
		}
		
		if e.isSubtreeValid {
			return e
		} else {
			throw GTError.importFailure(e.subtreeNodes)
		}
	}
	
}
