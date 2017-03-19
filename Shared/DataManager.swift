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
	
	var created: Date? {
		return data[DataObject.createdKey] as? Date
	}
	
	fileprivate var isNew: Bool? {
		guard let created = self.created, let modified = data[DataObject.modifiedKey] as? Date else {
			return nil
		}
		
		return created == modified
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
	
}

// MARK: - Data Manager

class DataManager: NSObject {
	
	weak var delegate: DataManagerDelegate?
	
	fileprivate private(set) var localData: CoreDataStack
	fileprivate private(set) var wcInterface: WatchConnectivityInterface
	
	// MARK: - Initialization
	
	private static var manager: DataManager?
	
	class func getManager(withDelegate delegate: DataManagerDelegate?) -> DataManager {
		DataManager.manager?.delegate = delegate
		
		return DataManager.manager ?? {
			let m = DataManager(delegate: delegate)
			DataManager.manager = m
			return m
		}()
	}
	
	class func activate(withDelegate delegate: DataManagerDelegate?) {
		let _ = getManager(withDelegate: delegate)
	}
	
	override private convenience init() {
		self.init(delegate: nil)
	}
	
	private init(delegate: DataManagerDelegate?) {
		localData = CoreDataStack.getStack()
		wcInterface = WatchConnectivityInterface.getInterface()
		
		super.init()
		
		self.delegate = delegate
		localData.dataManager = self
		wcInterface.dataManager = self
		
		// Use for cleanup during development
//		preferences.addFromLocal = []
//		preferences.updateFromLocal = []
//		preferences.deleteFromLocal = []

		print("Data Manager initialized")
		
		if !preferences.initialSyncDone && wcInterface.hasCounterPart {
			// TODO: Invoke initialization process (include cleaning pending local transfer and not persisted changes), only from iPhone
		}
		
		// TODO: Check if no running workout and persist any pending changes
	}
	

	// MARK: - Interaction
	
	var runningWorkout: CDRecordID? {
		didSet {
			// TODO: Save this in preferences alongside which device it is on
			
			if runningWorkout != nil && runningWorkout!.type != Workout.objectType {
				runningWorkout = nil
				
				return
			}
			
			if runningWorkout == nil {
				wcInterface.persistPendingChanges()
			}
		}
	}

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
		
		if obj.mergeUpdatesFrom(src) {
			return obj
		} else {
			return nil
		}
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
			context.delete(r)
			return id
		}
		
		let now = Date()
		for obj in data {
			if obj.created == nil {
				obj.created = now
			}
			obj.modified = now
		}
		
		do {
			try context.save()
			
			wcInterface.sendUpdateForChangedObjects(data, andDeleted: removedIDs)
			
			return true
		} catch let error {
			print(error.localizedDescription)
			for e in (error as NSError).userInfo[NSDetailedErrorsKey] as? [NSError] ?? [] {
				print(e.localizedDescription)
			}
			
			return false
		}
	}

	// MARK: - Synchronization methods

	fileprivate func saveCounterPartUpdatesForChangedObjects(_ changes: [WCObject], andDeleted deletion: [CDRecordID]) -> Bool {
		// TODO: Make delegate terminate any editing action to remove/save any uncommitted changes
		let context = localData.managedObjectContext
		
		// Delete objects
		for d in deletion {
			// If the object is missing it's been already deleted so no problem
			if let obj = d.getObject() {
				context.delete(obj)
			}
		}
		
		// Save changes
		let order: [DataObject.Type] = [Workout.self, Exercize.self, RepsSet.self]
		var pendingSave = changes
		for type in order {
			for obj in pendingSave {
				// TODO: Merge changes
				
				pendingSave.removeElement(obj)
			}
		}
		
		return false
	}

}

// MARK: - Core Data Stack

private class CoreDataStack {
	
	let storeName = "GymTracker"
	
	weak var dataManager: DataManager!
	
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
	
	weak var dataManager: DataManager!
	
	private var session: WCSession?
	fileprivate var hasCounterPart: Bool {
		return session != nil && session!.isPaired && session!.isWatchAppInstalled
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
			let session = WCSession.default()
			session.delegate = self
			session.activate()
		}
		
		print("Watch/iOS interface initialized")
	}
	
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
		// Use this method to manage watch switching
		
		// Send pending transfers
		sendUpdateForChangedObjects([], andDeleted: [])
	}
	
	func sessionDidBecomeInactive(_ session: WCSession) {
		// Use this method to manage watch switching
	}
	
	func sessionDidDeactivate(_ session: WCSession) {
		session.activate()
	}
	
	func sessionWatchStateDidChange(_ session: WCSession) {
		if hasCounterPart {
			// TODO: Invoke initialization process
		}
	}
	
	// MARK: - Interaction
	
	private let changesKey = "changes"
	private let deletionKey = "deletion"
	private let currentWorkoutKey = "curWorkout"
	
	fileprivate func sendUpdateForChangedObjects(_ data: [DataObject], andDeleted delete: [CDRecordID]) {
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
		
		let changedData = changedObjects.map { $0.wcObject }.filter { $0 != nil }.map { $0!.wcRepresentation }
		let deletedData = deletedIDs.map { $0.wcRepresentation }
		
		let data = [ changesKey: changedData, deletionKey: deletedData ] as [String : Any]
		
		sess.transferUserInfo(data)
		preferences.transferLocal = []
		preferences.deleteLocal = []
	}
	
	fileprivate func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
		guard error != nil else {
			return
		}
		
		Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
			guard let sess = self.session, self.hasCounterPart, self.canComunicate else {
				return
			}
			
			sess.transferUserInfo(userInfoTransfer.userInfo)
		}
	}

	fileprivate func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
		if let curWorkout = userInfo[currentWorkoutKey] {
			// Pass something that's not an ID to signal that workout has ended
			dataManager.runningWorkout = curWorkout as? CDRecordID
			
			// TODO: Proper support
		}
		
		let changes = preferences.saveRemote + WCObject.decodeArray(userInfo[changesKey] as? [[String : Any]] ?? [])
		let deletion = preferences.deleteRemote + CDRecordID.decodeArray(userInfo[deletionKey] as? [[String]] ?? [])
		if dataManager.runningWorkout != nil {
			preferences.saveRemote = changes
			preferences.deleteRemote = deletion
			
			return
		}
		
		if !dataManager.saveCounterPartUpdatesForChangedObjects(changes, andDeleted: deletion) {
			preferences.saveRemote = changes
			preferences.deleteRemote = deletion
			
			Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
				self.persistPendingChanges()
			}
		} else {
			preferences.saveRemote = []
			preferences.deleteRemote = []
		}
	}
	
	fileprivate func persistPendingChanges() {
		guard dataManager.runningWorkout == nil else {
			return
		}
		
		if !dataManager.saveCounterPartUpdatesForChangedObjects(preferences.saveRemote, andDeleted: preferences.deleteRemote) {
			Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
				self.persistPendingChanges()
			}
		} else {
			preferences.saveRemote = []
			preferences.deleteRemote = []
		}
	}
	
}
