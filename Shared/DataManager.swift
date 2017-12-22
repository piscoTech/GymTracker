//
//  DataManager.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/17.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import CoreData
import MBLibrary
import WatchConnectivity

func == (l: CDRecordID, r: CDRecordID) -> Bool {
	return l.hashValue == r.hashValue
}

func == (l: WCObject, r: WCObject) -> Bool {
	return l.id == r.id
}

struct CDRecordID: Hashable {
	
	let type: String
	let id: String
	
	var hashValue: Int {
		return (type+id).hashValue
	}
	
	init(obj: DataObject) {
		type = obj.objectType
		id = obj.id
	}
	
	init?(wcRepresentation d: [String]) {
		guard d.count == 2 else {
			return nil
		}
		
		self.init(type: d[0], id: d[1])
	}
	
	private init?(type: String, id: String) {
		self.type = type
		self.id = id
		
		if type == "" || id == "" {
			return nil
		}
	}
	
	var wcRepresentation: [String] {
		return [type, id]
	}
	
	fileprivate func getType() -> DataObject.Type? {
		return NSClassFromString(type) as? DataObject.Type
	}
	
	func getObject(fromDataManager dataManager: DataManager) -> DataObject? {
		return getType()?.loadWithID(id, fromDataManager: dataManager)
	}
	
	static func encodeArray(_ ar: [CDRecordID]) -> [[String]] {
		return ar.map { [$0.type, $0.id] }
	}
	
	static func decodeArray(_ ar: [[String]]) -> [CDRecordID] {
		var res = [CDRecordID]()
		
		for el in ar {
			if el.count == 2 {
				if let id = CDRecordID(type: el[0], id: el[1]) {
					res.append(id)
				}
			}
		}
		
		return res
	}
	
}

class DataObject: NSManagedObject {
	
	class var objectType: String {
		return "DataObject"
	}
	var objectType: String {
		return type(of: self).objectType
	}
	
	@NSManaged fileprivate var id: String
	@NSManaged fileprivate var created: Date?
	@NSManaged fileprivate var modified: Date?
	
	fileprivate static let createdKey = "created"
	fileprivate static let modifiedKey = "modified"
	
	override required init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}
	
	fileprivate var isNew: Bool {
		precondition(modified != nil && created != nil, "\(objectType) not saved")
		
		return created! == modified!
	}
	
	var recordID: CDRecordID {
		return CDRecordID(obj: self)
	}
	
	class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> DataObject? {
		fatalError("Abstarct method not implemented")
	}
	
	///- returns: Whether or not the object represented by this instance is still present in the database, `false` is returned even if it was impossible to determine.
	func stillExists(inDataManager dataManager: DataManager) -> Bool {
		if let _ = recordID.getType()?.loadWithID(self.id, fromDataManager: dataManager) {
			return true
		} else {
			return false
		}
	}
	
	var wcObject: WCObject? {
		let obj = WCObject(id: self.recordID)
		
		guard let c = created, let m = modified else {
			return nil
		}
		
		obj[DataObject.createdKey] = c
		obj[DataObject.modifiedKey] = m
		
		return obj
	}
	
	func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard src.id == self.recordID, let modified = src[DataObject.modifiedKey] as? Date else {
			return false
		}
		
		if self.modified != nil && self.modified! > modified {
			// If local changes are more recent ignore the updates
			return false
		}
		
		self.modified = modified
		
		return true
	}
	
}

class WCObject: Equatable {
	
	private static let idKey = "WCObjectIdKey"
	private let initialDataKey = "isInitialData"
	
	private(set) var id: CDRecordID
	private var data: [String: Any] = [:]
	
	fileprivate init(id: CDRecordID) {
		self.id = id
	}
	
	fileprivate convenience init?(wcRepresentation data: [String: Any]) {
		guard let idData = data[WCObject.idKey] as? [String], let id = CDRecordID(wcRepresentation: idData) else {
			return nil
		}
		
		self.init(id: id)
		
		self.data = data
		self.data.removeValue(forKey: WCObject.idKey)
	}
	
