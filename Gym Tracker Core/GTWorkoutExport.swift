//
//  GTWorkoutExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTWorkout {
	
	static let workoutTag = "workout"
	static let nameTag = "name"
	static let archivedTag = "archived"
	static let partsTag = "exercizes"
	
	override func export() -> String {
		var res = "<\(GTWorkout.workoutTag)>"
		res += "<\(GTWorkout.nameTag)>\(self.name.toXML())</\(GTWorkout.nameTag)>"
		res += "<\(GTWorkout.archivedTag)>\(self.archived)</\(GTWorkout.archivedTag)>"
		res += "<\(GTWorkout.partsTag)>\(self.exercizeList.map { $0.export() }.reduce("") { $0 + $1 })</\(GTWorkout.partsTag)>"
		res += "</\(GTWorkout.workoutTag)>"

		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTWorkout {
		guard xml.name == GTWorkout.workoutTag,
			let name = xml.children.first(where: { $0.name == GTWorkout.nameTag })?.content?.fromXML(),
			let archived = xml.children.first(where: { $0.name == GTWorkout.archivedTag })?.content,
			let parts = xml.children.first(where: { $0.name == GTWorkout.partsTag })?.children else {
			throw GTError.importFailure([])
		}

		let w = dataManager.newWorkout()
		w.set(name: name)
		w.archived = archived == "true"
		
		var dynamicCircuit: GTCircuit?

		for p in parts {
			do {
				let o = try GTDataObject.import(fromXML: p, withDataManager: dataManager)
				guard let part = o as? GTPart else {
					throw GTError.importFailure(w.subtreeNodes.union([o] + (dynamicCircuit?.subtreeNodes ?? [])))
				}
				
				if let e = part as? GTSetsExercize {
					let isCircuit = p.children.first(where: { $0.name == GTSimpleSetsExercize.isCircuitTag })?.content ?? "false"  == "true"
					
					if let c = dynamicCircuit {
						c.add(parts: e)
						
						if !isCircuit {
							w.add(parts: c)
							dynamicCircuit = nil
						}
					} else if isCircuit {
						dynamicCircuit = dataManager.newCircuit()
						dynamicCircuit?.add(parts: e)
					} else {
						w.add(parts: part)
					}
				} else {
					if let c = dynamicCircuit {
						w.add(parts: c)
						dynamicCircuit = nil
					}
						
					w.add(parts: part)
				}
			} catch GTError.importFailure(let obj) {
				throw GTError.importFailure(w.subtreeNodes.union(obj.union(dynamicCircuit?.subtreeNodes ?? [])))
			}
		}
		
		if let c = dynamicCircuit {
			w.add(parts: c)
			dynamicCircuit = nil
		}

		let del = w.purge()
		if w.isSubtreeValid && del.isEmpty {
			return w
		} else {
			throw GTError.importFailure(w.subtreeNodes.union(del))
		}
	}
	
}
