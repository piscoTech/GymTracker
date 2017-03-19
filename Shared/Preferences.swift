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
	
	case initialSyncDone = "initialSync"
	
	case transferLocal = "transferLocal"
	case deleteLocal = "deleteLocal"
	case saveRemote = "saveRemote"
	case deleteRemote = "deleteRemote"
	
}

class Preferences {
	
	// MARK: - Initialization
	
	private static var pref: Preferences?
	
	private var local: KeyValueStore
	
	class func getPreferences() -> Preferences {
		return Preferences.pref ?? {
			let p = Preferences()
			Preferences.pref = p
			return p
		}()
	}
	
	class func activate() {
		let _ = getPreferences()
	}
	
	private init() {
		local = KeyValueStore(userDefaults: UserDefaults.standard)
		
		print("Preferences initialized")
	}
	
	// MARK: - Data
	
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
	
}