	fileprivate var wcRepresentation: [String: Any] {
		var res = self.data
		res[WCObject.idKey] = id.wcRepresentation
		
		return res
	}
	
	subscript (index: String) -> Any? {
		get {
			return data[index]
		}
		set {
			data[index] = newValue
		}
	}
	
	fileprivate func setAsInitialData(_ val: Bool = true) {
		data[initialDataKey] = val
	}
	
	var created: Date? {
		return data[DataObject.createdKey] as? Date
	}
	
	fileprivate var isNew: Bool? {
		guard let created = self.created, let modified = data[DataObject.modifiedKey] as? Date else {
			return nil
		}
		
		return created == modified
	}
	
	fileprivate var isInitialData: Bool {
		return data[initialDataKey] as? Bool ?? false
	}
	
	static func encodeArray(_ ar: [WCObject]) -> [[String: Any]] {
		return ar.map { $0.wcRepresentation }
	}
	
	static func decodeArray(_ ar: [[String: Any]]) -> [WCObject] {
		var res = [WCObject]()
		
		for el in ar {
			if let obj = WCObject(wcRepresentation: el) {
				res.append(obj)
			}
		}
		
		return res
	}
	
}

// MARK: - Delegate Protocol

@objc protocol DataManagerDelegate: class {
	
	func refreshData()
	func cancelAndDisableEdit()
	func enableEdit()
	
	// TODO: Make date optional, if nil means we are in a set (no current rest as date represent the start of the currente rest)
	@available(watchOS, unavailable)
	func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date)
	@available(watchOS, unavailable)
	func mirroredWorkoutHasEnded()
	
	@available(iOS, unavailable)
	func remoteWorkoutStart(_ workout: Workout)
	
}

// MARK: - Data Manager

class DataManager {
	
	enum Usage: CustomStringConvertible {
		case application, testing
		
		var description: String {
			switch self {
			case .application:
				return "[App]"
			case .testing:
				return "[Test]"
			}
		}
	}
	
	weak var delegate: DataManagerDelegate?
	
	let use: Usage
	let preferences: Preferences
	#if os(iOS)
	private(set) var importExportManager: ImportExportBackupManager!
	#endif
	private let localData: CoreDataStack
	private let wcInterface: WatchConnectivityInterface
	
	init(for use: Usage) {
		preferences = Preferences(for: use)
		localData = CoreDataStack(for: use)
		wcInterface = WatchConnectivityInterface(for: use)
		self.use = use
		
		wcInterface.dataManager = self
		#if os(iOS)
			importExportManager = ImportExportBackupManager(dataManager: self)
		#endif

		print("\(use) Data Manager initialized")
		
		if wcInterface.hasCounterPart && !preferences.initialSyncDone {
			initializeWatchDatabase()
		}
		
		wcInterface.persistPendingChanges()
	}
	
	// MARK: - Interaction

	func executeFetchRequest<T>(_ request: NSFetchRequest<T>) -> [T]? {
		var result: [T]? = nil
		localData.managedObjectContext.performAndWait {
			result = try? self.localData.managedObjectContext.fetch(request)
		}
		
		return result
	}
	
	func performCoreDataCodeAndWait<T>(_ block: @escaping () -> T) -> T {
		var res: T!
		localData.managedObjectContext.performAndWait {
			res = block()
		}
		
		return res
	}
	
	private func newObjectFor<T: DataObject>(_ obj: T.Type) -> T {
		let context = localData.managedObjectContext
		var newObj: T!
		context.performAndWait {
			let e = NSEntityDescription.entity(forEntityName: obj.objectType, in: context)!
			newObj = T(entity: e, insertInto: context)
		}
		
		newObj.id = newObj.objectID.uriRepresentation().path
		newObj.created = nil
		newObj.modified = nil
		
		return newObj
	}
	
