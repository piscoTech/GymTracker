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
		var res = "<?xml version=\"1.0\"?><workoutlist>"
		res += Workout.getList().map { $0.export() }.reduce("") { $0 + $1 }
		res += "</workoutlist>\n"
		
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
		
		guard let xsd = Bundle.main.url(forResource: "workout", withExtension: "xsd"),
			let root = file.loadAsXML(validatingWithXSD: xsd) else {
			return
		}
		
		// TODO: Cycle over child elements (aka `workout`s), import them using `Workout.import(fromXML:)` and persist correct ones
	}
	
}
