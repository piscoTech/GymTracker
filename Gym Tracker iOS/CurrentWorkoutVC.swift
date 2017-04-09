//
//  CurrentWorkoutViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 08/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class CurrentWorkoutViewController: UIViewController, ExecuteWorkoutViewController {
	
	@IBOutlet weak var manageFromWatchLbl: UILabel!
	@IBOutlet weak var noWorkoutLabel: UIView!
	@IBOutlet weak var workoutInfo: UIStackView!

	@IBOutlet weak var workoutTitleLbl: UILabel!
	@IBOutlet weak var bpmLbl: UILabel!
	@IBOutlet weak var timerLbl: UILabel!
	
	@IBOutlet weak var currentExercizeInfo: UIStackView!
	@IBOutlet weak var exercizeNameLbl: UILabel!
	@IBOutlet weak var currentSetInfo: UIView!
	@IBOutlet weak var currentSetInfoLbl: UILabel!
	@IBOutlet weak var otherSetsLbl: UILabel!
	@IBOutlet weak var setDoneBtn: UIButton!
	
	@IBOutlet weak var restInfo: UIStackView!
	@IBOutlet weak var restTimerLbl: UILabel!
	@IBOutlet weak var restDoneBtn: UIButton!
	
	@IBOutlet weak var workoutDoneInfo: UIStackView!
	@IBOutlet weak var workoutDoneLbl: UILabel!
	@IBOutlet weak var workoutDoneBtn: UIButton!
	
	@IBOutlet weak var nextUpInfo: UIView!
	@IBOutlet weak var nextUpLbl: UILabel!
	
	private var workoutController: ExecuteWorkoutController?

    override func viewDidLoad() {
        super.viewDidLoad()
		
		appDelegate.currentWorkout = self

		for b in [setDoneBtn!, restDoneBtn!] {
			b.clipsToBounds = true
			b.layer.cornerRadius = 5
		}
		
		for l in [bpmLbl!, timerLbl!, restTimerLbl!] {
			l.font = l.font.makeMonospacedDigit()
		}
		
		if preferences.runningWorkout != nil, let src = preferences.runningWorkoutSource, src == .watch {
			updateMirroredWorkout(withCurrentExercize: preferences.currentExercize, part: preferences.currentPart, andTime: Date())
		} else {
			exitWorkoutTracking()
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date) {
		guard preferences.runningWorkout != nil else {
			return
		}
		
		if workoutController == nil {
			workoutController = ExecuteWorkoutController(mirrorWorkoutForViewController: self)
		}
		
		guard let controller = workoutController, controller.isMirroring else {
			return
		}
		
		controller.updateMirroredWorkout(withCurrentExercize: exercize, part: part, andTime: date)
	}
	
	func mirroredWorkoutHasEnded() {
		guard let controller = workoutController, controller.isMirroring else {
			return
		}
		
		controller.mirroredWorkoutHasEnded()
	}
	
	// MARK: - ExecuteWorkoutViewController
	
	func setWorkoutTitle(_ text: String) {
		workoutTitleLbl.text = text
	}
	
	func setBPM(_ text: String) {
		bpmLbl.text = text
	}
	
	private var timerDate: Date!
	private var timerUpdater: Timer?
	
	func startTimer(at date: Date) {
		timerDate = date
		
		let update = {
			self.timerLbl.text = Date().timeIntervalSince(self.timerDate).getDuration()
		}
		timerUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
			update()
		}
		RunLoop.main.add(timerUpdater!, forMode: .commonModes)
		update()
	}
	
	func stopTimer() {
		timerUpdater?.invalidate()
		timerUpdater = nil
	}
	
	private var currentExercizeInfoSpacing: CGFloat?
	
	func setCurrentExercizeViewHidden(_ hidden: Bool) {
		if hidden {
			currentExercizeInfoSpacing = currentExercizeInfo.isHidden
				? currentExercizeInfoSpacing
				: currentExercizeInfo.spacing
			
			currentExercizeInfo.spacing = 0
		} else {
			currentExercizeInfo.spacing = currentExercizeInfoSpacing ?? 0
		}
		
		currentExercizeInfo.isHidden = hidden
	}
	
	func setExercizeName(_ name: String) {
		exercizeNameLbl.text = name
	}
	
	func setCurrentSetViewHidden(_ hidden: Bool) {
		currentSetInfo.isHidden = hidden
	}
	
	func setCurrentSetText(_ text: String) {
		currentSetInfoLbl.text = text
	}
	
	func setOtherSetsViewHidden(_ hidden: Bool) {
		otherSetsLbl.isHidden = hidden
	}
	
	func setOtherSetsText(_ text: String) {
		otherSetsLbl.text = text
	}
	
	func setSetDoneButtonHidden(_ hidden: Bool) {
		setDoneBtn.isHidden = hidden
	}
	
	private var restTimerDate: Date!
	private var restTimerUpdater: Timer?
	
	func startRestTimer(to date: Date) {
		restTimerDate = date
		
		let update = {
			let time = max(self.restTimerDate.timeIntervalSince(Date()), 0)
			self.restTimerLbl.text = time.getDuration(hideHours: true)
			
			if time == 0 {
				self.stopRestTimer()
			}
		}
		restTimerUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
			update()
		}
		RunLoop.main.add(restTimerUpdater!, forMode: .commonModes)
		update()
	}
	
	func stopRestTimer() {
		restTimerUpdater?.invalidate()
		restTimerUpdater = nil
	}
	
	private var restInfoSpacing: CGFloat?
	
	func setRestViewHidden(_ hidden: Bool) {
		if hidden {
			restInfoSpacing = restInfo.isHidden
				? restInfoSpacing
				: restInfo.spacing
			
			restInfo.spacing = 0
		} else {
			restInfo.spacing = restInfoSpacing ?? 0
		}
		
		restInfo.isHidden = hidden
	}
	
	func setRestEndButtonHidden(_ hidden: Bool) {
		restDoneBtn.isHidden = hidden
	}
	
	private var workoutDoneInfoSpacing: CGFloat?
	
	func setWorkoutDoneViewHidden(_ hidden: Bool) {
		if hidden {
			workoutDoneInfoSpacing = workoutDoneInfo.isHidden
				? workoutDoneInfoSpacing
				: workoutDoneInfo.spacing
			
			workoutDoneInfo.spacing = 0
		} else {
			workoutDoneInfo.spacing = workoutDoneInfoSpacing ?? 0
		}
		
		workoutDoneInfo.isHidden = hidden
	}
	
	func setWorkoutDoneText(_ text: String) {
		workoutDoneLbl.text = text
	}
	
	func setWorkoutDoneButtonEnabled(_ enabled: Bool) {
		workoutDoneBtn.isEnabled = enabled
	}
	
	func setNextUpTextHidden(_ hidden: Bool) {
		nextUpInfo.isHidden = hidden
	}
	
	func setNextUpText(_ text: String) {
		nextUpLbl.text = text
	}
	
	func notifyEndRest() {
		// TODO: Implement for workout on phone
	}
	
	func endNotifyEndRest() {
		// TODO: Implement for workout on phone
	}
	
	func notifyExercizeChange() {
		// TODO: Implement for workout on phone
	}
	
	func askUpdateWeight(with data: UpdateWeightData) {
		// TODO: Implement for workout on phone
	}
	
	func workoutHasStarted() {
		manageFromWatchLbl.isHidden = !(workoutController?.isMirroring ?? false)
		noWorkoutLabel.isHidden = true
		workoutInfo.isHidden = false
	}
	
	func exitWorkoutTracking() {
		workoutController = nil
		
		noWorkoutLabel.isHidden = false
		workoutInfo.isHidden = true
	}
	
	
}