	private func newObjectFor(_ src: WCObject) -> DataObject? {
		guard let created = src.created, let type = src.id.getType() else {
			return nil
		}
		
		let obj = newObjectFor(type)
		obj.id = src.id.id
		obj.created = created
		
		return obj
	}
	
	func newWorkout() -> Workout {
		return newObjectFor(Workout.self)
	}
	
	func newExercize(for workout: Workout) -> Exercize {
		let newE = newObjectFor(Exercize.self)
		newE.order = Int32(workout.exercizes.count)
		newE.workout = workout
		
		return newE
	}
	
	
	func newSet(for exercize: Exercize) -> RepsSet {
		let newS = newObjectFor(RepsSet.self)
		newS.order = Int32(exercize.sets.count)
		newS.exercize = exercize
		
		return newS
	}
	
	func discardAllChanges() {
		localData.managedObjectContext.rollback()
	}
	
	func persistChangesForObjects(_ data: [DataObject], andDeleteObjects delete: [DataObject]) -> Bool {
		let context = localData.managedObjectContext
		let removedIDs = delete.map { (r) -> CDRecordID in
			let id = r.recordID
			context.performAndWait {
				context.delete(r)
			}
			return id
		}
		
		let now = Date()
		for obj in data {
			if obj.created == nil {
				obj.created = now
			}
			obj.modified = now
		}
		
		var res = false
		context.performAndWait {
			do {
				try context.save()
				
				self.wcInterface.sendUpdateForChangedObjects(data, andDeleted: removedIDs)
				
				res = true
			} catch {
				res = false
			}
		}
		
		return res
	}
	
	@available(watchOS, unavailable)
	var shouldStartWorkoutOnWatch: Bool {
		return use == .application && wcInterface.hasCounterPart && wcInterface.canComunicate
	}
	
	func setRunningWorkout(_ w: Workout?, fromSource s: RunningWorkoutSource) {
		// Can set workout only for current platform, the phone can set also for the watch
		guard use == .application, s.isCurrentPlatform() || s == .watch else {
			return
		}
		
		preferences.runningWorkout = w?.recordID
		preferences.runningWorkoutSource = s
		
		if w == nil {
			delegate?.enableEdit()
			wcInterface.persistPendingChanges()
		} else {
			delegate?.cancelAndDisableEdit()
		}
		
		preferences.runningWorkoutNeedsTransfer = true
		wcInterface.setRunningWorkout()
	}
	
	@available(watchOS, unavailable)
	func requestStarting(_ workout: Workout) -> Bool {
		#if os(iOS)
			return wcInterface.requestStarting(workout)
		#endif
		#if os(watchOS)
			return false
		#endif
	}
	
	func sendWorkoutStartDate() {
		wcInterface.sendWorkoutStartDate()
	}
	
	func sendWorkoutStatusUpdate() {
		wcInterface.sendWorkoutStatusUpdate()
	}

	// MARK: - Synchronization methods
	
	private var isSaving = false
	
	fileprivate func initializeWatchDatabase() {
		guard isiOS else {
			return
		}
		
		DispatchQueue.main.async {
			self.preferences.transferLocal = []
			self.preferences.deleteLocal = []
			
			self.preferences.saveRemote = []
			self.preferences.deleteRemote = []
			
			let data = Workout.getList(fromDataManager: self).flatMap { [$0 as DataObject]
				+ $0.exercizes.map { [$0 as DataObject] + Array($0.sets) as [DataObject] }.reduce([]) { $0 + $1 } }
			self.wcInterface.sendUpdateForChangedObjects(data, andDeleted: [], markAsInitial: true)
			
			self.preferences.initialSyncDone = true
			print("\(self.use) Initial data sent to watch")
		}
	}

