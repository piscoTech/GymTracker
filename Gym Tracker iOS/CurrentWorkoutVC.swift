//
//  CurrentWorkoutViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 08/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import GymTrackerCore

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
	
	@IBOutlet private weak var tipView: UIView!
	
	private var workoutController: ExecuteWorkoutController? {
		return appDelegate.workoutController
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		appDelegate.currentWorkout = self

		for b in [setDoneBtn, restDoneBtn] {
			b?.clipsToBounds = true
			b?.layer.cornerRadius = 5
		}
		
		for l in [bpmLbl, timerLbl, restTimerLbl] {
			l?.font = l?.font?.makeMonospacedDigit()
		}

		// This method is always called during app launch by the app delegate and as soon as the view is loaded it also updates it as appropriate
		
		if #available(iOS 13, *) {} else {
			self.navigationController?.navigationBar.barStyle = .black
			self.view.backgroundColor = .black
		}
    }
	
	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func setWorkoutTitle(_ text: String) {
		workoutTitleLbl.text = text
	}
	
	func askForChoices(_ choices: [GTChoice]) {
		DispatchQueue.main.async {
			self.performSegue(withIdentifier: "askChoices", sender: choices)
		}
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
			self.timerLbl.text = Date().timeIntervalSince(self.timerDate).getRawDuration()
		}
		DispatchQueue.main.async {
			self.timerUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
				update()
			}
			RunLoop.main.add(self.timerUpdater!, forMode: .common)
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
		currentSetInfoLbl.isHidden = hidden
	}
	
	func setCurrentSetText(_ text: NSAttributedString) {
		if #available(iOS 13, *) {
			// In iOS 12 and before there's a bug where the appearance color overrides the color of the attributed string
		} else {
			currentSetInfoLbl.textColor = UIColor(named: "Text Color")
		}
		currentSetInfoLbl.attributedText = text
	}
	
	func setOtherSetsViewHidden(_ hidden: Bool) {
		otherSetsLbl.isHidden = hidden
	}
	
	func setOtherSetsText(_ text: NSAttributedString) {
		if #available(iOS 13, *) {
			// In iOS 12 and before there's a bug where the appearance color overrides the color of the attributed string
		} else {
			otherSetsLbl.textColor = UIColor(named: "Text Color")
		}
		otherSetsLbl.attributedText = text
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
			self.restTimerLbl.text = time.getRawDuration(hideHours: true)
			
			if time == 0 {
				self.stopRestTimer()
			}
		}
		DispatchQueue.main.async {
			self.restTimerUpdater = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
				update()
			}
			RunLoop.main.add(self.restTimerUpdater!, forMode: .common)
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
		DispatchQueue.main.async {
			self.cancelBtn.isEnabled = false
			self.endNowBtn.isEnabled = false
		}
	}
	
	func setNextUpTextHidden(_ hidden: Bool) {
		nextUpInfo.isHidden = hidden
	}
	
	func setNextUpText(_ text: NSAttributedString) {
		if #available(iOS 13, *) {
			// In iOS 12 and before there's a bug where the appearance color overrides the color of the attributed string
		} else {
			nextUpLbl.textColor = UIColor(named: "Text Color")
		}
		nextUpLbl.attributedText = text
	}
	
	var skipAskUpdate = false
	
	func askUpdateSecondaryInfo(with data: UpdateSecondaryInfoData) {
		if !skipAskUpdate {
			self.performSegue(withIdentifier: "updateWeight", sender: data)
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
		let alert = UIAlertController(title: GTLocalizedString("WORKOUT_END", comment: "End"), message: GTLocalizedString("WORKOUT_END_TXT", comment: "End?"), preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: GTLocalizedString("YES", comment: "Yes"), style: .default) { _ in
			self.workoutController?.endWorkout()
			})
		alert.addAction(UIAlertAction(title: GTLocalizedString("NO", comment: "No"), style: .cancel, handler: nil))
		
		self.present(alert, animated: true)
	}
	
	@IBAction func cancelWorkout() {
		let alert = UIAlertController(title: GTLocalizedString("WORKOUT_CANCEL", comment: "Cancel"), message: GTLocalizedString("WORKOUT_CANCEL_TXT", comment: "Cancel??"), preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: GTLocalizedString("YES", comment: "Yes"), style: .destructive) { _ in
			self.workoutController?.cancelWorkout()
		})
		alert.addAction(UIAlertAction(title: GTLocalizedString("NO", comment: "No"), style: .cancel, handler: nil))
		
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
		tipView.isHidden = isWatch
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
		
		let dest = segue.destination
		PopoverController.preparePresentation(for: dest)
		dest.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
		dest.popoverPresentationController?.sourceView = self.view
		dest.popoverPresentationController?.canOverlapSourceViewRect = true
		
		switch segueID {
		case "updateWeight":
			guard let updateSec = dest as? UpdateSecondaryInfoViewController, let data = sender as? UpdateSecondaryInfoData else {
				break
			}
			
			updateSec.secondaryInfoData = data
			updateSec.popoverPresentationController?.backgroundColor = updateSec.backgroundColor
		case "askChoices":
			guard let ask = (dest as? UINavigationController)?.viewControllers.first as? AskChoiceTableViewController, let choices = sender as? [GTChoice] else {
				break
			}
			
			ask.choices = choices
			ask.n = 0
		default:
			break
		}
	}
	
}
