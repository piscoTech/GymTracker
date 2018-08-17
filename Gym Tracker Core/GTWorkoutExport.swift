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
	
	override func export() -> String {
		return ""
		#warning("Implement me")
//		var res = "<\(ImportExportBackupManager.workoutTag)>"
//		res += "<\(ImportExportBackupManager.workoutNameTag)>\(self.name.toXML())</\(ImportExportBackupManager.workoutNameTag)>"
//		res += "<\(ImportExportBackupManager.archivedTag)>\(self.archived)</\(ImportExportBackupManager.archivedTag)>"
//		res += "<\(ImportExportBackupManager.exercizesTag)>\(self.exercizeList.map { $0.export() }.reduce("") { $0 + $1 })</\(ImportExportBackupManager.exercizesTag)>"
//		res += "</\(ImportExportBackupManager.workoutTag)>"
//
//		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTWorkout {
		throw GTDataImportError.failure([])
		#warning("Implement me")
//		// Check that the exercize list in XML does not contain rest period at the start or end, nor two or more consecutive rest
//		guard let exercizes = xml.children.first(where: { $0.name == ImportExportBackupManager.exercizesTag })?.children,
//			let lastEx = exercizes.last, lastEx.name == ImportExportBackupManager.exercizeTag else {
//			return (nil, false)
//		}
//
//		var acceptRest = false
//		for e in exercizes {
//			if e.name == ImportExportBackupManager.restTag {
//				if !acceptRest {
//					return (nil, false)
//				}
//
//				acceptRest = false
//			} else if e.name == ImportExportBackupManager.exercizeTag {
//				acceptRest = true
//			} else {
//				return (nil, false)
//			}
//		}
//
//		guard let name = xml.children.first(where: { $0.name == ImportExportBackupManager.workoutNameTag })?.content?.fromXML(),
//			let archived = xml.children.first(where: { $0.name == ImportExportBackupManager.archivedTag })?.content else {
//			return (nil, false)
//		}
//
//		let w = dataManager.newWorkout()
//		w.set(name: name)
//		w.archived = archived == "true"
//
//		for e in exercizes {
//			let (_, success) = Exercize.import(fromXML: e, for: w, withDataManager: dataManager)
//			if !success {
//				return (w, false)
//			}
//		}
//
//		return (w, w.hasExercizes)
	}
	
}
