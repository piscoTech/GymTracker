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

let dataManager = DataManager.getManager(withDelegate: nil)
let timesSign = "×"
