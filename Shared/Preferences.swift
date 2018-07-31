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
			return notificationData.bool(forKey: PreferenceKeys.weightUpdatedInNotification.rawValue)
		}
		set {
			notificationData.set(newValue, forKey: PreferenceKeys.weightUpdatedInNotification.rawValue)
			notificationData.synchronize()
		}
	}
	
}
