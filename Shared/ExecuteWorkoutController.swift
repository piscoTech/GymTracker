//
//  ExecuteWorkoutController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import GymTrackerCore

extension ExecuteWorkoutController {
	
	convenience init(data: ExecuteWorkoutData, viewController ctrl: ExecuteWorkoutControllerDelegate, source: RunningWorkoutSource) {
		self.init(data: data, viewController: ctrl, source: source, dataManager: appDelegate.dataManager)
	}
	
}
