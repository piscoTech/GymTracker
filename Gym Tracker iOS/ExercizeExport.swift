//
//  ExercizeExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension Exercize {
	
	func export() -> String {
		if isRest {
			return "<\(importExportManager.restTag)>\(Int(rest))</\(importExportManager.restTag)>"
		} else {
			var res = "<\(importExportManager.exercizeTag)>"
			res += "<\(importExportManager.exercizeNameTag)>\(self.name?.toXML() ?? "")</\(importExportManager.exercizeNameTag)>"
			res += "<\(importExportManager.setsTag)>\(self.setList.map { $0.export() }.reduce("") { $0 + $1 })</\(importExportManager.setsTag)>"
			res += "</\(importExportManager.exercizeTag)>"
			
			return res
		}
	}
	
	///Read XML data and create the corresponding `Exercize`, this method assumes that data is valid according to `workout.xsd`.
	///- returns: Whether the import was success or not, in case of failure the returned `Exercize`, if any, must be deleted.
	static func `import`(fromXML xml: XMLNode, for w: Workout) -> (exercize: Exercize?, success: Bool) {
		if xml.name == importExportManager.restTag {
			guard let restData = xml.content, let restTime = TimeInterval(restData) else {
				return (nil, false)
			}
			
			let e = dataManager.newExercize(for: w)
			e.set(rest: restTime)
			
			return (e, true)
		} else if xml.name == importExportManager.exercizeTag {
			guard let name = xml.children.first(where: { $0.name == importExportManager.exercizeNameTag })?.content?.fromXML(),
				let sets = xml.children.first(where: { $0.name == importExportManager.setsTag })?.children else {
				return (nil, false)
			}
			
			let e = dataManager.newExercize(for: w)
			e.set(name: name)
			for s in sets {
				let (_, success) = RepsSet.import(fromXML: s, for: e)
				if !success {
					return (e, false)
				}
			}
			
			return (e, e.isValid)
		} else {
			return (nil, false)
		}
	}
	
}
