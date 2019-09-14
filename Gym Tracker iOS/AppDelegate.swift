//
//  AppDelegate.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/11/2016.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import UserNotifications
import AVFoundation
import MBLibrary
import StoreKit
import GymTrackerCore

@available(iOS 13.0, *)
class TraitOverriderWindow: UIWindow {
	
	var colorScheme: UIUserInterfaceStyle?
	
	override var traitCollection: UITraitCollection {
		if let scheme = colorScheme {
			let override = UITraitCollection(userInterfaceStyle: scheme)
			return UITraitCollection(traitsFrom: [super.traitCollection, override])
		}
		return super.traitCollection
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	weak var tabController: TabBarController!
	weak var workoutList: WorkoutListTableViewController!
	weak var currentWorkout: CurrentWorkoutViewController!
	weak var completedWorkouts: CompletedWorkoutsTableViewController!
	weak var settings: SettingsViewController!
	
	var canEdit: Bool {
		return workoutList.canEdit
	}
	
	fileprivate(set) var workoutController: ExecuteWorkoutController?
	fileprivate var workoutAudio: AVAudioPlayer?
	fileprivate var workoutRestTimer: Timer? {
		didSet {
			DispatchQueue.main.async {
				oldValue?.invalidate()
			}
		}
	}
	
	private var tryImport: URL?
	private var launched = false

	private(set) var dataManager: DataManager!
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		dataManager = DataManager(for: .application)

		tabController = self.window?.rootViewController as? TabBarController
		if #available(iOS 13.0, *) {
			let window = TraitOverriderWindow(frame: UIScreen.main.bounds)
			window.colorScheme = .dark
			window.rootViewController = tabController

			self.window = window
			window.makeKeyAndVisible()
		} else {
			tabController.tabBar.barStyle = .black
		}
		tabController.delegate = tabController
		tabController.loadNeededControllers()
		
		try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
		
		if dataManager.preferences.runningWorkout != nil, let src = dataManager.preferences.runningWorkoutSource {
			if src == .watch {
				self.updateMirroredWorkout(withCurrentExercise: dataManager.preferences.currentExercise,
										   part: dataManager.preferences.currentPart,
										   andTime: dataManager.preferences.currentRestEnd != nil ? Date() : nil)
			} else {
				self.startLocalWorkout()
			}
		} else {
			// This also request a review
			self.exitWorkoutTracking()
		}
		
		dataManager.delegate = self
		authorizeHealthAccess()
		
		if !dataManager.preferences.firstLaunchDone {
			dataManager.preferences.firstLaunchDone = true
			
			// Just set the default choice to use backups, checks if this is possible will be done by the appropriate manager
			dataManager.preferences.useBackups = true
		}
		
		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
		do {
			let endRestNow = UNNotificationAction(identifier: GTNotification.Action.endRest.rawValue, title: GTLocalizedString("NOTIF_END_REST_NOW", comment: "End now"))
			let endRest = UNNotificationAction(identifier: GTNotification.Action.endRest.rawValue, title: GTLocalizedString("NOTIF_END_REST", comment: "End"))
			
			let endSet = UNNotificationAction(identifier: GTNotification.Action.endSet.rawValue, title: GTLocalizedString("NOTIF_END_SET", comment: "Done"))
			let endWorkout = UNNotificationAction(identifier: GTNotification.Action.endSet.rawValue, title: GTLocalizedString("NOTIF_END_WORKOUT", comment: "Done Workout"), options: .foreground)
			
			let endSetWeight = UNNotificationAction(identifier: GTNotification.Action.endSetWeight.rawValue, title: GTLocalizedString("NOTIF_END_SET_WEIGHT", comment: "Done, weight"), options: GTNotification.Action.genericSetWeightUpdateOptions)
			let endWorkoutWeight = UNNotificationAction(identifier: GTNotification.Action.endSetWeight.rawValue, title: GTLocalizedString("NOTIF_END_SET_WEIGHT", comment: "Done, weight"), options: .foreground)
			
			let restStartNowCategory = UNNotificationCategory(identifier: GTNotification.Category.restStart.rawValue, actions: [endRestNow], intentIdentifiers: [], options: [])
			let endRestCategory = UNNotificationCategory(identifier: GTNotification.Category.restEnd.rawValue, actions: [endRest], intentIdentifiers: [], options: [])
			let endSetCategory = UNNotificationCategory(identifier: GTNotification.Category.currentSetInfo.rawValue, actions: [endSet, endSetWeight], intentIdentifiers: [], options: [])
			let endWorkoutCategory = UNNotificationCategory(identifier: GTNotification.Category.lastSetInfo.rawValue, actions: [endWorkout, endWorkoutWeight], intentIdentifiers: [], options: [])
			
			center.setNotificationCategories([restStartNowCategory, endRestCategory, endSetCategory, endWorkoutCategory])
		}
		center.delegate = self
		
