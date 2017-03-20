//
//  WorkoutListController.swift
//  Gym Tracker watchOS Extension
//
//  Created by Marco Boschi on 20/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import Foundation


class WorkoutListController: WKInterfaceController {
	
	// private weak var workoutDetail: Any?
	
	private var workouts: [Workout] = []
	
	@IBOutlet weak var table: WKInterfaceTable!
	@IBOutlet weak var unlockMsg: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		appDelegate.workoutList = self

		reloadData()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
	func reloadData() {
		if !preferences.initialSyncDone && dataManager.askPhoneForData() {
			table.setHidden(true)
			unlockMsg.setHidden(false)
		} else {
			table.setHidden(true)
			unlockMsg.setHidden(false)
		}
		
		self.workouts.removeAll(keepingCapacity: true)
		
		for w in Workout.getList() {
			if !w.archived {
				workouts.append(w)
			}
		}
		
//		tableView.reloadData()
		
		// TODO: if workout is deleted pop the controller
		// workoutDetail?.refresh()
	}

}
