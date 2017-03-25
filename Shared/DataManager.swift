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
		return [ type, id]
	}
	
	fileprivate func getType() -> DataObject.Type? {
		return NSClassFromString(type) as? DataObject.Type
	}
	
	func getObject() -> DataObject? {
		return getType()?.loadWithID(id)
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
		get {
			return "DataObject"
		}
	}
	var objectType: String {
		get {
			return type(of: self).objectType
		}
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
		get {
			return CDRecordID(obj: self)
		}
	}
	
	class func loadWithID(_ id: String) -> DataObject? {
		fatalError("Abstarct method not implemented")
	}
	
	///- returns: Whether or not the object represented by this instance is still present in the database, `false` is returned even if it was impossible to determine.
	func stillExists() -> Bool {
		if let _ = recordID.getType()?.loadWithID(self.id) {
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
	
	func mergeUpdatesFrom(_ src: WCObject) -> Bool {
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
	
	subscript(index: String) -> Any? {
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

protocol DataManagerDelegate: class {
	
	func refreshData()
	func cancelAndDisableEdit()
	func enableEdit()
	
}

// MARK: - Data Manager

class DataManager: NSObject {
	
	weak var delegate: DataManagerDelegate?
	
	fileprivate private(set) var localData: CoreDataStack
	fileprivate private(set) var wcInterface: WatchConnectivityInterface
	
	// MARK: - Initialization
	
	private static var manager: DataManager?
	
	class func getManager() -> DataManager {
		return DataManager.manager ?? {
			let m = DataManager()
			DataManager.manager = m
			return m
		}()
	}
	
	override private init() {
		localData = CoreDataStack.getStack()
		wcInterface = WatchConnectivityInterface.getInterface()
		
		super.init()
		
		// Use for cleanup during development
//		preferences.addFromLocal = []
//		preferences.updateFromLocal = []
//		preferences.deleteFromLocal = []

		print("Data Manager initialized")
		
		if wcInterface.hasCounterPart && !preferences.initialSyncDone {
			initializeWatchDatabase()
		}
		
		// TODO: Remove running workout (with watch as source) if on ios and watch is no more paired
		
		wcInterface.persistPendingChanges()
	}
	

	// MARK: - Interaction

	func executeFetchRequest<T: NSFetchRequestResult>(_ request: NSFetchRequest<T>) -> [T]? {
		var result: [T]? = nil
		localData.managedObjectContext.performAndWait {
			do {
				result = try self.localData.managedObjectContext.fetch(request)
			} catch {}
		}
		
		return result
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
	
	func setRunningWorkout(_ w: Workout?, fromSource s: RunningWorkoutSource) {
		guard s.isCurrentPlatform() else {
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

	// MARK: - Synchronization methods
	
	private var isSaving = false
	
	fileprivate func initializeWatchDatabase() {
		guard isiOS else {
			return
		}
		
		preferences.transferLocal = []
		preferences.deleteLocal = []
		
		preferences.saveRemote = []
		preferences.deleteRemote = []
		
		let data = Workout.getList().flatMap { [$0 as DataObject]
			+ $0.exercizes.map { [$0 as DataObject] + Array($0.sets) as [DataObject] }.reduce([]) { $0 + $1 } }
		wcInterface.sendUpdateForChangedObjects(data, andDeleted: [], markAsInitial: true)
		
		preferences.initialSyncDone = true
		print("Initial data sent to watch")
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
			if let obj = d.getObject() {
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
				if let tmp = obj.id.getObject() {
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
				
				if !cdObj.mergeUpdatesFrom(obj) {
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
		let context = localData.managedObjectContext
		for w in Workout.getList() {
			context.performAndWait {
				context.delete(w)
			}
		}
		
		var res = false
		context.performAndWait {
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

}

// MARK: - Core Data Stack

private class CoreDataStack {
	
	let storeName = "GymTracker"
	
	// MARK: - Initialization
	
	private static var stack: CoreDataStack?
	
	class func getStack() -> CoreDataStack {
		return CoreDataStack.stack ?? {
			let s = CoreDataStack()
			CoreDataStack.stack = s
			return s
		}()
	}
	
	private init() {
		print("Local store initialized")
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
		let url = applicationDocumentsDirectory.appendingPathComponent("\(self.storeName).sqlite")
		let options: [AnyHashable : Any] = [
			NSMigratePersistentStoresAutomaticallyOption: true,
			NSInferMappingModelAutomaticallyOption: true
		]
		
		do {
			try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
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
	
	private var session: WCSession!
	fileprivate var hasCounterPart: Bool {
		var res = session != nil
		#if os(iOS)
			res = res && session!.isPaired && session!.isWatchAppInstalled
		#endif
		
		return res
	}
	private var canComunicate: Bool {
		return session != nil && session!.activationState == .activated
	}

	// MARK: - Initialization
	
	private static var interface: WatchConnectivityInterface?
	
	class func getInterface() -> WatchConnectivityInterface {
		return WatchConnectivityInterface.interface ?? {
			let i = WatchConnectivityInterface()
			WatchConnectivityInterface.interface = i
			return i
		}()
	}

	private override init() {
		super.init()
		
		if WCSession.isSupported() {
			session = WCSession.default()
			session.delegate = self
			session.activate()
		}
		
		print("Watch/iOS interface initialized")
	}
	
	private var pendingBlock: [() -> Void] = []
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		print("Watch Connectivity Session activated")
		
		// Use this method to manage watch switching
		
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
		if hasCounterPart && !preferences.initialSyncDone {
			dataManager.initializeWatchDatabase()
		}
	}
	
	#endif
	
	// MARK: - Interaction
	
	private let changesKey = "changes"
	private let deletionKey = "deletion"
	private let currentWorkoutKey = "curWorkout"
	
	fileprivate func sendUpdateForChangedObjects(_ data: [DataObject], andDeleted delete: [CDRecordID], markAsInitial: Bool = false) {
		guard let sess = session, hasCounterPart else {
			return
		}
		
		//Prepend pending transfer to new ones
		let changedObjects = preferences.transferLocal.map { $0.getObject() }.filter { $0 != nil }.map { $0! } + data
		let deletedIDs = preferences.deleteLocal + delete
		
		guard changedObjects.count != 0 || deletedIDs.count != 0 else {
			return
		}
		
		guard canComunicate else {
			preferences.transferLocal = changedObjects.map { $0.recordID }
			preferences.deleteLocal = deletedIDs
			
			return
		}
		
		let changedData = changedObjects.map { (cdObj) -> WCObject? in
			let wcObj = cdObj.wcObject
			if markAsInitial {
				wcObj?.setAsInitialData()
			}
			
			return wcObj
		}.filter { $0 != nil }.map { $0!.wcRepresentation }
		let deletedData = deletedIDs.map { $0.wcRepresentation }
		
		var data = [ changesKey: changedData, deletionKey: deletedData ] as [String : Any]
		if markAsInitial {
			data[isInitialDataKey] = true
		}
		
		sess.transferUserInfo(data)
		preferences.transferLocal = []
		preferences.deleteLocal = []
	}
	
	fileprivate func setRunningWorkout() {
		guard let sess = session, hasCounterPart, preferences.runningWorkoutNeedsTransfer else {
			return
		}
		
		guard canComunicate else {
			preferences.runningWorkoutNeedsTransfer = true
			return
		}
		
		sess.transferUserInfo([currentWorkoutKey: [
			preferences.runningWorkout?.wcRepresentation ?? ["nil"],
			preferences.runningWorkoutSource?.rawValue ?? "nil"
		]])
		preferences.runningWorkoutNeedsTransfer = false
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
		if let curWorkout = userInfo[currentWorkoutKey] as? [Any], curWorkout.count == 2 {
			// Pass something that's not an ID to signal that workout has ended
			let w = CDRecordID(wcRepresentation: curWorkout[0] as? [String] ?? [])
			preferences.runningWorkout = w
			preferences.runningWorkoutSource = RunningWorkoutSource(rawValue: curWorkout[1] as? String ?? "")
			
			if w == nil {
				dataManager.delegate?.enableEdit()
			} else {
				dataManager.delegate?.cancelAndDisableEdit()
			}
		}
		
		if userInfo[isInitialDataKey] as? Bool ?? false, iswatchOS {
			_ = dataManager.clearDatabase()
		}
		
		DispatchQueue.gymDatabase.async {
			let changes = preferences.saveRemote + WCObject.decodeArray(userInfo[self.changesKey] as? [[String : Any]] ?? [])
			let deletion = preferences.deleteRemote + CDRecordID.decodeArray(userInfo[self.deletionKey] as? [[String]] ?? [])
			if preferences.runningWorkout != nil {
				preferences.saveRemote = changes
				preferences.deleteRemote = deletion
				
				return
			}
			
			if !dataManager.saveCounterPartUpdatesForChangedObjects(changes, andDeleted: deletion) {
				preferences.saveRemote = changes
				preferences.deleteRemote = deletion
				
				DispatchQueue.main.async {
					let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
						self.persistPendingChanges()
					}
					RunLoop.main.add(timer, forMode: .commonModes)
				}
			} else {
				preferences.saveRemote = []
				preferences.deleteRemote = []
			}
		}
	}
	
	fileprivate func persistPendingChanges() {
		DispatchQueue.gymDatabase.async {
			guard preferences.runningWorkout == nil else {
				return
			}
			
			if !dataManager.saveCounterPartUpdatesForChangedObjects(preferences.saveRemote, andDeleted: preferences.deleteRemote) {
				DispatchQueue.main.async {
					let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
						self.persistPendingChanges()
					}
					RunLoop.main.add(timer, forMode: .commonModes)
				}
			} else {
				preferences.saveRemote = []
				preferences.deleteRemote = []
			}
		}
	}
	
	// MARK: - Watch initail setup
	
	private let askDataKey = "watchNeedsData"
	private let isInitialDataKey = "isInitialData"
	private let dataIncomingKey = "dataIncoming"
	
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
				
				preferences.initialSyncDone = true
				dataManager.delegate?.refreshData()
			}) { _ in
				DispatchQueue.main.async {
					reschedule()
				}
			}
		}
		
		return !session.isReachable
	}
	
	fileprivate func sessionReachabilityDidChange(_ session: WCSession) {
		guard iswatchOS else {
			return
		}
		
		_ = askPhoneForData()
	}
	
	fileprivate func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
		if let sendData = message[askDataKey] as? Bool, isiOS, sendData {
			dataManager.initializeWatchDatabase()
			
			replyHandler([dataIncomingKey: true])
		}
	}
	
}
