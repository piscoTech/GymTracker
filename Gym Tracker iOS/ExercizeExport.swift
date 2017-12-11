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
			return "<\(ImportExportBackupManager.restTag)>\(Int(rest))</\(ImportExportBackupManager.restTag)>"
		} else {
			var res = "<\(ImportExportBackupManager.exercizeTag)>"
			res += "<\(ImportExportBackupManager.exercizeNameTag)>\(self.name?.toXML() ?? "")</\(ImportExportBackupManager.exercizeNameTag)>"
			res += "<\(ImportExportBackupManager.exercizeIsCircuit)>\(self.isCircuit)</\(ImportExportBackupManager.exercizeIsCircuit)>"
			res += "<\(ImportExportBackupManager.exercizeHasCircuitRest)>\(self.hasCircuitRest)</\(ImportExportBackupManager.exercizeHasCircuitRest)>"
			res += "<\(ImportExportBackupManager.setsTag)>\(self.setList.map { $0.export() }.reduce("") { $0 + $1 })</\(ImportExportBackupManager.setsTag)>"
			res += "</\(ImportExportBackupManager.exercizeTag)>"
			
			return res
		}
	}
	
	///Read XML data and create the corresponding `Exercize`, this method assumes that data is valid according to `workout.xsd`.
	///- returns: Whether the import was success or not, in case of failure the returned `Exercize`, if any, must be deleted.
	static func `import`(fromXML xml: XMLNode, for w: Workout, withDataManager dataManager: DataManager) -> (exercize: Exercize?, success: Bool) {
		if xml.name == ImportExportBackupManager.restTag {
			guard let restData = xml.content, let restTime = TimeInterval(restData) else {
				return (nil, false)
			}
			
			let e = dataManager.newExercize(for: w)
			e.set(rest: restTime)
			
			return (e, true)
		} else if xml.name == ImportExportBackupManager.exercizeTag {
			guard let name = xml.children.first(where: { $0.name == ImportExportBackupManager.exercizeNameTag })?.content?.fromXML(),
				let sets = xml.children.first(where: { $0.name == ImportExportBackupManager.setsTag })?.children else {
				return (nil, false)
			}
			let isCircuit = xml.children.first(where: { $0.name == ImportExportBackupManager.exercizeIsCircuit })?.content ?? "false"
			let hasCircuitRest = xml.children.first(where: { $0.name == ImportExportBackupManager.exercizeHasCircuitRest })?.content ?? "false"
			
			let e = dataManager.newExercize(for: w)
			e.set(name: name)
			e.makeCircuit(isCircuit == "true")
			e.enableCircuitRest(hasCircuitRest == "true")
			for s in sets {
				let (_, success) = RepsSet.import(fromXML: s, for: e, withDataManager: dataManager)
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