	fileprivate func saveCounterPartUpdatesForChangedObjects(_ changes: [WCObject], andDeleted deletion: [CDRecordID]) -> Bool {
		guard changes.count > 0 || deletion.count > 0 else {
			return true
		}
		
		delegate?.cancelAndDisableEdit()
		let context = localData.managedObjectContext
		
		// Delete objects
		for d in deletion {
			// If the object is missing it's been already deleted so no problem
			if let obj = d.getObject(fromDataManager: self) {
				context.delete(obj)
			}
		}
		
		// Save changes
		var res = true
		let order: [DataObject.Type] = [Workout.self, Exercize.self, RepsSet.self]
		var pendingSave = changes
		for type in order {
			for obj in pendingSave {
				guard type.objectType == obj.id.type else {
					continue
				}
				
				let cdObj: DataObject
				if let tmp = obj.id.getObject(fromDataManager: self) {
					cdObj = tmp
				} else if obj.isNew ?? false || obj.isInitialData {
					if let tmp = newObjectFor(obj) {
						cdObj = tmp
					} else {
						res = false
						break
					}
				} else {
					continue
				}
				
				if !cdObj.mergeUpdatesFrom(obj, inDataManager: self) {
					res = false
					break
				}
				pendingSave.removeElement(obj)
			}
		}
		
		if res {
			context.performAndWait {
				do {
					try context.save()
					
					self.delegate?.refreshData()
					res = true
				} catch {
					res = false
				}
			}
		} else {
			context.rollback()
		}
	
		delegate?.enableEdit()
		return res
	}
	
	fileprivate func clearDatabase() -> Bool {
		var res = false
		let context = localData.managedObjectContext
		context.performAndWait {
			for w in Workout.getList(fromDataManager: self) {
				context.delete(w)
			}
			
			do {
				try context.save()
				
				res = true
			} catch {
				res = false
			}
		}
		
		return res
	}
	
	func askPhoneForData() -> Bool {
		return wcInterface.askPhoneForData()
	}
	
	// MARK: - iCloude Drive handling
	
	private func rootDirectoryForICloud(_ completion: @escaping (URL?) -> Void) {
		DispatchQueue.background.async {
			let file = FileManager.default
			guard let root = file.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
				DispatchQueue.main.async {
					completion(nil)
				}
				
				return
			}
			
			if !file.fileExists(atPath: root.path, isDirectory: nil) {
				do {
					try file.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
				} catch {
					DispatchQueue.main.async {
						completion(nil)
					}
					
					return
				}
			}
			
			DispatchQueue.main.async {
				completion(root)
			}
		}
	}
	
	func reportICloudStatus(_ completion: @escaping (Bool) -> Void) {
		rootDirectoryForICloud { url in
			completion(url != nil)
		}
	}
	
	func loadDocumentToICloud(_ localPath: URL, completion: @escaping (Bool) -> Void) {
		rootDirectoryForICloud { path in
			guard let root = path else {
				completion(false)
				
				return
			}
			
			DispatchQueue.background.async {
				let remotePath = root.appendingPathComponent(localPath.lastPathComponent)
				do {
					let file = FileManager.default
					if file.fileExists(atPath: remotePath.path) {
						try file.removeItem(at: remotePath)
					}
					
					try file.setUbiquitous(true, itemAt: localPath, destinationURL: remotePath)
					
					completion(true)
				} catch {
					completion(false)
				}
			}
		}
	}
	
	private lazy var fileCoordinator = NSFileCoordinator(filePresenter: nil)
	
	func deleteICloudDocument(_ path: URL, completion: @escaping (Bool) -> Void) {
		DispatchQueue.background.async {
			self.fileCoordinator.coordinate(writingItemAt: path, options: .forDeleting, error: nil) { writingPath in
				let file = FileManager()
				do {
					try file.removeItem(at: writingPath)
					completion(true)
				} catch {
					completion(false)
				}
			}
		}
	}

}

// MARK: - Core Data Stack

private class CoreDataStack {
	
	let storeName = "GymTracker"
	let use: DataManager.Usage
	
	fileprivate init(for use: DataManager.Usage) {
		self.use = use
		
		print("\(use) Local store initialized")
	}
	
	// MARK: - Core Data objects
	