		UITabBar.appearance().tintColor = customTint
		if #available(iOS 13, *) {
			// These can be done in storyboard
			tabController.tabBar.items![0].image = UIImage(systemName: "list.bullet")
			tabController.tabBar.items![3].image = UIImage(systemName: "gear")
			// Override also the selected images just to be sure
			tabController.tabBar.items![0].selectedImage = UIImage(systemName: "list.bullet")
			tabController.tabBar.items![3].selectedImage = UIImage(systemName: "gear")
		} else {
			let table = UITableView.appearance()
			table.backgroundColor = .black
			table.separatorColor = #colorLiteral(red: 0.2243117094, green: 0.2243117094, blue: 0.2243117094, alpha: 1)
			
			let cell = UITableViewCell.appearance()
			cell.backgroundColor = #colorLiteral(red: 0.0393620953, green: 0.0393620953, blue: 0.0393620953, alpha: 1)
			cell.selectionStyle = .gray
			cell.tintColor = customTint
			
			UILabel.appearance().textColor = UIColor(named: "Text Color")
			UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
			
			let textField = UITextField.appearance()
			textField.textColor = UIColor(named: "Text Color")
			textField.keyboardAppearance = .dark
		}
		
		launched = true
		
		dataManager.importExportManager.doBackup()
		importFile()
		
		return true
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		if url.isFileURL {
			tryImport = url
			importFile()
			
			return true
		}
		
		return false
	}
	
	private var reviewRequested = false
	
	private func requestReview() {
		guard !reviewRequested else {
			return
		}
		
		if #available(iOS 10.3, *) {
			if dataManager.preferences.reviewRequestCounter >= dataManager.preferences.reviewRequestThreshold {
				#if !DEBUG
				SKStoreReviewController.requestReview()
				#endif
				
				reviewRequested = true
				Timer.scheduledTimer(withTimeInterval: 60, repeats: false) { _ in
					self.reviewRequested = false
				}
			}
		}
	}
	
	private func importFile() {
		guard launched else {
			return
		}
		
		DispatchQueue.main.async {
			if let url = self.tryImport {
				if ".\(url.pathExtension)" == self.dataManager.importExportManager.fileExtension {
					if self.canEdit {
						self.workoutList.exitDetailAndCreation {
							let loading = UIAlertController.getModalLoading()
							self.tabController.present(loading, animated: true) {
								self.dataManager.importExportManager.import(url, isRestoring: false, performCallback: { _, _, proceed in
									if let proceed = proceed {
										proceed()
									} else {
										loading.dismiss(animated: true) {
											let alert = UIAlertController(simpleAlert: GTLocalizedString("IMPORT_FAIL", comment: "Fail"), message: GTLocalizedString("WRKT_INVALID", comment: "Invalid file"))
											self.tabController.present(alert, animated: true)
										}
									}
								}) { wrkt in
									let success: Bool
									let msg: String?
									if let wrkt = wrkt {
										success = true
										appDelegate.workoutList.refreshData()
										msg = String(format: GTLocalizedString("%lld_WORKOUTS", comment: "n workouts"),
													 wrkt.count)
									} else {
										success = false
										msg = nil
									}
									
									loading.dismiss(animated: true) {
										self.tabController.present(UIAlertController(simpleAlert: GTLocalizedString(success ? "IMPORT_SUCCESS" : "IMPORT_FAIL", comment: "err/ok"), message: msg), animated: true)
									}
								}
							}
						}
					} else {
						let alert = UIAlertController(simpleAlert: GTLocalizedString("IMPORT_FAIL", comment: "Fail"), message: GTLocalizedString("IMPORT_STOP_WRKT", comment: "stop & retry"))
						self.tabController.present(alert, animated: true)
					}
				} else {
					let alert = UIAlertController(simpleAlert: GTLocalizedString("IMPORT_FAIL", comment: "Fail"), message: GTLocalizedString("WRKT_INVALID", comment: "Invalid file"))
					self.tabController.present(alert, animated: true)
				}
			}
			
			self.tryImport = nil
		}
	}
	
	func authorizeHealthAccess() {
		let req = {
			healthStore.requestAuthorization(toShare: healthWriteData, read: healthReadData) { _, _ in }
		}
		
		if #available(iOS 12.0, *) {
			healthStore.getRequestStatusForAuthorization(toShare: healthWriteData, read: healthReadData) { status, _ in
				if status != .unnecessary {
					req()
				}
			}
		} else {
			req()
		}
	}
	
	func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
		healthStore.handleAuthorizationForExtension { _, _ in }
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
		
		if let ctrl = self.workoutController {
			self.notifyExerciseChange(isRest: ctrl.isRestMode)
		}
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		
		if let ctrl = self.workoutController {
			self.notifyExerciseChange(isRest: ctrl.isRestMode)
		}
	}
	
}

