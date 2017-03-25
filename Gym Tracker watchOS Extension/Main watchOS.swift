//
//  Main watchOS.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 20/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import HealthKit

var appDelegate: ExtensionDelegate = {
	return WKExtension.shared().delegate as! ExtensionDelegate
}()