	lazy var managedObjectModel: NSManagedObjectModel = {
		// The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
		let modelURL = Bundle.main.url(forResource: self.storeName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
	}()
	
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
		// The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
		// Create the coordinator and store
		let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		
		let failureReason = "There was an error creating or loading the application's saved data."
		
		let type = use == .application ? NSSQLiteStoreType : NSInMemoryStoreType
		let url = use == .application ? applicationDocumentsDirectory.appendingPathComponent("\(self.storeName).sqlite") : nil
		let options = use == .application ? [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSInferMappingModelAutomaticallyOption: true
		] : nil
		
		do {
			try coordinator.addPersistentStore(ofType: type, configurationName: nil, at: url, options: options)
		} catch {
			// Report any error we got.
			var dict = [String: Any]()
			dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
			dict[NSLocalizedFailureReasonErrorKey] = failureReason
			
			dict[NSUnderlyingErrorKey] = error as NSError
			let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			// Replace this with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			abort()
		}
		
		return coordinator
	}()
	
	lazy var managedObjectContext: NSManagedObjectContext = {
		// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
		let coordinator = self.persistentStoreCoordinator
		var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = coordinator
		return managedObjectContext
	}()

}

// MARK: - Watch/iOS Interface

private class WatchConnectivityInterface: NSObject, WCSessionDelegate {
	
	private let use: DataManager.Usage
	private var session: WCSession!
	fileprivate var hasCounterPart: Bool {
		var res = session != nil
		#if os(iOS)
			res = res && session!.isPaired && session!.isWatchAppInstalled
		#endif
		
		return res
	}
	fileprivate var canComunicate: Bool {
		return session != nil && session!.activationState == .activated
	}
	fileprivate var isReachable: Bool {
		return session?.isReachable ?? false
	}
	
	fileprivate var dataManager: DataManager!

	override convenience fileprivate init() {
		self.init(for: .application)
	}
	
	fileprivate init(for use: DataManager.Usage) {
		self.use = use
		
		super.init()
		
		if use == .application, WCSession.isSupported() {
			session = WCSession.default
			session.delegate = self
			session.activate()
		}
		
		print("\(use) Watch/iOS interface initialized")
	}
	
	private var pendingBlock: [() -> Void] = []
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("\(use) Watch Connectivity Session activated")
		
		if isiOS, dataManager.preferences.runningWorkout != nil, let src = dataManager.preferences.runningWorkoutSource, src == .watch, !self.hasCounterPart {
			dataManager.setRunningWorkout(nil, fromSource: .watch)
		}
		
		for b in pendingBlock {
			b()
		}
		pendingBlock.removeAll()
		
