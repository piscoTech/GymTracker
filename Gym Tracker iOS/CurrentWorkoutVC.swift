//
//  CurrentWorkoutViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 08/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class CurrentWorkoutViewController: UIViewController {
	
	@IBOutlet private var cancelBtn: UIBarButtonItem!
	@IBOutlet private var endNowBtn: UIBarButtonItem!
	
	@IBOutlet private weak var manageFromWatchLbl: UILabel!
	@IBOutlet private weak var noWorkoutLabel: UIView!
	@IBOutlet private weak var workoutInfo: UIStackView!

	@IBOutlet private weak var workoutTitleLbl: UILabel!
	@IBOutlet private weak var bpmLbl: UILabel!
	@IBOutlet private weak var timerLbl: UILabel!
	
	@IBOutlet private weak var currentExercizeInfo: UIStackView!
	@IBOutlet private weak var exercizeNameLbl: UILabel!
	@IBOutlet private weak var currentSetInfo: UIView!
	@IBOutlet private weak var currentSetInfoLbl: UILabel!
	@IBOutlet private weak var otherSetsLbl: UILabel!
	@IBOutlet private weak var setDoneBtn: UIButton!
	
	@IBOutlet private weak var restInfo: UIStackView!
	@IBOutlet private weak var restTimerLbl: UILabel!
	@IBOutlet private weak var restDoneBtn: UIButton!
	
	@IBOutlet private weak var workoutDoneInfo: UIStackView!
	@IBOutlet private weak var workoutDoneLbl: UILabel!
	@IBOutlet private weak var workoutDoneBtn: UIButton!
	
	@IBOutlet private weak var nextUpInfo: UIView!
	@IBOutlet private weak var nextUpLbl: UILabel!
	
	private var workoutController: ExecuteWorkoutController? {
		return appDelegate.workoutController
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		appDelegate.currentWorkout = self

		for b in [setDoneBtn!, restDoneBtn!] {
			b.clipsToBounds = true
			b.layer.cornerRadius = 5
		}
		
		for l in [bpmLbl!, timerLbl!, restTimerLbl!] {
			l.font = l.font?.makeMonospacedDigit()
		}

		// This method is always called during app launch by the app delegate and as soon as the view is loaded it also updates it as appropriate
    }
	
	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func setWorkoutTitle(_ text: String) {
		workoutTitleLbl.text = text
	}
	
	func setBPM(_ text: String) {
		bpmLbl.text = text
	}
	
	private var timerDate: Date!
	private var timerUpdater: Timer? {
		didSet {
			DispatchQueue.main.async {
				oldValue?.invalidate()
			}
		}
	}
	
	func startTimer(at date: Date) {
		timerDate = date
		
		let update = {
			self.timerLbl.text = Date().timeIntervalSince(self.timerDate).getDuration()
		}
		DispatchQueue.main.async {
			self.timerUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
				update()
			}
			RunLoop.main.add(self.timerUpdater!, forMode: .commonModes)
		}
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
	private var restTimerUpdater: Timer? {
		didSet {
			DispatchQueue.main.async {
				oldValue?.invalidate()
			}
		}
	}
	
	func startRestTimer(to date: Date) {
		restTimerDate = date
		
		let update = {
			let time = max(self.restTimerDate.timeIntervalSince(Date()), 0)
			self.restTimerLbl.text = time.getDuration(hideHours: true)
			
			if time == 0 {
				self.stopRestTimer()
			}
		}
		DispatchQueue.main.async {
			self.restTimerUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
				update()
			}
			RunLoop.main.add(self.restTimerUpdater!, forMode: .commonModes)
		}
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
	
	func disableGlobalActions() {
		cancelBtn.isEnabled = false
		endNowBtn.isEnabled = false
	}
	
	func setNextUpTextHidden(_ hidden: Bool) {
		nextUpInfo.isHidden = hidden
	}
	
	func setNextUpText(_ text: String) {
		nextUpLbl.text = text
	}
	
	private var updateWeightData: UpdateWeightData?
	var skipAskUpdate = false
	
	func askUpdateWeight(with data: UpdateWeightData) {
		if !skipAskUpdate {
			updateWeightData = data
			self.performSegue(withIdentifier: "updateWeight", sender: self)
		}
		
		skipAskUpdate = false
	}
	
	@IBAction func endRest() {
		workoutController?.endRest()
	}
	
	@IBAction func endSet() {
		workoutController?.endSet()
	}
	
	@IBAction func endWorkout() {
		let alert = UIAlertController(title: NSLocalizedString("WORKOUT_END", comment: "End"), message: NSLocalizedString("WORKOUT_END_TXT", comment: "End?"), preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("YES", comment: "Yes"), style: .default) { _ in
			self.workoutController?.endWorkout()
			})
		alert.addAction(UIAlertAction(title: NSLocalizedString("NO", comment: "No"), style: UIAlertActionStyle.cancel, handler: nil))
		
		self.present(alert, animated: true)
	}
	
	@IBAction func cancelWorkout() {
		let alert = UIAlertController(title: NSLocalizedString("WORKOUT_CANCEL", comment: "Cancel"), message: NSLocalizedString("WORKOUT_CANCEL_TXT", comment: "Cancel??"), preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString("YES", comment: "Yes"), style: .destructive) { _ in
			self.workoutController?.cancelWorkout()
		})
		alert.addAction(UIAlertAction(title: NSLocalizedString("NO", comment: "No"), style: UIAlertActionStyle.cancel, handler: nil))
		
		self.present(alert, animated: true)
	}
	
	func workoutHasStarted() {
		skipAskUpdate = false
		let isWatch = workoutController?.isMirroring ?? false
		
		cancelBtn.isEnabled = true
		endNowBtn.isEnabled = true
		navigationItem.leftBarButtonItem = isWatch ? nil : cancelBtn
		navigationItem.rightBarButtonItem = isWatch ? nil : endNowBtn
		
		manageFromWatchLbl.isHidden = !isWatch
		noWorkoutLabel.isHidden = true
		workoutInfo.isHidden = false
	}
	
	@IBAction func workoutDoneButton() {
		appDelegate.exitWorkoutTracking()
	}
	
	func exitWorkoutTracking() {
		navigationItem.leftBarButtonItem = nil
		navigationItem.rightBarButtonItem = nil
		
		noWorkoutLabel.isHidden = false
		workoutInfo.isHidden = true
		appDelegate.refreshData()
	}
	
	func exitWorkoutTrackingIfAppropriate() {
		if workoutController?.isCompleted ?? false {
			appDelegate.exitWorkoutTracking()
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case "updateWeight":
			let dest = segue.destination as! UpdateWeightViewController
			dest.weightData = updateWeightData
			updateWeightData = nil
			
			PopoverController.preparePresentation(for: dest)
			dest.popoverPresentationController?.backgroundColor = dest.backgroundColor
			dest.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
			dest.popoverPresentationController?.sourceView = self.view
			dest.popoverPresentationController?.canOverlapSourceViewRect = true
		default:
			break
		}
	}
	
}
