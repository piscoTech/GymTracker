//
//  Main.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

let applicationDocumentsDirectory: URL = {
	return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
}()

let preferences = Preferences.getPreferences()
let timesSign = "×"