// MARK: - Execute Workout Controller Delegate

extension AppDelegate: ExecuteWorkoutControllerDelegate {
	
	func startWorkout(_ workout: GTWorkout) {
		guard workoutController == nil else {
			return
		}
		
		tabController.selectedIndex = 1
		
		if dataManager.shouldStartWorkoutOnWatch {
			healthStore.startWatchApp(with: HKWorkoutConfiguration()) { success, _ in
				let displayError = {
					DispatchQueue.main.async {
						let alert = UIAlertController(simpleAlert: GTLocalizedString("WORKOUT_START_ERR", comment: "Err"),
													  message: GTLocalizedString("WORKOUT_START_ERR_WATCH", comment: "Err watch")) {
														self.startLocalWorkout(workout)
						}
						self.currentWorkout.present(alert, animated: true)
					}
				}
				
				if !success {
					displayError()
				} else {
					DispatchQueue.background.asyncAfter(delay: 1) {
						self.dataManager.requestStarting(workout) { success in
							if !success {
								displayError()
							}
						}
					}
				}
			}
		} else {
			startLocalWorkout(workout)
		}
	}
	
	fileprivate func startLocalWorkout(_ workout: GTWorkout? = nil) {
		guard workoutController == nil, workout == nil || dataManager.preferences.runningWorkout == nil else {
			return
		}
		
		let data: ExecuteWorkoutData
		if let w = workout {
			data = ExecuteWorkoutData(workout: w, resume: false)
		} else {
			guard let wID = dataManager.preferences.runningWorkout,
				let w = wID.getObject(fromDataManager: dataManager) as? GTWorkout,
				let src = dataManager.preferences.runningWorkoutSource, src == .phone else {
				return
			}
			
			data = ExecuteWorkoutData(workout: w, resume: true)
		}
		
		workoutController = ExecuteWorkoutController(data: data, viewController: self, source: .phone)
	}
	
	func askForChoices(_ choices: [GTChoice]) {
		currentWorkout.askForChoices(choices)
	}
	
	func reportChoices(_ choices: [GTChoice: Int32]) {
		workoutController?.reportChoices(choices)
	}
	
	func cancelStartup() {
		workoutController?.cancelStartup()
	}
	
	func setWorkoutTitle(_ text: String) {
		currentWorkout.setWorkoutTitle(text)
	}
	
	func setBPM(_ text: String) {
		currentWorkout.setBPM(text)
	}
	
	func startTimer(at date: Date) {
		currentWorkout.startTimer(at: date)
	}
	
	func stopTimer() {
		currentWorkout.stopTimer()
	}
	
	func setCurrentExerciseViewHidden(_ hidden: Bool) {
		currentWorkout.setCurrentExerciseViewHidden(hidden)
	}
	
	func setExerciseName(_ name: String) {
		currentWorkout.setExerciseName(name)
	}
	
	func setCurrentSetViewHidden(_ hidden: Bool) {
		currentWorkout.setCurrentSetViewHidden(hidden)
	}
	
	func setCurrentSetText(_ text: NSAttributedString) {
		currentWorkout.setCurrentSetText(text)
	}
	
	func setOtherSetsViewHidden(_ hidden: Bool) {
		currentWorkout.setOtherSetsViewHidden(hidden)
	}
	
	func setOtherSetsText(_ text: NSAttributedString) {
		currentWorkout.setOtherSetsText(text)
	}
	
