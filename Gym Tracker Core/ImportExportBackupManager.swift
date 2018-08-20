//
//  ImportExportBackupManager.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//
//

import Foundation

public class ImportExportBackupManager: NSObject {
	
	let dataManager: DataManager
	
	public let fileExtension = ".wrkt"
	let keepBackups = 5
	let autoBackupTime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
	let delayReloadTime: TimeInterval = 2
	
	static let workoutsTag = "workoutlist"
	
	private let nameFilter = try! NSRegularExpression(pattern: "[^a-z0-9]+", options: .caseInsensitive)
	private var query: NSMetadataQuery?
	
	private override init() {
		fatalError("Use init(dataManager:_)")
	}
	
	init(dataManager: DataManager) {
		self.dataManager = dataManager
		
		super.init()
		
		NotificationCenter.default.addObserver(self, selector: #selector(backupsCollected(_:)), name: .NSMetadataQueryDidFinishGathering, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Backup fetch
	
	public typealias BackupList = [(path: URL, date: Date)]
	public typealias BackupCallback = () -> Void
	private var backupCallbacks = [BackupCallback]()
	public private(set) var backups: BackupList = []
	
	public func loadBackups(_ completion: @escaping BackupCallback) {
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
	
	@objc func backupsCollected(_ not: Notification) {
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
	
	public func export(workout: GTWorkout) -> URL? {
		let name = dataManager.performCoreDataCodeAndWait { return workout.name }
		return export(workouts: [workout], name: nameFilter.stringByReplacingMatches(in: name, options: [], range: NSRange(location: 0, length: name.count), withTemplate: "_"))
	}
	
	func export() -> URL? {
		return export(workouts: GTWorkout.getList(fromDataManager: dataManager), name: Date().getWorkoutExportName())
	}
	
	private func export(workouts: [GTWorkout], name: String) -> URL? {
		let res: String = dataManager.performCoreDataCodeAndWait {
			var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><\(ImportExportBackupManager.workoutsTag)>"
			xml += workouts.map { $0.export() }.joined()
			xml += "</\(ImportExportBackupManager.workoutsTag)>\n"
			
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
	
	public func doBackup(manual: Bool = false, completion: ((Bool) -> Void)? = nil) {
		if !manual {
			guard dataManager.preferences.useBackups else {
				completion?(false)
				return
			}
			
			if let last = dataManager.preferences.lastBackup {
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
					self.dataManager.loadDocumentToICloud(file) { success in
						if success {
							self.dataManager.preferences.lastBackup = Date()
							DispatchQueue.main.asyncAfter(delay: self.delayReloadTime) {
								self.loadBackups {
									if self.backups.count > self.keepBackups {
										var waiting = self.backups.count - self.keepBackups
										for b in self.backups.suffix(from: self.keepBackups) {
											self.dataManager.deleteICloudDocument(b.path) { success in
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
	
	public func `import`(_ file: URL, isRestoring restore: Bool, performCallback: @escaping (Bool, Int?, (() -> ())?) -> Void, callback: @escaping ([GTWorkout]?) -> Void) {
		if let xsd = Bundle(for: type(of: self)).url(forResource: "workout", withExtension: "xsd"),
			let workouts = file.loadAsXML(validatingWithXSD: xsd)?.children, workouts.count > 0 {
			DispatchQueue.main.async {
				performCallback(true, workouts.count) {
					DispatchQueue.main.async {
						var save = [GTDataObject]()
						var delete: [GTDataObject] = restore ? GTWorkout.getList(fromDataManager: self.dataManager) : []
						
						for wData in workouts {
							do {
								let w = try GTWorkout.import(fromXML: wData, withDataManager: self.dataManager)
								
								if w.isValid {
									save.append(contentsOf: w.subtreeNodeList)
								} else {
									delete.append(w)
								}
							} catch GTDataImportError.failure(let obj) {
								delete.append(contentsOf: obj)
							} catch _ {}
						}
						
						if self.dataManager.persistChangesForObjects(save, andDeleteObjects: delete) {
							callback(save.compactMap { $0 as? GTWorkout })
						} else {
							self.dataManager.discardAllChanges()
							callback(nil)
						}
					}
				}
			}
		} else {
			DispatchQueue.main.async {
				performCallback(false, nil, nil)
			}
		}
	}
	
}
