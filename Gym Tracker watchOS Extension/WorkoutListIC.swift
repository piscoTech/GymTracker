//
//  WorkoutListInterfaceController.swift
//  Gym Tracker watchOS Extension
//
//  Created by Marco Boschi on 20/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import Foundation

class WorkoutListInterfaceController: WKInterfaceController {
	
	weak var workoutDetail: WorkoutDetailInterfaceController?
	
	private var workouts: [Workout] = []
	
	@IBOutlet weak var table: WKInterfaceTable!
	@IBOutlet weak var unlockMsg: WKInterfaceLabel!
	
	var canEdit = appDelegate.dataManager.preferences.runningWorkout == nil
	private var activated = false
	private(set) var resuming = false

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		appDelegate.workoutList = self

		reloadData()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
		
		if !appDelegate.dataManager.preferences.authorized || appDelegate.dataManager.preferences.authVersion < authRequired {
			authorize()
		}
		
		activated = true
		resumeWorkout()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
	func reloadData() {
		if !appDelegate.dataManager.preferences.initialSyncDone && appDelegate.dataManager.askPhoneForData() {
			table.setHidden(true)
			unlockMsg.setHidden(false)
		} else {
			table.setHidden(false)
			unlockMsg.setHidden(true)
		}
		
		self.workouts.removeAll(keepingCapacity: true)
		
		for w in Workout.getList(fromDataManager: appDelegate.dataManager) {
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
	
	@IBAction func forceReloadData() {
		appDelegate.dataManager.preferences.initialSyncDone = false
		reloadData()
	}
	
	func authorize() {
		healthStore.requestAuthorization(toShare: healthWriteData, read: healthReadData) { (success, _) in
			if success {
				appDelegate.dataManager.preferences.authorized = true
				appDelegate.dataManager.preferences.authVersion = authRequired
			}
		}
	}
	
	func resumeWorkout() {
		guard activated else {
			return
		}
		
		guard let (workout, start, exercize, part) = appDelegate.tryResumeData else {
			return
		}
		
		resuming = true
		let resumeAct = WKAlertAction(title: NSLocalizedString("WORKOUT_DO_RESUME", comment: "Yes"), style: .default) {
			WKInterfaceController.reloadRootControllers(withNames: ["executeWorkout"],
														contexts: [ExecuteWorkoutData(workout: workout, resumeData: (start, exercize, part))])
			self.resuming = false
		}
		let cancelAct = WKAlertAction(title: NSLocalizedString("WORKOUT_DONT_RESUME", comment: "No"), style: .destructive) {
			self.resuming = false
		}
		
		DispatchQueue.main.asyncAfter(delay: 0.5) {
			self.presentAlert(withTitle: NSLocalizedString("WORKOUT_RESUME", comment: "Resume?"), message: NSLocalizedString("WORKOUT_RESUME_TEXT", comment: "Resume?"), preferredStyle: .sideBySideButtonsAlert, actions: [resumeAct, cancelAct])
		}
		
		appDelegate.tryResumeData = nil
	}
	
	override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
		guard workouts.count > 0 && segueIdentifier == "workoutDetail" else {
			return nil
		}
		
		return WorkoutDetailData(listController: self, workout: workouts[rowIndex])
	}
	
	func setEnable(_ flag: Bool) {
		canEdit = flag
		workoutDetail?.updateButton()
	}

}
