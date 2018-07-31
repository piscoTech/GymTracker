//
//  Preference iOS.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 31/07/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation

extension Preferences {
	
	// MARK: - Data
	
	var firstLaunchDone: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.firstLaunchDone)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.firstLaunchDone)
			local.synchronize()
		}
	}
	
	var initialSyncDone: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.initialSyncDone)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.initialSyncDone)
			local.synchronize()
		}
	}
	
	// MARK: - Local data not yet sent
	
	var transferLocal: [CDRecordID] {
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
	
	var deleteLocal: [CDRecordID] {
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
	
	var saveRemote: [WCObject] {
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
	
	var deleteRemote: [CDRecordID] {
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
	
	var runningWorkout: CDRecordID? {
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
	
	var runningWorkoutSource: RunningWorkoutSource? {
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
	
	var runningWorkoutNeedsTransfer: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.runningWorkoutNeedsTransfer)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.runningWorkoutNeedsTransfer)
			local.synchronize()
		}
	}
	
	var currentStart: Date {
		get {
			return local.object(forKey: PreferenceKeys.currentStart) as? Date ?? Date()
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.currentStart)
			local.synchronize()
		}
	}
	
	/// The current exercize, rest or circuit in the running workout.
	var currentExercize: Int {
		get {
			return local.integer(forKey: PreferenceKeys.currentExercize)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.currentExercize)
			local.synchronize()
		}
	}
	
	/// The current set inside the current exercize or circuit, if `currentRestEnd` is set the workout is currently in the rest after the set.
	var currentPart: Int {
		get {
			return local.integer(forKey: PreferenceKeys.currentPart)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.currentPart)
			local.synchronize()
		}
	}
	
	
	var currentRestEnd: Date? {
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
	
	var weightChangeCache: [CDRecordID : Double] {
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
	
	var authorized: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.authorized)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.authorized)
			local.synchronize()
		}
	}
	
	var authVersion: Int {
		get {
			return local.integer(forKey: PreferenceKeys.authVersion)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.authVersion)
			local.synchronize()
		}
	}
	
	// MARK: - Backups
	
	var useBackups: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.useBackups)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.useBackups)
			local.synchronize()
		}
	}
	
	var lastBackup: Date? {
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
