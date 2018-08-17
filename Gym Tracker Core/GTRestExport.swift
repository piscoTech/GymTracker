//
//  GTRestExport.swift
//  Gym Tracker Core iOS
//
//  Created by Marco Boschi on 17/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTRest {
	
	override func export() -> String {
		return ""
		return "<\(ImportExportBackupManager.restTag)>\(Int(rest))</\(ImportExportBackupManager.restTag)>"
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTRest {
		throw GTDataImportError.failure([])
		
		if xml.name == ImportExportBackupManager.restTag {
			guard let restData = xml.content, let restTime = TimeInterval(restData) else {
				throw GTDataImportError.failure([])
			}
			
			let e = dataManager.newRest()
			e.set(rest: restTime)
			
			return e
		}
	}
}
