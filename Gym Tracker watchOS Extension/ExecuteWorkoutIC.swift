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
				// TODO: Save workout
				cancelWorkout()
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
			// TODO: Save workout
			cancelWorkout()
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
			
			if curPart % 2 == 0 {
				setRest = nil
				exercizeNameLbl.setText(curEx.name)
				setRepWeightLbl.setText(set.description)
				
				let otherSetCount = curEx.sets.count - setN - 1
				if otherSetCount > 0 {
					otherSetsLbl.setText("\(otherSetCount)\(otherSetCount > 1 ? otherSetsTxt : otherSetTxt)")
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
		
		nextStep()
	}
	
	@IBAction func cancelWorkout() {
		timerLbl.stop()
		
		dataManager.setRunningWorkout(nil, fromSource: .watch)
		appDelegate.restoredefaultState()
	}

}