	func setSetDoneButtonHidden(_ hidden: Bool) {
		currentWorkout.setSetDoneButtonHidden(hidden)
	}
	
	func startRestTimer(to date: Date) {
		currentWorkout.startRestTimer(to: date)
	}
	
	func stopRestTimer() {
		currentWorkout.stopRestTimer()
	}
	
	func setRestViewHidden(_ hidden: Bool) {
		currentWorkout.setRestViewHidden(hidden)
	}
	
	func setRestEndButtonHidden(_ hidden: Bool) {
		currentWorkout.setRestEndButtonHidden(hidden)
	}
	
	func setWorkoutDoneViewHidden(_ hidden: Bool) {
		currentWorkout.setWorkoutDoneViewHidden(hidden)
	}
	
	func setWorkoutDoneText(_ text: String) {
		currentWorkout.setWorkoutDoneText(text)
	}
	
	func setWorkoutDoneButtonEnabled(_ enabled: Bool) {
		currentWorkout.setWorkoutDoneButtonEnabled(enabled)
	}
	
	func disableGlobalActions() {
		currentWorkout.disableGlobalActions()
	}
	
	func setNextUpTextHidden(_ hidden: Bool) {
		currentWorkout.setNextUpTextHidden(hidden)
	}
	
	func setNextUpText(_ text: NSAttributedString) {
		currentWorkout.setNextUpText(text)
	}
	
	func notifyEndRest() {
		try? AVAudioSession.sharedInstance().setActive(true)
		workoutAudio?.play()
		
		DispatchQueue.main.async {
			self.workoutRestTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
				self.workoutAudio?.play()
			}
			RunLoop.main.add(self.workoutRestTimer!, forMode: .common)
		}
	}
	
	func endNotifyEndRest() {
		workoutAudio?.stop()
		workoutAudio?.currentTime = 0
		try? AVAudioSession.sharedInstance().setActive(false)
		
		DispatchQueue.main.async {
			self.workoutRestTimer = nil
		}
	}
	
	func notifyExerciseChange(isRest: Bool) {
		guard !(workoutController?.isMirroring ?? true) else {
			return
		}
		
		var notifications = [UNNotificationRequest]()
		let presentNow = UNTimeIntervalNotificationTrigger(timeInterval: GTNotification.immediateNotificationDelay, repeats: false)
		if isRest {
			if let (duration, end) = workoutController?.currentRestTime {
				let endTime = end.timeIntervalSinceNow
				if endTime > GTNotification.immediateNotificationDelay {
					let restDurationContent = UNMutableNotificationContent()
					restDurationContent.title = GTLocalizedString("REST_TIME_TITLE", comment: "Rest time")
					restDurationContent.body = String(format: GTLocalizedString("REST_TIME_BODY", comment: "Rest for"), duration.getFormattedDuration())
					restDurationContent.sound = nil
					restDurationContent.categoryIdentifier = GTNotification.Category.restStart.rawValue
					
					notifications.append(UNNotificationRequest(identifier: GTNotification.ID.restStart.rawValue, content: restDurationContent, trigger: presentNow))
				}
				
				let restEndTrigger = UNTimeIntervalNotificationTrigger(timeInterval: max(endTime, GTNotification.immediateNotificationDelay), repeats: false)
				let restEndContent = UNMutableNotificationContent()
				restEndContent.title = GTLocalizedString("REST_OVER_TITLE", comment: "Rest over")
				restEndContent.body = GTLocalizedString("REST_\((workoutController?.currentIsRestPeriod ?? true) ? "EXERCISE" : "SET")_OVER_BODY", comment: "Next Exercise")
				restEndContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "rest_end_notification.caf"))
				restEndContent.categoryIdentifier = GTNotification.Category.restEnd.rawValue
				
				notifications.append(UNNotificationRequest(identifier: GTNotification.ID.restEnd.rawValue, content: restEndContent, trigger: restEndTrigger))
			}
		} else {
			if let (ex, set, other) = workoutController?.currentSetInfo, let (weight, change) = workoutController?.currentSetRawInfo {
				let nextSetContent = UNMutableNotificationContent()
				nextSetContent.title = ex
				nextSetContent.body = set + (other != nil ? "\n\(other!)" : "")
				nextSetContent.sound = nil
				nextSetContent.userInfo = [
					GTNotification.UserInfo.setWeight.rawValue: 	  weight,
					GTNotification.UserInfo.setWeightChange.rawValue: change
				]
				nextSetContent.categoryIdentifier = ((workoutController?.isLastPart ?? false) ? GTNotification.Category.lastSetInfo : .currentSetInfo).rawValue
				
				notifications.append(UNNotificationRequest(identifier: GTNotification.ID.currentSetInfo.rawValue, content: nextSetContent, trigger: presentNow))
			}
		}
		
		let center = UNUserNotificationCenter.current()
		for n in notifications {
			center.add(n)
		}
	}

	func askUpdateSecondaryInfo(with data: UpdateSecondaryInfoData) {
		currentWorkout.askUpdateSecondaryInfo(with: data)
	}
	
	func workoutHasStarted() {
		currentWorkout.workoutHasStarted()
		
		let center = UNUserNotificationCenter.current()
		center.removeAllDeliveredNotifications()
		center.removeAllPendingNotificationRequests()
		
		if let endRestSound = Bundle.main.url(forResource: "rest_end", withExtension: "caf") {
			workoutAudio = try? AVAudioPlayer(contentsOf: endRestSound)
			workoutAudio?.prepareToPlay()
		}
	}
	
	func exitWorkoutTracking() {
		workoutController = nil
		currentWorkout.exitWorkoutTracking()
		
		let center = UNUserNotificationCenter.current()
		center.removeAllDeliveredNotifications()
		center.removeAllPendingNotificationRequests()
		
		workoutAudio = nil
		
		// Review
		dataManager.preferences.reviewRequestCounter += 1
		requestReview()
	}
	
	func globallyUpdateSecondaryInfoChange() {
		workoutList?.globallyUpdateSecondaryInfoChange()
	}
	
}

