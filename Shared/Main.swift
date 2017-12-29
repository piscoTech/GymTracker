//
//  Main.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import UIKit

let customTint = #colorLiteral(red: 0.7568627451, green: 0.9215686275, blue: 0.2, alpha: 1)
let defaultTint = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
let redTint = #colorLiteral(red: 1, green: 0.1882352941, blue: 0, alpha: 1)
let greenTint = #colorLiteral(red: 0, green: 0.7529411765, blue: 0, alpha: 1)

let applicationDocumentsDirectory: URL = {
	return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
}()

let timesSign = "×"
let minusSign = "−"
let plusSign = "+"
