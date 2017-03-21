//
//  Main iOS & watchOS.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

let applicationDocumentsDirectory: URL = {
	return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
}()

let dataManager = DataManager.getManager()
let preferences = Preferences.getPreferences()
let timesSign = "×"
let maxRest: TimeInterval = 5 * 60

extension DispatchQueue {
	
	static let gymDatabase = DispatchQueue(label: "Marco-Boschi.ios.Gym-Tracker.database")
	
}
