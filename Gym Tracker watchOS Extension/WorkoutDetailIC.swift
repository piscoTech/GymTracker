//
//  WorkoutDetailInterfaceController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 23/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import Foundation
import GymTrackerCore

struct WorkoutDetailData {
	
	let listController: WorkoutListInterfaceController?
	let workout: GTWorkout
	
}

class WorkoutDetailInterfaceController: WKInterfaceController {
	
	@IBOutlet weak var workoutName: WKInterfaceLabel!
	@IBOutlet weak var table: WKInterfaceTable!
	
	@IBOutlet weak var startBtn: WKInterfaceButton!
	
	private var workout: GTWorkout!
	private var delegate: WorkoutListInterfaceController?
	
	private var choices: [GTChoice: Int32]?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
		guard let data = context as? WorkoutDetailData else {
			fatalError("Inconsistent loading")
		}
		
		workout = data.workout
		delegate = data.listController
		delegate?.workoutDetail = self
		if delegate == nil {
			startBtn.setEnabled(false)
			startBtn.setHidden(true)
			appDelegate.executeWorkoutDetail = self
		}
		
		reloadData(checkExistence: false)
		updateButton()
	}
	
	func reloadData(checkExistence: Bool = true, choices: [GTChoice: Int32]? = nil, withController ctrl: ExecuteWorkoutController? = nil) {
		if checkExistence {
			guard workout.stillExists(inDataManager: appDelegate.dataManager), !workout.archived else {
				if delegate != nil {
					// If delegate is not set this is displayed as a page during a workout, so just do nothing
					self.pop()
				}
				
				return
			}
		}
		
		self.choices = choices
		workoutName.setText(workout.name)
		let exercizes = workout.exercizeList
		let exCell = "exercize"
		let rows = exercizes.flatMap { p -> [(GTPart, String)] in
			if let r = p as? GTRest {
				return [(r, "rest")]
			} else if let e = p as? GTSimpleSetsExercize {
				return [(e, exCell)]
			} else if let c = p as? GTCircuit {
				return c.exercizeList.map { ($0, exCell) }
			} else if let ch = p as? GTChoice {
				return [(ch, exCell)]
			} else {
				fatalError("Unknown part type")
			}
		}.map { p -> (GTPart, String) in
			if let ch = p.0 as? GTChoice, let i = choices?[ch], let e = ch[i] {
				return (e, exCell)
			} else {
				return p
			}
		}
		table.setRowTypes(rows.map { $0.1 })
		
		for (i, (p, _)) in zip(0 ..< rows.count, rows) {
			if let r = p as? GTRest {
				let row = table.rowController(at: i) as! RestCell
				row.setRest(r.rest)
			} else if let se = p as? GTSetsExercize {
				let row = table.rowController(at: i) as! ExercizeCell
				if let curWrkt = ctrl {
					row.detailLabel.setAttributedText(se.summaryWithSecondaryInfoChange(from: curWrkt))
				} else {
					row.detailLabel.setText(se.summary)
				}
				row.accessoryWidth = 21
				row.showAccessory(false)
				
				if let e = se as? GTSimpleSetsExercize {
					row.set(title: e.title)
				} else if let ch = se as? GTChoice {
					row.setChoice(title: ch.title, total: ch.exercizes.count)
				} else {
					fatalError("Unknown part type")
				}
				
				if let (n, t) = se.circuitStatus {
					row.setCircuit(number: n, total: t)
				}
			} else {
				fatalError("Unknown part type")
			}
		}
    }
	
	func reloadDetails(from ctrl: ExecuteWorkoutController) {
		reloadData(checkExistence: false, choices: self.choices, withController: ctrl)
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
		startBtn.setEnabled(delegate?.canEdit ?? false)
	}
	
	@IBAction func startWorkout() {
		guard delegate?.canEdit ?? false, appDelegate.dataManager.preferences.runningWorkout == nil else {
			return
		}
		
		appDelegate.startWorkout(with: ExecuteWorkoutData(workout: workout, resume: false))
	}

}
