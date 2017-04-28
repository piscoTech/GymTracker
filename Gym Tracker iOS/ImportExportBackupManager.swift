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

class ImportExportBackupManager: NSObject {
	
	let fileExtension = ".wrkt"
	let keepBackups = 5
	let autoBackupTime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
	
	let delayReloadTime: TimeInterval = 2
	
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
	
	private var query: NSMetadataQuery?
	
	private override init() {
		super.init()
		
		NotificationCenter.default.addObserver(self, selector: #selector(backupsCollected(_:)), name: .NSMetadataQueryDidFinishGathering, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Backup fetch
	
	typealias BackupList = [(path: URL, date: Date)]
	typealias BackupCallback = () -> Void
	private var backupCallbacks = [BackupCallback]()
	private(set) var backups: BackupList = []
	
	func loadBackups(_ completion: @escaping BackupCallback) {
		backupCallbacks.append(completion)
		
		DispatchQueue.main.async {
			if self.query == nil {
				let query = NSMetadataQuery()
				query.searchScopes.append(NSMetadataQueryUbiquitousDocumentsScope)
				query.predicate = NSPredicate(format: "%K like '*\(self.fileExtension)'", NSMetadataItemFSNameKey)
				
				query.start()
				self.query = query
			}
		}
	}
	
	func backupsCollected(_ not: Notification) {
		guard let query = not.object as? NSMetadataQuery, let savedQuery = self.query, query == savedQuery else {
			return
		}
		query.stop()
		query.disableUpdates()
		self.query = nil
		
		backups = []
		query.enumerateResults({ item, _, _ in
			guard let data = item as? NSMetadataItem,
				let path = data.value(forAttribute: NSMetadataItemURLKey) as? URL,
				let date = data.value(forAttribute: NSMetadataItemFSContentChangeDateKey) as? Date else {
					return
			}
			
			backups.append((path, date))
		})
		backups.sort { $0.date > $1.date }
		
		for c in backupCallbacks {
			c()
		}
		backupCallbacks = []
	}
	
	// MARK: - Export
	
	///- parameter isExternal: whether to save the resulting file in the temporary directory for exporting or in the backup folder.
	private func export(name: String? = nil) -> URL? {
		let res: String = dataManager.performCoreDataCodeAndWait {
			var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><\(self.workoutsTag)>"
			xml += Workout.getList().map { $0.export() }.reduce("") { $0 + $1 }
			xml += "</\(self.workoutsTag)>\n"
			
			return xml
		}
		
		let filePath = URL(fileURLWithPath: NSString(string: NSTemporaryDirectory()).appendingPathComponent((name ?? Date().getWorkoutExportName()) + fileExtension))
		
		do {
			try res.write(to: filePath, atomically: true, encoding: .utf8)
			
			return filePath
		} catch {
			return nil
		}
	}
	
	func doBackup(manual: Bool = false, completion: ((Bool) -> Void)? = nil) {
		if !manual {
			guard preferences.useBackups else {
				completion?(false)
				return
			}
			
			if let last = preferences.lastBackup {
				if Date().timeIntervalSince(last) < autoBackupTime {
					completion?(false)
					return
				}
			}
		}
		
		dataManager.reportICloudStatus { res in
			guard res else {
				completion?(false)
				return
			}
	
			DispatchQueue.background.async {
				guard let file = self.export() else {
					print("Cannot export")
					return
				}
				
				dataManager.loadDocumentToICloud(file) { success in
					if success {
						preferences.lastBackup = Date()
						DispatchQueue.main.asyncAfter(delay: self.delayReloadTime) {
							self.loadBackups {
								if self.backups.count > self.keepBackups {
									var waiting = self.backups.count - self.keepBackups
									for b in self.backups.suffix(from: self.keepBackups) {
										dataManager.deleteICloudDocument(b.path) { success in
											DispatchQueue.main.async {
												waiting -= 1
												if success {
													self.backups = self.backups.filter { $0.path != b.path }
												}
												
												if waiting == 0 {
													completion?(success)
												}
											}
										}
									}
								} else {
									completion?(success)
								}
							}
						}
					} else {
						completion?(success)
					}
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
