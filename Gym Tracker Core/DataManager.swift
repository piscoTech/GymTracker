//
//  DataManager.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/17.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import CoreData
import WatchConnectivity
import MBLibrary

struct CDRecordID: Hashable {
	
	let type: String
	let id: String
	
	// Let the compiler automatically synthesize the requirement for `Equatable` and `Hashable` based on `type` and `id`
	
	init(obj: GTDataObject) {
		type = obj.objectType
		id = obj.id
	}
	
	init?(wcRepresentation data: [String]?) {
		guard let d = data, d.count == 2 else {
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
	
	fileprivate func getType() -> GTDataObject.Type? {
		return NSClassFromString(type) as? GTDataObject.Type
	}
	
	func getObject(fromDataManager dataManager: DataManager) -> GTDataObject? {
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

class GTDataObject: NSManagedObject {
	
	class var objectType: String {
		fatalError("Abstarct property not implemented")
	}
	final var objectType: String {
		return type(of: self).objectType
	}
	
	@NSManaged final fileprivate var id: String
	@NSManaged final fileprivate var created: Date?
	@NSManaged final fileprivate var modified: Date?
	
	fileprivate static let createdKey = "created"
	fileprivate static let modifiedKey = "modified"
	
	override required init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}
	
	final fileprivate var isNew: Bool {
		precondition(modified != nil && created != nil, "\(objectType) not saved")
		
		return created! == modified!
	}
	
	final var recordID: CDRecordID {
		return CDRecordID(obj: self)
	}
	
	class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTDataObject? {
		fatalError("Abstarct method not implemented")
	}
	
	///- returns: Whether or not the object represented by this instance is still present in the database, `false` is returned even if it was impossible to determine.
	final func stillExists(inDataManager dataManager: DataManager) -> Bool {
		if let _ = recordID.getType()?.loadWithID(self.id, fromDataManager: dataManager) {
			return true
		} else {
			return false
		}
	}
	
	var isValid: Bool {
		fatalError("Abstarct property not implemented")
	}
	
	internal var isSubtreeValid: Bool {
		fatalError("Abstarct property not implemented")
	}
	
	/// The list of all more specific components of the workout that are linked by the receiver, and the receiver itself.
	var subtreeNodeList: Set<GTDataObject> {
		fatalError("Abstarct property not implemented")
	}
	
	func purgeInvalidSettings() {
		fatalError("Abstarct property not implemented")
	}
	
	var wcObject: WCObject? {
		let obj = WCObject(id: self.recordID)
		
		guard let c = created, let m = modified else {
			return nil
		}
		
		obj[GTDataObject.createdKey] = c
		obj[GTDataObject.modifiedKey] = m
		
		return obj
	}
	
	func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard src.id == self.recordID, let modified = src[GTDataObject.modifiedKey] as? Date else {
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

final class WCObject: Equatable {
	
	static func == (l: WCObject, r: WCObject) -> Bool {
		return l.id == r.id
	}
	
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
		return data[GTDataObject.createdKey] as? Date
	}
	
	fileprivate var isNew: Bool? {
		guard let created = self.created, let modified = data[GTDataObject.modifiedKey] as? Date else {
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
	
	@available(watchOS, unavailable)
	func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date?)
	@available(watchOS, unavailable)
	func mirroredWorkoutHasEnded()
	
	@available(iOS, unavailable)
	func remoteWorkoutStart(_ workout: GTWorkout)
	
}

// MARK: - Data Manager

@objc
public class DataManager: NSObject {
	
	public enum Usage: CustomStringConvertible {
		case application, testing
		
		public var description: String {
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
	
	override private init() {
		fatalError("Not supported")
	}
	
	init(for use: Usage) {
		preferences = Preferences(for: use)
		localData = CoreDataStack(for: use)
		wcInterface = WatchConnectivityInterface(for: use)
		self.use = use
		
		super.init()
		
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
	
	private func newObjectFor<T: GTDataObject>(_ obj: T.Type) -> T {
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
	
	private func newObjectFor(_ src: WCObject) -> GTDataObject? {
		guard let created = src.created, let type = src.id.getType() else {
			return nil
		}
		
		let obj = newObjectFor(type)
		obj.id = src.id.id
		obj.created = created
		
		return obj
	}
	
	func newWorkout() -> GTWorkout {
		return newObjectFor(GTWorkout.self)
	}
	
	func newRest() -> GTRest {
		return newObjectFor(GTRest.self)
	}
	
	func newCircuit() -> GTCircuit {
		return newObjectFor(GTCircuit.self)
	}
	
	func newChoice() -> GTChoice {
		return newObjectFor(GTChoice.self)
	}
	
	func newExercize() -> GTSimpleSetsExercize {
		return newObjectFor(GTSimpleSetsExercize.self)
	}
	
	internal func newSet() -> GTRepsSet {
		return newObjectFor(GTRepsSet.self)
	}
	
	func newSet(for exercize: GTSimpleSetsExercize) -> GTRepsSet {
		let newS = newSet()
		newS.order = Int32(exercize.sets.count)
		newS.exercize = exercize
		
		return newS
	}
	
	public func discardAllChanges() {
		localData.managedObjectContext.rollback()
	}
	
	func persistChangesForObjects(_ data: [GTDataObject], andDeleteObjects delete: [GTDataObject]) -> Bool {
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
	
	func setRunningWorkout(_ w: GTWorkout?, fromSource s: RunningWorkoutSource) {
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
	func requestStarting(_ workout: GTWorkout, completion: @escaping (Bool) -> Void) {
		#if os(iOS)
			wcInterface.requestStarting(workout, completion: completion)
		#elseif os(watchOS)
			completion(false)
		#endif
	}
	
	func sendWorkoutStartDate() {
		wcInterface.sendWorkoutStartDate()
	}
	
	func sendWorkoutStatusUpdate(restStart date: Date?) {
		wcInterface.sendWorkoutStatusUpdate(restStart: date)
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
			
			let data = GTWorkout.getList(fromDataManager: self).flatMap { $0.subtreeNodeList }
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
		let order: [GTDataObject.Type] = [GTWorkout.self, GTCircuit.self, GTChoice.self, GTSimpleSetsExercize.self, GTRepsSet.self]
		var pendingSave = changes
		for type in order {
			for obj in pendingSave {
				guard type.objectType == obj.id.type else {
					continue
				}
				
				let cdObj: GTDataObject
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
			for w in GTWorkout.getList(fromDataManager: self) {
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
	
	func readICloudDocument(_ path: URL, action: @escaping (URL) -> Void) {
		DispatchQueue.background.async {
			self.fileCoordinator.coordinate(readingItemAt: path, options: .withoutChanges, error: nil) { readingPath in
				action(readingPath)
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
		let modelURL = Bundle(for: type(of: self)).url(forResource: self.storeName, withExtension: "momd")!
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
	
	fileprivate func sendUpdateForChangedObjects(_ data: [GTDataObject], andDeleted delete: [CDRecordID], markAsInitial: Bool = false) {
		guard let sess = session, hasCounterPart else {
			return
		}
		
		DispatchQueue.main.async {
			//Prepend pending transfer to new ones
			let changedObjects = self.dataManager.preferences.transferLocal.compactMap { $0.getObject(fromDataManager: self.dataManager) } + data
			let deletedIDs = self.dataManager.preferences.deleteLocal + delete
			
			guard changedObjects.count != 0 || deletedIDs.count != 0 else {
				return
			}
			
			guard self.canComunicate else {
				self.dataManager.preferences.transferLocal = changedObjects.map { $0.recordID }
				self.dataManager.preferences.deleteLocal = deletedIDs
				
				return
			}
			
			let changedData = changedObjects.compactMap { (cdObj) -> [String: Any]? in
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
			RunLoop.main.add(timer, forMode: .common)
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
			
			if let currentProgress = userInfo[currentWorkoutProgress] as? [Any], currentProgress.count == 2 || currentProgress.count == 3,
				let curExercize = currentProgress[0] as? Int, let curPart = currentProgress[1] as? Int, dataManager.preferences.runningWorkout != nil {
				let date = currentProgress.count == 3 ? currentProgress[2] as? Date : nil
				if currentProgress.count == 2 || date != nil {
					dataManager.delegate?.updateMirroredWorkout(withCurrentExercize: curExercize, part: curPart, andTime: date)
				}
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
					RunLoop.main.add(timer, forMode: .common)
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
					RunLoop.main.add(timer, forMode: .common)
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
	
	fileprivate func sendWorkoutStatusUpdate(restStart date: Date?) {
		guard iswatchOS, dataManager.preferences.runningWorkout != nil, canComunicate, let sess = self.session else {
			return
		}
		
		var info: [Any] = [
			dataManager.preferences.currentExercize,
			dataManager.preferences.currentPart
		]
		if let d = date {
			info.append(d)
		}
		sess.transferUserInfo([currentWorkoutProgress: info])
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
				RunLoop.main.add(timer, forMode: .common)
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
	func requestStarting(_ workout: GTWorkout, completion: @escaping (Bool) -> Void) {
		guard canComunicate && session.isReachable else {
			completion(false)
			return
		}
		
		DispatchQueue.main.async {
			self.session.sendMessage([self.remoteWorkoutStartKey: workout.recordID.wcRepresentation],
									 replyHandler: { completion($0[self.remoteWorkoutStartKey] as? Bool ?? false) },
									 errorHandler: { _ in completion(false) })
		}
	}
	
	fileprivate func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		if let sendData = message[askDataKey] as? Bool, isiOS, sendData {
			dataManager.initializeWatchDatabase()
			
			replyHandler([dataIncomingKey: true])
		}
	
		#if os(watchOS)
			if let wID = CDRecordID(wcRepresentation: message[remoteWorkoutStartKey] as? [String]), let workout = wID.getObject(fromDataManager: dataManager) as? GTWorkout {
				dataManager.delegate?.remoteWorkoutStart(workout)
				replyHandler([remoteWorkoutStartKey: true])
			}
		#endif
	}
	
}
