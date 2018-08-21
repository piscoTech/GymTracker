//
//  Preferences.swift
//  WorkTime
//
//  Created by Marco Boschi on 30/06/15.
//  Copyright (c) 2015 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

enum PreferenceKeys: String, KeyValueStoreKey {
	var description: String {
		return rawValue
	}
	
	case firstLaunchDone = "firstLaunchDone"
	case initialSyncDone = "initialSync"
	
	case transferLocal = "transferLocal"
	case deleteLocal = "deleteLocal"
	case saveRemote = "saveRemote"
	case deleteRemote = "deleteRemote"
	
	case runningWorkout = "runningWorkout"
	case runningWorkoutSource = "runningWorkoutSource"
	case runningWorkoutNeedsTransfer = "runningWorkoutNeedsTransfer"
	case currentStart = "currentStart"
	case currentExercize = "currentExercize"
	case currentPart = "currentPart"
	case currentRestEnd = "currentRestEnd"
	case weightChangeCache = "weightChangeCache"
	
	case authorized = "authorized"
	case authVersion = "authVersion"
	
	case useBackups = "useBackups"
	case lastBackup = "lastBackup"
	
	case weightUpdatedInNotification = "weightUpdatedInNotification"
	case setEndedInNotificationTime = "setEndedInNotification"
	case weightChangeFromNotification = "weightChangeFromNotification"
	
	case reviewRequestCounter = "reviewRequestCounter"
}

public enum RunningWorkoutSource: String {
	
	case watch = "watch"
	case phone = "phone"
	
	func isCurrentPlatform() -> Bool {
		switch self {
		case .watch:
			return iswatchOS
		case .phone:
			return isiOS
		}
	}
	
}

// MARK: -

public class Preferences {
	
	let use: DataManager.Usage
	let local: KeyValueStore
	#if os(iOS)
	let notificationData: KeyValueStore
	#endif
	
	public init(for use: DataManager.Usage) {
		self.use = use
		
		if use == .application {
			#warning("Check this is ok from inside a framework and old data from previous versions is loaded")
			local = KeyValueStore(userDefaults: UserDefaults.standard)
		} else {
			local = KeyValueStore(userDefaults: UserDefaults(suiteName: "GymTrackerTests")!)
		}
		#if os(iOS)
		#warning("Check this is ok from inside a framework")
		notificationData = KeyValueStore(userDefaults: UserDefaults.init(suiteName: "group.marcoboschi.gymtracker.notificationdata")!)
		#endif
		
		print("\(use) Preferences initialized")
	}
	
	// MARK: - Notification Data
	
	#if os(iOS)
	public var weightUpdatedInNotification: Bool {
		get {
			return notificationData.bool(forKey: PreferenceKeys.weightUpdatedInNotification)
		}
		set {
			notificationData.set(newValue, forKey: PreferenceKeys.weightUpdatedInNotification)
			notificationData.synchronize()
		}
	}
	
	public var setEndedInNotificationTime: Date? {
		get {
			return notificationData.object(forKey: PreferenceKeys.setEndedInNotificationTime) as? Date
		}
		set {
			let key = PreferenceKeys.setEndedInNotificationTime
			if let val = newValue {
				notificationData.set(val, forKey: key)
			} else {
				notificationData.removeObject(forKey: key)
			}
			notificationData.synchronize()
		}
	}
	
	#warning("Rename me")
	public var weightChangeFromNotification: Double {
		get {
			return notificationData.double(forKey: PreferenceKeys.weightChangeFromNotification)
		}
		set {
			notificationData.set(newValue, forKey: PreferenceKeys.weightChangeFromNotification)
			notificationData.synchronize()
		}
	}
	
	public func clearNotificationData() {
		weightUpdatedInNotification = false
		setEndedInNotificationTime = nil
		weightChangeFromNotification = 0
	}
	#endif
	
	// MARK: - Data
	
