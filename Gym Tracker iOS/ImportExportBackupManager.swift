//
//  ImportExportBackupManager.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//
//

import Foundation
import MBLibrary

class ImportExportBackupManager {
	
	let fileExtension = ".wrkt"
	
	let workoutsTag = "workoutlist"
	let workoutTag = "workout"
	let workoutNameTag = "name"
	let archivedTag = "archived"
	let exercizesTag = "exercizes"
	
	let restTag = "rest"
	let exercizeTag = "exercize"
	let exercizeNameTag = "name"
	let setsTag = "sets"
	
	let setTag = "set"
	let setRestTag = "rest"
	let setWeightTag = "weight"
	let setRepsTag = "reps"
	
	// MARK: - Initialization
	
	private static var manager: ImportExportBackupManager?
	
	class func getManager() -> ImportExportBackupManager {
		return ImportExportBackupManager.manager ?? {
			let m = ImportExportBackupManager()
			ImportExportBackupManager.manager = m
			return m
		}()
	}
	
	private init() {}
	
	// MARK: - Export
	
	///- parameter isExternal: whether to save the resulting file in the temporary directory for exporting or in the backup folder.
	private func export(isExternal: Bool = false) -> URL? {
		var res = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><\(workoutsTag)>"
		res += Workout.getList().map { $0.export() }.reduce("") { $0 + $1 }
		res += "</\(workoutsTag)>\n"
		
		let filePath: URL
		if isExternal {
			filePath = URL(fileURLWithPath: NSString(string: NSTemporaryDirectory()).appendingPathComponent("workouts\(fileExtension)"))
		} else {
			return nil
		}
		
		do {
			try res.write(to: filePath, atomically: true, encoding: .utf8)
			
			return filePath
		} catch {
			return nil
		}
	}
	
	func testExportImport() {
		guard let file = export(isExternal: true) else {
			print("Cannot export")
			return
		}
		
//		guard let xsd = Bundle.main.url(forResource: "workout", withExtension: "xsd"),
//			let workouts = file.loadAsXML(validatingWithXSD: xsd)?.children else {
//			return
//		}
//		
//		var save = [Workout]()
//		var delete = [Workout]()
//		
//		for wData in workouts {
//			let (w, success) = Workout.import(fromXML: wData)
//			
//			if let w = w {
//				if success {
//					save.append(w)
//				} else {
//					delete.append(w)
//				}
//			}
//		}
//		
//		if dataManager.persistChangesForObjects(save, andDeleteObjects: delete) {
//			print("Import-Export successful")
//			appDelegate.workoutList.refreshData()
//		} else {
//			dataManager.discardAllChanges()
//			print("Import-Export failed")
//		}
		dataManager.loadDocumentToICloud(file) { success in
			print(success ? "File uploaded" : "Error uploading")
		}
	}
	
}
