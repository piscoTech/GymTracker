//
//  ExecuteWorkoutInterfaceController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 24/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import Foundation

class ExecuteWorkoutInterfaceController: WKInterfaceController {
	
	private var workout: Workout!
	
	@IBOutlet weak var timer: WKInterfaceTimer!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		
		guard let workout = context as? Workout else {
			appDelegate.restoredefaultState()
			return
		}
		
		appDelegate.executeWorkout = self
		self.workout = workout
        dataManager.setRunningWorkout(workout, fromSource: .watch)
		
		let now = Date()
		timer.setDate(now)
		timer.start()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
	@IBAction func cancelWorkout() {
		timer.stop()
		
		dataManager.setRunningWorkout(nil, fromSource: .watch)
		appDelegate.restoredefaultState()
	}

}