	public var firstLaunchDone: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.firstLaunchDone)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.firstLaunchDone)
			local.synchronize()
		}
	}
	
	public var initialSyncDone: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.initialSyncDone)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.initialSyncDone)
			local.synchronize()
		}
	}
	
	public var reviewRequestThreshold: Int {
		return 5
	}
	public var reviewRequestCounter: Int {
		get {
			return local.integer(forKey: PreferenceKeys.reviewRequestCounter)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.reviewRequestCounter)
			local.synchronize()
		}
	}
	
	// MARK: - Local data not yet sent
	
	public var transferLocal: [CDRecordID] {
		get {
			return CDRecordID.decodeArray(local.array(forKey: PreferenceKeys.transferLocal) as? [[String]] ?? [])
		}
		set {
			let key = PreferenceKeys.transferLocal
			if newValue.count > 0 {
				local.set(CDRecordID.encodeArray(newValue), forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
	public var deleteLocal: [CDRecordID] {
		get {
			return CDRecordID.decodeArray(local.array(forKey: PreferenceKeys.deleteLocal) as? [[String]] ?? [])
		}
		set {
			let key = PreferenceKeys.deleteLocal
			if newValue.count > 0 {
				local.set(CDRecordID.encodeArray(newValue), forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
	// MARK: - Updates not persisted yet
	
	public var saveRemote: [WCObject] {
		get {
			return WCObject.decodeArray(local.array(forKey: PreferenceKeys.saveRemote) as? [[String: Any]] ?? [])
		}
		set {
			let key = PreferenceKeys.saveRemote
			if newValue.count > 0 {
				local.set(WCObject.encodeArray(newValue), forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
	public var deleteRemote: [CDRecordID] {
		get {
			return CDRecordID.decodeArray(local.array(forKey: PreferenceKeys.deleteRemote) as? [[String]] ?? [])
		}
		set {
			let key = PreferenceKeys.deleteRemote
			if newValue.count > 0 {
				local.set(CDRecordID.encodeArray(newValue), forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
	// MARK: - Running Workout data
	
	public var runningWorkout: CDRecordID? {
		get {
			return CDRecordID(wcRepresentation: local.array(forKey: PreferenceKeys.runningWorkout) as? [String] ?? [])
		}
		set {
			let key = PreferenceKeys.runningWorkout
			if let data = newValue?.wcRepresentation {
				local.set(data, forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
	public var runningWorkoutSource: RunningWorkoutSource? {
		get {
			return RunningWorkoutSource(rawValue: local.string(forKey: PreferenceKeys.runningWorkoutSource) ?? "")
		}
		set {
			let key = PreferenceKeys.runningWorkoutSource
			if let data = newValue?.rawValue {
				local.set(data, forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
	public var runningWorkoutNeedsTransfer: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.runningWorkoutNeedsTransfer)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.runningWorkoutNeedsTransfer)
			local.synchronize()
		}
	}
	
	public var currentStart: Date {
		get {
			return local.object(forKey: PreferenceKeys.currentStart) as? Date ?? Date()
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.currentStart)
			local.synchronize()
		}
	}
	
	/// The current exercize, rest or circuit in the running workout.
	public var currentExercize: Int {
		get {
			return local.integer(forKey: PreferenceKeys.currentExercize)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.currentExercize)
			local.synchronize()
		}
	}
	
	/// The current set inside the current exercize or circuit, if `currentRestEnd` is set the workout is currently in the rest after the set.
	public var currentPart: Int {
		get {
			return local.integer(forKey: PreferenceKeys.currentPart)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.currentPart)
			local.synchronize()
		}
	}
	
	
	public var currentRestEnd: Date? {
		get {
			return local.object(forKey: PreferenceKeys.currentRestEnd) as? Date
		}
		set {
			let key = PreferenceKeys.currentRestEnd
			if let val = newValue {
				local.set(val, forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
	public var weightChangeCache: [CDRecordID : Double] {
		get {
			var cache: [CDRecordID : Double] = [:]
			for wc in local.array(forKey: PreferenceKeys.weightChangeCache) as? [[Any]] ?? [] {
				guard wc.count == 3, let rawId = Array(wc[0...1]) as? [String], let id = CDRecordID(wcRepresentation: rawId), let w = wc[2] as? Double else {
					continue
				}
				
				cache[id] = w
			}
			
			return cache
		}
		set {
			if newValue.isEmpty {
				local.removeObject(forKey: PreferenceKeys.weightChangeCache)
			} else {
				var cache = [[Any]]()
				for (e, w) in newValue {
					cache.append(e.wcRepresentation as [Any] + [w])
				}
				local.set(cache, forKey: PreferenceKeys.weightChangeCache)
			}
			local.synchronize()
		}
	}
	
	// MARK: - Health Access
	
	public var authorized: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.authorized)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.authorized)
			local.synchronize()
		}
	}
	
	public var authVersion: Int {
		get {
			return local.integer(forKey: PreferenceKeys.authVersion)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.authVersion)
			local.synchronize()
		}
	}
	
	// MARK: - Backups
	
	public var useBackups: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.useBackups)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.useBackups)
			local.synchronize()
		}
	}
	
	public var lastBackup: Date? {
		get {
			return local.object(forKey: PreferenceKeys.lastBackup) as? Date
		}
		set {
			let key = PreferenceKeys.lastBackup
			if let val = newValue {
				local.set(val, forKey: key)
			} else {
				local.removeObject(forKey: key)
			}
			local.synchronize()
		}
	}
	
}
