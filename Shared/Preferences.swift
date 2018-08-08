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

enum RunningWorkoutSource: String {
	
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

class Preferences {
	
	let use: DataManager.Usage
	let local: KeyValueStore
	let notificationData: KeyValueStore

	init(for use: DataManager.Usage) {
		self.use = use
		
		if use == .application {
			local = KeyValueStore(userDefaults: UserDefaults.standard)
		} else {
			local = KeyValueStore(userDefaults: UserDefaults(suiteName: "GymTrackerTests")!)
		}
		notificationData = KeyValueStore(userDefaults: UserDefaults.init(suiteName: "group.marcoboschi.gymtracker.notificationdata")!)
		
		print("\(use) Preferences initialized")
	}
	
	// MARK: - Notification Data
	
	var weightUpdatedInNotification: Bool {
		get {
			return notificationData.bool(forKey: PreferenceKeys.weightUpdatedInNotification)
		}
		set {
			notificationData.set(newValue, forKey: PreferenceKeys.weightUpdatedInNotification)
			notificationData.synchronize()
		}
	}
	
	var setEndedInNotificationTime: Date? {
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
	
	var weightChangeFromNotification: Double {
		get {
			return notificationData.double(forKey: PreferenceKeys.weightChangeFromNotification)
		}
		set {
			notificationData.set(newValue, forKey: PreferenceKeys.weightChangeFromNotification)
			notificationData.synchronize()
		}
	}
	
	func clearNotificationData() {
		weightUpdatedInNotification = false
		setEndedInNotificationTime = nil
		weightChangeFromNotification = 0
	}
	
}