// MARK: - Handle Notification Actions

extension AppDelegate: UNUserNotificationCenterDelegate {
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([])
		
		if workoutController != nil {
			tabController.selectedIndex = 1
		}
		
		center.removeAllDeliveredNotifications()
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let act = response.actionIdentifier
		
		completionHandler()
		center.removeAllDeliveredNotifications()
		center.removeAllPendingNotificationRequests()
		
		switch act {
		case UNNotificationDefaultActionIdentifier:
			if workoutController != nil {
				tabController.selectedIndex = 1
			}
		case GTNotification.Action.endRest.rawValue:
			workoutController?.endRest()
		case GTNotification.Action.endSet.rawValue:
			currentWorkout.skipAskUpdate = true
			workoutController?.endSet()
		case GTNotification.Action.endSetWeightInApp.rawValue, GTNotification.Action.endSetWeight.rawValue:
			let isUpdate = dataManager.preferences.secondaryInfoUpdatedInNotification
			let endTime = dataManager.preferences.setEndedInNotificationTime
			let weightChange = isUpdate ? dataManager.preferences.secondaryInfoChangeFromNotification : nil
			
			workoutController?.endSet(endTime: endTime, secondaryInfoChange: weightChange)
		default:
			break
		}
		
		dataManager.preferences.clearNotificationData()
	}
	
}

// MARK: - Workout Status Change from Apple Watch

extension AppDelegate: DataManagerDelegate {
	
	func refreshData() {
		DispatchQueue.main.async {
			self.workoutList.refreshData()
		}
	}
	
	func enableEdit() {
		DispatchQueue.main.async {
			self.workoutList.enableEdit(true)
		}
	}
	
	func cancelAndDisableEdit() {
		DispatchQueue.main.async {
			self.workoutList.enableEdit(false)
		}
	}
	
	func updateMirroredWorkout(withCurrentExercise exercise: Int, part: Int, andTime date: Date?) {
		guard dataManager.preferences.runningWorkout != nil else {
			return
		}
		
		DispatchQueue.main.async {
			if self.workoutController?.isCompleted ?? true {
				self.workoutController = ExecuteWorkoutController(mirrorWorkoutForViewController: self, dataManager: self.dataManager)
			}
			
			guard let controller = self.workoutController, controller.isMirroring else {
				return
			}
			
			
			controller.updateMirroredWorkout(withCurrentExercise: exercise, part: part, andTime: date)
		}
	}
	
	func mirroredWorkoutHasEnded() {
		guard let controller = workoutController, controller.isMirroring else {
			return
		}
		
		DispatchQueue.main.async {
			controller.mirroredWorkoutHasEnded()
		}
	}

}
