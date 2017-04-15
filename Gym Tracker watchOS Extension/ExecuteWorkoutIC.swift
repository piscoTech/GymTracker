//
//  ExecuteWorkoutInterfaceController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 24/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import HealthKit
import Foundation

class ExecuteWorkoutInterfaceController: WKInterfaceController, ExecuteWorkoutControllerDelegate {
	
	@IBOutlet weak var timerLbl: WKInterfaceTimer!
	@IBOutlet weak var bpmLbl: WKInterfaceLabel!
	
	@IBOutlet weak var currentExercizeGrp: WKInterfaceGroup!
	@IBOutlet weak var exercizeNameLbl: WKInterfaceLabel!
	@IBOutlet weak var currentSetGrp: WKInterfaceGroup!
	@IBOutlet weak var setRepWeightLbl: WKInterfaceLabel!
	@IBOutlet weak var otherSetsLbl: WKInterfaceLabel!
	@IBOutlet weak var doneSetBtn: WKInterfaceButton!
	
	@IBOutlet weak var restGrp: WKInterfaceGroup!
	@IBOutlet weak var restLbl: WKInterfaceTimer!
	@IBOutlet weak var restEndBtn: WKInterfaceButton!
	
	@IBOutlet weak var nextUpLbl: WKInterfaceLabel!
	
	@IBOutlet weak var workoutDoneGrp: WKInterfaceGroup!
	@IBOutlet weak var workoutDoneLbl: WKInterfaceLabel!
	@IBOutlet weak var workoutDoneBtn: WKInterfaceButton!
	
	private var workoutController: ExecuteWorkoutController!
	private var restTimer: Timer?
	
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		
		guard let data = context as? ExecuteWorkoutData else {
			appDelegate.restoredefaultState()
			return
		}
		
		appDelegate.executeWorkout = self
		addMenuItem(with: .decline, title: NSLocalizedString("CANCEL", comment: "cancel"), action: #selector(cancelWorkout))
		addMenuItem(with: .accept, title: NSLocalizedString("WORKOUT_END_BUTTON", comment: "End"), action: #selector(endWorkout))
		
		DispatchQueue.main.async {
			self.workoutController = ExecuteWorkoutController(data: data, viewController: self, source: .watch)
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
	
	// MARK: - ExecuteWorkoutViewController
	
	func setWorkoutTitle(_ text: String) {
		self.setTitle(text)
	}
	
	func setBPM(_ text: String) {
		bpmLbl.setText(text)
	}
	
	func startTimer(at date: Date) {
		timerLbl.setDate(date)
		timerLbl.start()
	}
	
	func stopTimer() {
		timerLbl.stop()
	}
	
	func setCurrentExercizeViewHidden(_ hidden: Bool) {
		currentExercizeGrp.setHidden(hidden)
	}
	
	func setExercizeName(_ name: String) {
		exercizeNameLbl.setText(name)
	}
	
	func setCurrentSetViewHidden(_ hidden: Bool) {
		currentSetGrp.setHidden(hidden)
	}
	
	func setCurrentSetText(_ text: String) {
		setRepWeightLbl.setText(text)
	}
	
	func setOtherSetsViewHidden(_ hidden: Bool) {
		otherSetsLbl.setHidden(hidden)
	}
	
	func setOtherSetsText(_ text: String) {
		otherSetsLbl.setText(text)
	}
	
	func setSetDoneButtonHidden(_ hidden: Bool) {
		doneSetBtn.setHidden(hidden)
	}
	
	func startRestTimer(to date: Date) {
		restLbl.setDate(date)
		restLbl.start()
	}
	
	func stopRestTimer() {
		restLbl.stop()
	}
	
	func setRestViewHidden(_ hidden: Bool) {
		restGrp.setHidden(hidden)
	}
	
	func setRestEndButtonHidden(_ hidden: Bool) {
		restEndBtn.setHidden(hidden)
	}
	
	func setWorkoutDoneViewHidden(_ hidden: Bool) {
		workoutDoneGrp.setHidden(hidden)
	}
	
	func setWorkoutDoneText(_ text: String) {
		workoutDoneLbl.setText(text)
	}
	
	func setWorkoutDoneButtonEnabled(_ enabled: Bool) {
		workoutDoneBtn.setEnabled(enabled)
	}
	
	func disableGlobalActions() {
		clearAllMenuItems()
	}
	
	func setNextUpTextHidden(_ hidden: Bool) {
		nextUpLbl.setHidden(hidden)
	}
	
	func setNextUpText(_ text: String) {
		nextUpLbl.setText(text)
	}
	
	func notifyEndRest() {
		let sound = WKHapticType.stop
		WKInterfaceDevice.current().play(sound)
		DispatchQueue.main.async {
			self.restTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
				WKInterfaceDevice.current().play(sound)
			}
			RunLoop.main.add(self.restTimer!, forMode: .commonModes)
		}
	}
	
	func endNotifyEndRest() {
		DispatchQueue.main.async {
			self.restTimer?.invalidate()
			self.restTimer = nil
		}
	}
	
	func notifyExercizeChange(isRest: Bool) {
		WKInterfaceDevice.current().play(.click)
	}
	
	func askUpdateWeight(with data: UpdateWeightData) {
		presentController(withName: "updateWeight", context: data)
	}
	
	@IBAction func endRest() {
		workoutController.endRest()
	}
	
	@IBAction func endSet() {
		workoutController.endSet()
	}
	
	func endWorkout() {
		workoutController.endWorkout()
	}
	
	func cancelWorkout() {
		workoutController.cancelWorkout()
	}
	
	func workoutHasStarted() {}
	
	@IBAction func exitWorkoutTracking() {
		appDelegate.restoredefaultState()
	}

}
