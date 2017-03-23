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
	
	weak var workoutDetail: WorkoutDetailInterfaceController?
	
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
			table.setHidden(false)
			unlockMsg.setHidden(true)
		}
		
		self.workouts.removeAll(keepingCapacity: true)
		
		for w in Workout.getList() {
			if !w.archived {
				workouts.append(w)
			}
		}
		
		if workouts.count > 0 {
			table.setNumberOfRows(workouts.count, withRowType: "workout")
			
			for i in 0 ..< workouts.count {
				guard let row = table.rowController(at: i) as? BasicDetailCell else {
					continue
				}
				
				row.titleLabel.setText(workouts[i].name)
				row.detailLabel.setText(workouts[i].description)
			}
		} else {
			table.setNumberOfRows(1, withRowType: "noWorkout")
		}
		
		 workoutDetail?.reloadData()
	}
	
	override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
		guard workouts.count > 0 && segueIdentifier == "workoutDetail" else {
			return nil
		}
		
		return WorkoutDetailData(listController: self, workout: workouts[rowIndex])
	}

}
