//
//  WorkoutExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension Workout {
	
	func export() -> String {
		var res = "<\(importExportManager.workoutTag)>"
		res += "<\(importExportManager.workoutNameTag)>\(self.name.toXML())</\(importExportManager.workoutNameTag)>"
		res += "<\(importExportManager.archivedTag)>\(self.archived)</\(importExportManager.archivedTag)>"
		res += "<\(importExportManager.exercizesTag)>\(self.exercizeList.map { $0.export() }.reduce("") { $0 + $1 })</\(importExportManager.exercizesTag)>"
		res += "</\(importExportManager.workoutTag)>"
		
		return res
	}
	
	///Read XML data and create the corresponding `Workout`, this method assumes that data is valid according to `workout.xsd`.
	///- returns: Whether the import was success or not, in case of failure the returned `Workout`, if any, must be deleted.
	static func `import`(fromXML xml: XMLNode) -> (workout: Workout?, success: Bool) {
		// Check that the exercize list in XML does not contain rest period at the start or end, nor two or more consecutive rest
		guard let exercizes = xml.children.first(where: { $0.name == importExportManager.exercizesTag })?.children,
			let lastEx = exercizes.last, lastEx.name == importExportManager.exercizeTag else {
			return (nil, false)
		}
		
		var acceptRest = false
		for e in exercizes {
			if e.name == importExportManager.restTag {
				if !acceptRest {
					return (nil, false)
				}
				
				acceptRest = false
			} else if e.name == importExportManager.exercizeTag {
				acceptRest = true
			} else {
				return (nil, false)
			}
		}
		
		guard let name = xml.children.first(where: { $0.name == importExportManager.workoutNameTag })?.content?.fromXML(),
			let archived = xml.children.first(where: { $0.name == importExportManager.archivedTag })?.content else {
			return (nil, false)
		}
		
		let w = dataManager.newWorkout()
		w.set(name: name)
		w.archived = archived == "true"
		
		for e in exercizes {
			let (_, success) = Exercize.import(fromXML: e, for: w)
			if !success {
				return (w, false)
			}
		}
		
		return (w, w.hasExercizes)
	}
	
}
