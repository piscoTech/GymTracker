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
	private var start: Date!
	
	@IBOutlet weak var timerLbl: WKInterfaceTimer!
	@IBOutlet weak var bpmLbl: WKInterfaceLabel!
	
	@IBOutlet var currentSetGrp: WKInterfaceGroup!
	@IBOutlet var exercizeNameLbl: WKInterfaceLabel!
	@IBOutlet var setRepWeightLbl: WKInterfaceLabel!
	@IBOutlet var otherSetsLbl: WKInterfaceLabel!
	
	@IBOutlet var restGrp: WKInterfaceGroup!
	
	@IBOutlet var restLbl: WKInterfaceTimer!
	@IBOutlet var restExercizeNameLbl: WKInterfaceLabel!
	@IBOutlet var nextUpLbl: WKInterfaceLabel!
	
	@IBOutlet var workoutDoneGrp: WKInterfaceGroup!
	@IBOutlet var workoutDoneLbl: WKInterfaceLabel!
	
	private let noHeart = "– –"
	private let nextTxt = NSLocalizedString("NEXT_EXERCIZE_FLAG", comment: "Next:")
	private let nextEndTxt = NSLocalizedString("NEXT_EXERCIZE_END", comment: "End")
	private let nextRestTxt = NSLocalizedString("NEXT_EXERCIZE_REST", comment: "rest")
	private let otherSetTxt = NSLocalizedString("OTHER_N_SET", comment: "other set")
	private let otherSetsTxt = NSLocalizedString("OTHER_N_SETS", comment: "other sets")
	
	private var exercizes: [Exercize]!
	private var curPart = 0
	private var isRestMode = false
	private var restTimer: Timer?
	var addWeight = 0.0
	
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		
		guard let workout = context as? Workout else {
			appDelegate.restoredefaultState()
			return
		}
		
		appDelegate.executeWorkout = self
		self.workout = workout
        dataManager.setRunningWorkout(workout, fromSource: .watch)
		
		exercizes = workout.exercizeList
		
		bpmLbl.setText(noHeart)
		
		start = Date()
		timerLbl.setDate(start)
		timerLbl.start()
		
		workoutDoneGrp.setHidden(true)
		nextStep(true)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
	private func nextStep(_ isInitialSetup: Bool = false) {
		if !isInitialSetup {
			guard let curEx = exercizes.first else {
				saveWorkout()
				return
			}
			
			if curEx.isRest {
				exercizes.remove(at: 0)
				curPart = 0
			} else {
				let maxPart = 2 * curEx.sets.count - 1
				curPart += 1
				if curPart >= maxPart {
					exercizes.remove(at: 0)
					curPart = 0
				}
			}
		}
		
		guard let curEx = exercizes.first else {
			saveWorkout()
			return
		}
		
		var setRest: TimeInterval?
		
		if curEx.isRest {
			setRest = curEx.rest
			restExercizeNameLbl.setHidden(true)
		} else {
			let setN = curPart / 2
			guard let set = curEx.set(n: Int32(setN)) else {
				nextStep()
				return
			}
			
			if curPart == 0 {
				// Reset add weight for new exercize
				addWeight = 0
			}
			
			if curPart % 2 == 0 {
				setRest = nil
				exercizeNameLbl.setText(curEx.name)
				setRepWeightLbl.setText(set.description)
				
				let otherSet = Array(curEx.setList.suffix(from: setN + 1))
				if otherSet.count > 0 {
					otherSetsLbl.setText("\(otherSet.count)\(otherSet.count > 1 ? otherSetsTxt : otherSetTxt): " + otherSet.map { "\($0.weight.toString())kg" }.joined(separator: ", "))
					otherSetsLbl.setHidden(false)
				} else {
					otherSetsLbl.setHidden(true)
				}
			} else {
				setRest = set.rest
				restExercizeNameLbl.setText(curEx.name)
				restExercizeNameLbl.setHidden(false)
			}
		}
		
		if let restTime = setRest {
			WKInterfaceDevice.current().play(.click)
			
			guard restTime > 0 else {
				// A rest time of 0:00 is allowed between sets, jump to next set
				nextStep()
				return
			}
			
			restLbl.setDate(Date().addingTimeInterval(restTime))
			restLbl.start()
			restGrp.setHidden(false)
			currentSetGrp.setHidden(true)
			
			restTimer = Timer.scheduledTimer(withTimeInterval: restTime, repeats: false) { _ in
				self.restLbl.stop()
				let sound = WKHapticType.stop
				WKInterfaceDevice.current().play(sound)
				DispatchQueue.main.async {
					self.restTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
						WKInterfaceDevice.current().play(sound)
					}
					RunLoop.main.add(self.restTimer!, forMode: .commonModes)
				}
				
			}
			RunLoop.main.add(restTimer!, forMode: .commonModes)
		} else {
			restLbl.stop()
			restGrp.setHidden(true)
			currentSetGrp.setHidden(false)
		}
		isRestMode = setRest != nil
		
		if exercizes.count >= 2 {
			let txt: String
			let nextEx = exercizes[1]
			if nextEx.isRest {
				txt = nextEx.rest.getDuration(hideHours: true) + nextRestTxt
			} else {
				txt = nextEx.name!
			}
			nextUpLbl.setText(nextTxt + txt)
		} else {
			nextUpLbl.setText(nextTxt + nextEndTxt)
		}
	}
	
	@IBAction func endRest() {
		guard isRestMode else {
			return
		}
		
		restLbl.stop()
		restTimer?.invalidate()
		restTimer = nil
		
		nextStep()
	}
	
	@IBAction func endSet() {
		guard !isRestMode else {
			return
		}
		
		if let curEx = exercizes.first, !curEx.isRest, let set = curEx.set(n: Int32(curPart / 2)) {
			presentController(withName: "updateWeight", context: UpdateWeightData(workoutController: self, set: set, sum: addWeight))
		}
		nextStep()
	}
	
	private func saveWorkout() {
		timerLbl.stop()
		dataManager.setRunningWorkout(nil, fromSource: .watch)
		
		currentSetGrp.setHidden(true)
		currentSetGrp.setHidden(true)
		nextUpLbl.setHidden(true)
		workoutDoneGrp.setHidden(false)
		
		if true {
			workoutDoneLbl.setText(NSLocalizedString("WORKOUT_SAVED", comment: "Saved"))
		} else {
			workoutDoneLbl.setText(NSLocalizedString("WORKOUT_SAVE_ERROR", comment: "Error"))
		}
	}
	
	@IBAction func cancelWorkout() {
		dataManager.setRunningWorkout(nil, fromSource: .watch)
		exitWorkout()
	}
	
	@IBAction func exitWorkout() {
		appDelegate.restoredefaultState()
	}

}
