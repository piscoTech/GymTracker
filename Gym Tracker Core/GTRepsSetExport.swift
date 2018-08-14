//
//  GTRepsSetExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTRepsSet {
	
	override func export() -> String {
		return ""
		#warning("Implement me")
//		var res = "<\(ImportExportBackupManager.setTag)>"
//		res += "<\(ImportExportBackupManager.setRepsTag)>\(self.reps)</\(ImportExportBackupManager.setRepsTag)>"
//		res += "<\(ImportExportBackupManager.setWeightTag)>\(self.weight)</\(ImportExportBackupManager.setWeightTag)>"
//		res += "<\(ImportExportBackupManager.setRestTag)>\(Int(self.rest))</\(ImportExportBackupManager.setRestTag)>"
//		res += "</\(ImportExportBackupManager.setTag)>"
//		
//		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTRepsSet {
		throw GTDataImportError.failure(nil)
		#warning("Implement me")
//		guard !e.isRest else {
//			return (nil, false)
//		}
//		
//		guard let repsData = xml.children.first(where: { $0.name == ImportExportBackupManager.setRepsTag })?.content, let reps = Int32(repsData),
//			let weightData = xml.children.first(where: { $0.name == ImportExportBackupManager.setWeightTag })?.content, let weight = Double(weightData),
//			let restData = xml.children.first(where: { $0.name == ImportExportBackupManager.setRestTag })?.content, let rest = TimeInterval(restData) else {
//			return (nil, false)
//		}
//		
//		let s = dataManager.newSet(for: e)
//		s.set(rest: rest)
//		s.set(reps: reps)
//		s.set(weight: weight)
//		
//		return (s, s.isValid)
	}
	
}
