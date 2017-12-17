//
//  WorkoutDetailInterfaceController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 23/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import Foundation

struct WorkoutDetailData {
	
	let listController: WorkoutListInterfaceController
	let workout: Workout
	
}

class WorkoutDetailInterfaceController: WKInterfaceController {
	
	@IBOutlet weak var workoutName: WKInterfaceLabel!
	@IBOutlet weak var table: WKInterfaceTable!
	
	@IBOutlet weak var startBtn: WKInterfaceButton!
	
	private var workout: OrganizedWorkout!
	private var delegate: WorkoutListInterfaceController!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		guard let data = context as? WorkoutDetailData else {
			self.pop()
			
			return
		}
		
		workout = OrganizedWorkout(data.workout)
		delegate = data.listController
		delegate.workoutDetail = self
		
		reloadData(checkExistence: false)
		updateButton()
	}
	
	func reloadData(checkExistence: Bool = true) {
		if checkExistence {
			guard workout.raw.stillExists(inDataManager: appDelegate.dataManager), !workout.archived else {
				self.pop()
				
				return
			}
		}
		
		workoutName.setText(workout.name)
		let exercizes = workout.exercizes
		let rows = exercizes.map { e -> (Int, String, (Int, Int)?) in
			let ord = Int(e.order)
			if e.isRest {
				return (ord, "rest", nil)
			} else {
				let circuit = workout.circuitStatus(for: e)
				return (ord, "exercize" + (circuit != nil ? "Circuit" : ""), circuit)
			}
		}
		table.setRowTypes(rows.map { $0.1 })
		
		for (i, type, circuit) in rows {
			if type == "rest" {
				let row = table.rowController(at: i) as! RestCell
				row.setRest(exercizes[i].rest)
			} else {
				let row = table.rowController(at: i) as! BasicDetailCell
				row.titleLabel.setText(exercizes[i].name)
				row.detailLabel.setText(exercizes[i].setsSummary)
				if let (n, t) = circuit {
					row.circuitLabel.setText("\(n)/\(t)")
				}
			}
		}
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
	func updateButton() {
		startBtn.setEnabled(delegate.canEdit)
	}
	
	@IBAction func startWorkout() {
		guard delegate.canEdit, appDelegate.dataManager.preferences.runningWorkout == nil else {
			return
		}
		
		appDelegate.startWorkout(with: ExecuteWorkoutData(workout: workout.raw, resumeData: nil))
	}

}
