//
//  GTSimpleSetsExerciseExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTSimpleSetsExercise {
	
	static let exerciseTag = "exercize"
	static let nameTag = "name"
	static let isCircuitTag = "iscircuit"
	static let hasCircuitRestTag = "hascircuitrest"
	static let setsTag = "sets"
	
	override func export() -> String {
		var res = "<\(GTSimpleSetsExercise.exerciseTag)>"
		res += "<\(GTSimpleSetsExercise.nameTag)>\(name.toXML())</\(GTSimpleSetsExercise.nameTag)>"
		if isInCircuit {
			res += "<\(GTSimpleSetsExercise.hasCircuitRestTag)>\(hasCircuitRest)</\(GTSimpleSetsExercise.hasCircuitRestTag)>"
		}
		res += "<\(GTSimpleSetsExercise.setsTag)>\(self.setList.map { $0.export() }.reduce("") { $0 + $1 })</\(GTSimpleSetsExercise.setsTag)>"
		res += "</\(GTSimpleSetsExercise.exerciseTag)>"

		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTSimpleSetsExercise {
		guard xml.name == GTSimpleSetsExercise.exerciseTag,
			let name = xml.children.first(where: { $0.name == GTSimpleSetsExercise.nameTag })?.content?.fromXML(),
			let sets = xml.children.first(where: { $0.name == GTSimpleSetsExercise.setsTag })?.children else {
				throw GTError.importFailure([])
		}
		let hasCircuitRest = xml.children.first(where: { $0.name == GTSimpleSetsExercise.hasCircuitRestTag })?.content ?? "false" == "true"
		
		let e = dataManager.newExercise()
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
