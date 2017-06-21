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
	
	private let nameFilter = try! NSRegularExpression(pattern: "[^a-z0-9]+", options: .caseInsensitive)
	
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
	
	func export(workout: Workout) -> URL? {
		let name = dataManager.performCoreDataCodeAndWait { return workout.name }
		return export(workouts: [workout], name: nameFilter.stringByReplacingMatches(in: name, options: [], range: NSRange(location: 0, length: name.length), withTemplate: "_"))
	}
	
	func export() -> URL? {
		return export(workouts: Workout.getList(), name: Date().getWorkoutExportName())
	}
	
	private func export(workouts: [Workout], name: String) -> URL? {
		let res: String = dataManager.performCoreDataCodeAndWait {
			var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><\(self.workoutsTag)>"
			xml += workouts.map { $0.export() }.joined()
			xml += "</\(self.workoutsTag)>\n"
			
			return xml
		}
		
		let filePath = URL(fileURLWithPath: NSString(string: NSTemporaryDirectory()).appendingPathComponent(name + fileExtension))
		
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
			DispatchQueue.main.async {
				guard let file = self.export() else {
					return
				}
				
				DispatchQueue.background.async {
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
	}
	
	public func `import`(_ file: URL, isRestoring restore: Bool, performCallback: (Bool, Int?, (() -> ())?) -> Void, callback: @escaping (Bool) -> Void) {
		if let xsd = Bundle.main.url(forResource: "workout", withExtension: "xsd"),
			let workouts = file.loadAsXML(validatingWithXSD: xsd)?.children, workouts.count > 0 {
			performCallback(true, workouts.count) {
				DispatchQueue.main.async {
					var save = [Workout]()
					var delete = restore ? Workout.getList() : []
					
					for wData in workouts {
						let (w, success) = Workout.import(fromXML: wData)
						
						if let w = w {
							if success {
								save.append(w)
							} else {
								delete.append(w)
							}
						}
					}
					
					if dataManager.persistChangesForObjects(save, andDeleteObjects: delete) {
						appDelegate.workoutList.refreshData()
						callback(true)
					} else {
						dataManager.discardAllChanges()
						callback(false)
					}
				}
			}
		} else {
			performCallback(false, nil, nil)
		}
	}
	
}
