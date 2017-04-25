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
	private func export(name: String? = nil) -> URL? {
		let res: String = dataManager.performCoreDataCodeAndWait {
			var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><\(self.workoutsTag)>"
			xml += Workout.getList().map { $0.export() }.reduce("") { $0 + $1 }
			xml += "</\(self.workoutsTag)>\n"
			
			return xml
		}
		
		// TODO: Use current UNIX timestamp for default name
		let filePath = URL(fileURLWithPath: NSString(string: NSTemporaryDirectory()).appendingPathComponent((name ?? "workouts") + fileExtension))
		
		do {
			try res.write(to: filePath, atomically: true, encoding: .utf8)
			
			return filePath
		} catch {
			return nil
		}
	}
	
	func doBackup() {
		guard preferences.useBackups else {
			return
		}
		
		// TODO: Should check if appropriate to do a backup (time check), call this function at the end of applicationDidFinishLaunching and in viewDidLoad of the settings controller after checking iCloud status
		
		dataManager.reportICloudStatus { res in
			guard res else {
				return
			}
	
			DispatchQueue.background.async {
				guard let file = self.export() else {
					print("Cannot export")
					return
				}
				
				dataManager.loadDocumentToICloud(file) { success in
					print(success ? "File uploaded" : "Error uploading")
				}
			}
		}
	}
	
//	private func `import`(_ file: URL) {
//		guard let xsd = Bundle.main.url(forResource: "workout", withExtension: "xsd"),
//			let workouts = file.loadAsXML(validatingWithXSD: xsd)?.children else {
//				return
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
//	}
	
}