		// Send pending transfers
		sendUpdateForChangedObjects([], andDeleted: [])
		setRunningWorkout()
	}
	
	#if os(iOS)
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		// Use this method to manage watch switching
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
		session.activate()
	}
	
	func sessionWatchStateDidChange(_ session: WCSession) {
		if hasCounterPart && !dataManager.preferences.initialSyncDone {
			dataManager.initializeWatchDatabase()
		}
	}
	
	#endif
	
	// MARK: - Interaction
	
	private let changesKey = "changes"
	private let deletionKey = "deletion"
	private let currentWorkoutKey = "curWorkout"
	private let currentWorkoutStartDate = "curWorkoutStartDate"
	private let currentWorkoutProgress = "curWorkoutProgress"
	
	fileprivate func sendUpdateForChangedObjects(_ data: [DataObject], andDeleted delete: [CDRecordID], markAsInitial: Bool = false) {
		guard let sess = session, hasCounterPart else {
			return
		}
		
		DispatchQueue.main.async {
			//Prepend pending transfer to new ones
			let changedObjects = self.dataManager.preferences.transferLocal.flatMap { $0.getObject(fromDataManager: self.dataManager) } + data
			let deletedIDs = self.dataManager.preferences.deleteLocal + delete
			
			guard changedObjects.count != 0 || deletedIDs.count != 0 else {
				return
			}
			
			guard self.canComunicate else {
				self.dataManager.preferences.transferLocal = changedObjects.map { $0.recordID }
				self.dataManager.preferences.deleteLocal = deletedIDs
				
				return
			}
			
			let changedData = changedObjects.flatMap { (cdObj) -> [String: Any]? in
				let wcObj = cdObj.wcObject
				if markAsInitial {
					wcObj?.setAsInitialData()
				}
				
				return wcObj?.wcRepresentation
			}
			let deletedData = deletedIDs.map { $0.wcRepresentation }
			
			var data = [ self.changesKey: changedData, self.deletionKey: deletedData ] as [String : Any]
			if markAsInitial {
				data[self.isInitialDataKey] = true
			}
			
			sess.transferUserInfo(data)
			self.dataManager.preferences.transferLocal = []
			self.dataManager.preferences.deleteLocal = []
		}
	}
	
	fileprivate func setRunningWorkout() {
		guard let sess = session, hasCounterPart, dataManager.preferences.runningWorkoutNeedsTransfer else {
			return
		}
		
		guard canComunicate else {
			dataManager.preferences.runningWorkoutNeedsTransfer = true
			return
		}
		
		sess.transferUserInfo([currentWorkoutKey: [
			dataManager.preferences.runningWorkout?.wcRepresentation ?? ["nil"],
			dataManager.preferences.runningWorkoutSource?.rawValue ?? "nil"
		]])
		dataManager.preferences.runningWorkoutNeedsTransfer = false
	}
	
	fileprivate func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
		guard error != nil else {
			return
		}
		
		DispatchQueue.main.async {
			let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
				guard let sess = self.session, self.hasCounterPart, self.canComunicate else {
					return
				}
				
				sess.transferUserInfo(userInfoTransfer.userInfo)
			}
			RunLoop.main.add(timer, forMode: .commonModes)
		}
	}

	fileprivate func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
		if userInfo[isInitialDataKey] as? Bool ?? false, iswatchOS {
			_ = dataManager.clearDatabase()
		}
		
		if let curWorkout = userInfo[currentWorkoutKey] as? [Any], curWorkout.count == 2 {
			// Pass something that's not an ID to signal that workout has ended
			let w = CDRecordID(wcRepresentation: curWorkout[0] as? [String] ?? [])
			dataManager.preferences.runningWorkout = w
			dataManager.preferences.runningWorkoutSource = RunningWorkoutSource(rawValue: curWorkout[1] as? String ?? "")
			
			if w == nil {
				dataManager.delegate?.enableEdit()
				#if os(iOS)
					dataManager.delegate?.mirroredWorkoutHasEnded()
				#endif
			} else {
				dataManager.delegate?.cancelAndDisableEdit()
			}
		}
		
		#if os(iOS)
			if let curStart = userInfo[currentWorkoutStartDate] as? Date {
				dataManager.preferences.currentStart = curStart
			}
			
			if let currentProgress = userInfo[currentWorkoutProgress] as? [Any], currentProgress.count == 3,
				let curExercize = currentProgress[0] as? Int, let curPart = currentProgress[1] as? Int, let time = currentProgress[2] as? Date,
				dataManager.preferences.runningWorkout != nil {
				
				dataManager.delegate?.updateMirroredWorkout(withCurrentExercize: curExercize, part: curPart, andTime: time)
				
			}
		#endif
		
		DispatchQueue.main.async {
			let changes = self.dataManager.preferences.saveRemote + WCObject.decodeArray(userInfo[self.changesKey] as? [[String : Any]] ?? [])
			let deletion = self.dataManager.preferences.deleteRemote + CDRecordID.decodeArray(userInfo[self.deletionKey] as? [[String]] ?? [])
			if self.dataManager.preferences.runningWorkout != nil {
				self.dataManager.preferences.saveRemote = changes
				self.dataManager.preferences.deleteRemote = deletion
				
				return
			}
			
			if !self.dataManager.saveCounterPartUpdatesForChangedObjects(changes, andDeleted: deletion) {
				self.dataManager.preferences.saveRemote = changes
				self.dataManager.preferences.deleteRemote = deletion
				
				DispatchQueue.main.async {
					let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
						self.persistPendingChanges()
					}
					RunLoop.main.add(timer, forMode: .commonModes)
				}
			} else {
				self.dataManager.preferences.saveRemote = []
				self.dataManager.preferences.deleteRemote = []
			}
		}
	}
	
	fileprivate func persistPendingChanges() {
		DispatchQueue.main.async {
			guard self.dataManager.preferences.runningWorkout == nil else {
				return
			}
			
			if !self.dataManager.saveCounterPartUpdatesForChangedObjects(self.dataManager.preferences.saveRemote, andDeleted: self.dataManager.preferences.deleteRemote) {
				DispatchQueue.main.async {
					let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
						self.persistPendingChanges()
					}
					RunLoop.main.add(timer, forMode: .commonModes)
				}
			} else {
				self.dataManager.preferences.saveRemote = []
				self.dataManager.preferences.deleteRemote = []
			}
		}
	}
	
	fileprivate func sendWorkoutStartDate() {
		guard iswatchOS, dataManager.preferences.runningWorkout != nil, canComunicate, let sess = self.session else {
			return
		}
		
		sess.transferUserInfo([currentWorkoutStartDate: dataManager.preferences.currentStart])
	}
	
	fileprivate func sendWorkoutStatusUpdate() {
		guard iswatchOS, dataManager.preferences.runningWorkout != nil, canComunicate, let sess = self.session else {
			return
		}
		
		sess.transferUserInfo([currentWorkoutProgress: [
			dataManager.preferences.currentExercize,
			dataManager.preferences.currentPart,
			Date()
		]])
	}
	
	// MARK: - Watch initail setup & Remote workou start
	
	private let askDataKey = "watchNeedsData"
	private let isInitialDataKey = "isInitialData"
	private let dataIncomingKey = "dataIncoming"
	private let remoteWorkoutStartKey = "remoteWorkoutStart"
	
	///- returns: Whether or not the phone needs unlocking or be in range before initialization
	@available(watchOS 3, *)
	fileprivate func askPhoneForData() -> Bool {
		guard canComunicate else {
			pendingBlock.append({ _ = self.askPhoneForData() })
			
			return true
		}
		
		if session.isReachable {
			let reschedule = {
				let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
					_ = self.askPhoneForData()
				}
				RunLoop.main.add(timer, forMode: .commonModes)
			}
			
			session.sendMessage([askDataKey: true], replyHandler: { reply in
				guard let isOK = reply[self.dataIncomingKey] as? Bool, isOK else {
					DispatchQueue.main.async {
						reschedule()
					}
					
					return
				}
				
				self.dataManager.preferences.initialSyncDone = true
				self.dataManager.delegate?.refreshData()
			}) { _ in
				DispatchQueue.main.async {
					reschedule()
				}
			}
		}
		
		return !session.isReachable
	}
	
	fileprivate func sessionReachabilityDidChange(_ session: WCSession) {
		guard iswatchOS, !dataManager.preferences.initialSyncDone else {
			return
		}
		
		_ = askPhoneForData()
	}
	
	@available(watchOS, unavailable)
	func requestStarting(_ workout: Workout) -> Bool {
		guard canComunicate && session.isReachable else {
			return false
		}
		
		session.sendMessage([remoteWorkoutStartKey: workout.recordID.wcRepresentation], replyHandler: nil, errorHandler: nil)
		return true
	}
	
	fileprivate func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		if let sendData = message[askDataKey] as? Bool, isiOS, sendData {
			dataManager.initializeWatchDatabase()
			
			replyHandler([dataIncomingKey: true])
		}
	}
	
	fileprivate func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		if let wData = message[remoteWorkoutStartKey] as? [String], iswatchOS, let wID = CDRecordID(wcRepresentation: wData), let workout = wID.getObject(fromDataManager: dataManager) as? Workout {
			#if os(watchOS)
				dataManager.delegate?.remoteWorkoutStart(workout)
			#endif
		}
	}
	
}
