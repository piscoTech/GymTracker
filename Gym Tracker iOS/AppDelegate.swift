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
	
	fileprivate let restTimeNotification = "restTimeNotificationID"
	fileprivate let restEndNotification = "restEndNotificationID"
	fileprivate let nextSetNotification = "nextSetNotificationID"
	
	fileprivate let endRestNotificationAction = "endRestNotificationActionID"
	fileprivate let endSetNotificationAction = "endSetNotificationActionID"
	fileprivate let endSetWeightNotificationAction = "endSetWeightNotificationActionID"
	
	fileprivate let endRestNowNotificationCategory = "endRestNowNotificationCategoryID"
	fileprivate let endRestNotificationCategory = "endRestNotificationCategoryID"
	fileprivate let endSetNotificationCategory = "endSetNotificationCategoryID"
	fileprivate let endWorkoutNotificationCategory = "endWorkoutNotificationCategoryID"
	
	fileprivate let notifyNowDelay: TimeInterval = 1
	
	private var tryImport: URL?
	private var launched = false

	private(set) var dataManager: DataManager!
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		dataManager = DataManager(for: .application)
		
		tabController = self.window!.rootViewController as! TabBarController
		tabController.delegate = tabController
		tabController.loadNeededControllers()
		
		if dataManager.preferences.runningWorkout != nil, let src = dataManager.preferences.runningWorkoutSource {
			if src == .watch {
				self.updateMirroredWorkout(withCurrentExercize: dataManager.preferences.currentExercize,
										   part: dataManager.preferences.currentPart,
										   andTime: dataManager.preferences.currentRestEnd != nil ? Date() : nil)
			} else {
				self.startLocalWorkout()
			}
		} else {
			self.exitWorkoutTracking()
		}
		
		dataManager.delegate = self
		
		if !dataManager.preferences.authorized || dataManager.preferences.authVersion < authRequired {
			authorizeHealthAccess()
		}
		
		if !dataManager.preferences.firstLaunchDone {
			dataManager.preferences.firstLaunchDone = true
			
			// Just set the default choice to use backups, checks if this is possible will be done by the appropriate manager
			dataManager.preferences.useBackups = true
		}
		
		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
		do {
			let endRestNow = UNNotificationAction(identifier: endRestNotificationAction, title: NSLocalizedString("NOTIF_END_REST_NOW", comment: "End now"))
			let endRest = UNNotificationAction(identifier: endRestNotificationAction, title: NSLocalizedString("NOTIF_END_REST", comment: "End"))
			
			let endSet = UNNotificationAction(identifier: endSetNotificationAction, title: NSLocalizedString("NOTIF_END_SET", comment: "Done"))
			let endWorkout = UNNotificationAction(identifier: endSetNotificationAction, title: NSLocalizedString("NOTIF_END_WORKOUT", comment: "Done Workout"), options: .foreground)
			
			let endSetWeight = UNNotificationAction(identifier: endSetWeightNotificationAction, title: NSLocalizedString("NOTIF_END_SET_WEIGHT", comment: "Done, weight"), options: [.foreground])
			
			let endRestNowCategory = UNNotificationCategory(identifier: endRestNowNotificationCategory, actions: [endRestNow], intentIdentifiers: [], options: [])
			let endRestCategory = UNNotificationCategory(identifier: endRestNotificationCategory, actions: [endRest], intentIdentifiers: [], options: [])
			let endSetCategory = UNNotificationCategory(identifier: endSetNotificationCategory, actions: [endSet, endSetWeight], intentIdentifiers: [], options: [])
			let endWorkoutCategory = UNNotificationCategory(identifier: endWorkoutNotificationCategory, actions: [endWorkout, endSetWeight], intentIdentifiers: [], options: [])
			
			center.setNotificationCategories([endRestNowCategory, endRestCategory, endSetCategory, endWorkoutCategory])
		}
		center.delegate = self
		
		do {
			UITabBar.appearance().tintColor = customTint
			DestructiveButton.appearance().tintColor = redTint

			let table = UITableView.appearance()
			table.backgroundColor = .black
			table.separatorColor = #colorLiteral(red: 0.2243117094, green: 0.2243117094, blue: 0.2243117094, alpha: 1)
			
			let cell = UITableViewCell.appearance()
			cell.backgroundColor = #colorLiteral(red: 0.0393620953, green: 0.0393620953, blue: 0.0393620953, alpha: 1)
			cell.selectionStyle = .gray
			
			let textColor = #colorLiteral(red: 0.9198423028, green: 0.9198423028, blue: 0.9198423028, alpha: 1)
			UILabel.appearance().textColor = textColor
			UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
			HeartLabel.appearance().textColor = redTint
			
			let textField = UITextField.appearance()
			textField.textColor = textColor
			textField.keyboardAppearance = .dark
		}
		
		tabController.tabBar.items![1].selectedImage = #imageLiteral(resourceName: "Workout Active")
		tabController.tabBar.items![2].selectedImage = #imageLiteral(resourceName: "Completed List Active")
		tabController.tabBar.items![3].selectedImage = #imageLiteral(resourceName: "Settings Active")
		
		launched = true
		
		dataManager.importExportManager.doBackup()
		importFile()
		
		return true
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		if url.isFileURL {
			tryImport = url
			importFile()
			
			return true
		}
		
		return false
	}
	
	private func importFile() {
		guard launched else {
			return
		}
		
		DispatchQueue.main.async {
			if let url = self.tryImport {
				// FIXME: Call here workoutList.exitDetailAndCreation(), fixes #2
				if ".\(url.pathExtension)" == self.dataManager.importExportManager.fileExtension {
					if self.canEdit {
						let loading = UIAlertController.getModalLoading()
						self.tabController.present(loading, animated: true) {
							self.dataManager.importExportManager.import(url, isRestoring: false, performCallback: { _, _, proceed in
								if let proceed = proceed {
									proceed()
								} else {
									loading.dismiss(animated: true) {
										let alert = UIAlertController(simpleAlert: NSLocalizedString("IMPORT_FAIL", comment: "Fail"), message: NSLocalizedString("WRKT_INVALID", comment: "Invalid file"))
										self.tabController.present(alert, animated: true)
									}
								}
							}) { wrkt in
								let success = wrkt != nil
								if success {
									appDelegate.workoutList.refreshData()
								}
								
								loading.dismiss(animated: true) {
									self.tabController.present(UIAlertController(simpleAlert: NSLocalizedString(success ? "IMPORT_SUCCESS" : "IMPORT_FAIL", comment: "err/ok"), message: nil), animated: true)
								}
							}
						}
					} else {
						let alert = UIAlertController(simpleAlert: NSLocalizedString("IMPORT_FAIL", comment: "Fail"), message: NSLocalizedString("IMPORT_STOP_WRKT", comment: "stop & retry"))
						self.tabController.present(alert, animated: true)
					}
				} else {
					let alert = UIAlertController(simpleAlert: NSLocalizedString("IMPORT_FAIL", comment: "Fail"), message: NSLocalizedString("WRKT_INVALID", comment: "Invalid file"))
					self.tabController.present(alert, animated: true)
				}
			}
			
			self.tryImport = nil
		}
	}
	
	func authorizeHealthAccess() {
		healthStore.requestAuthorization(toShare: healthWriteData, read: healthReadData) { success, _ in
			if success {
				self.dataManager.preferences.authorized = true
				self.dataManager.preferences.authVersion = authRequired
			}
		}
	}
	
	func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
		healthStore.handleAuthorizationForExtension { success, _ in
			if success {
				self.dataManager.preferences.authorized = true
				self.dataManager.preferences.authVersion = authRequired
			}
		}
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
		
		if let ctrl = self.workoutController {
			self.notifyExercizeChange(isRest: ctrl.isRestMode)
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
			self.notifyExercizeChange(isRest: ctrl.isRestMode)
		}
	}
	
}

extension AppDelegate: ExecuteWorkoutControllerDelegate {
	
	func startWorkout(_ workout: OrganizedWorkout) {
		guard workoutController == nil else {
			return
		}
		
		tabController.selectedIndex = 1
		
		if dataManager.shouldStartWorkoutOnWatch {
			healthStore.startWatchApp(with: HKWorkoutConfiguration()) { success, _ in
				let displayError = {
					DispatchQueue.main.async {
						self.currentWorkout.present(UIAlertController(simpleAlert: NSLocalizedString("WORKOUT_START_ERR", comment: "Err"), message: NSLocalizedString("WORKOUT_START_ERR_WATCH", comment: "Err watch")), animated: true)
						// FIXME: Fix #6 by starting a local workout after alert is closed (also fix in DataManager)
					}
				}
				
				if !success {
					displayError()
				} else {
					if !self.dataManager.requestStarting(workout.raw) {
						displayError()
					}
				}
			}
		} else {
			startLocalWorkout(workout)
		}
	}
	
	fileprivate func startLocalWorkout(_ workout: OrganizedWorkout? = nil) {
		guard workoutController == nil, workout == nil || dataManager.preferences.runningWorkout == nil else {
			return
		}
		
		let data: ExecuteWorkoutData
		if let w = workout {
			data = ExecuteWorkoutData(workout: w, resume: false)
		} else {
			guard let wID = dataManager.preferences.runningWorkout,
				let w = wID.getObject(fromDataManager: dataManager) as? Workout,
				let src = dataManager.preferences.runningWorkoutSource, src == .phone else {
				return
			}
			
			data = ExecuteWorkoutData(workout: OrganizedWorkout(w), resume: true)
		}
		
		workoutController = ExecuteWorkoutController(data: data, viewController: self, source: .phone)
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
	
	func setCurrentExercizeViewHidden(_ hidden: Bool) {
		currentWorkout.setCurrentExercizeViewHidden(hidden)
	}
	
	func setExercizeName(_ name: String) {
		currentWorkout.setExercizeName(name)
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
		workoutAudio?.play()
		DispatchQueue.main.async {
			self.workoutRestTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
				self.workoutAudio?.play()
			}
			RunLoop.main.add(self.workoutRestTimer!, forMode: .commonModes)
		}
	}
	
	func endNotifyEndRest() {
		DispatchQueue.main.async {
			self.workoutRestTimer = nil
		}
	}
	
	func notifyExercizeChange(isRest: Bool) {
		guard !(workoutController?.isMirroring ?? true) else {
			return
		}
		
		var notifications = [UNNotificationRequest]()
		let presentNow = UNTimeIntervalNotificationTrigger(timeInterval: notifyNowDelay, repeats: false)
		if isRest {
			if let (duration, end) = workoutController?.currentRestTime {
				let endTime = end.timeIntervalSinceNow
				if endTime > notifyNowDelay {
					let restDurationContent = UNMutableNotificationContent()
					restDurationContent.title = NSLocalizedString("REST_TIME_TITLE", comment: "Rest time")
					restDurationContent.body = NSLocalizedString("REST_TIME_BODY", comment: "Rest for") + duration.getDuration(hideHours: true)
					restDurationContent.sound = nil
					restDurationContent.categoryIdentifier = endRestNowNotificationCategory
					
					notifications.append(UNNotificationRequest(identifier: restTimeNotification, content: restDurationContent, trigger: presentNow))
				}
				
				let restEndTrigger = UNTimeIntervalNotificationTrigger(timeInterval: max(endTime, notifyNowDelay), repeats: false)
				let restEndContent = UNMutableNotificationContent()
				restEndContent.title = NSLocalizedString("REST_OVER_TITLE", comment: "Rest over")
				restEndContent.body = NSLocalizedString("REST_\((workoutController?.currentIsRestPeriod ?? true) ? "EXERCIZE" : "SET")_OVER_BODY", comment: "Next Exercize")
				restEndContent.sound = UNNotificationSound(named: "rest_end_notification.caf")
				restEndContent.categoryIdentifier = endRestNotificationCategory
				
				notifications.append(UNNotificationRequest(identifier: restEndNotification, content: restEndContent, trigger: restEndTrigger))
			}
		} else {
			if let (ex, set, other) = workoutController?.currentSetInfo {
				let nextSetContent = UNMutableNotificationContent()
				nextSetContent.title = ex
				nextSetContent.body = set + NSLocalizedString("CUR_REPS_INFO", comment: "reps") + (other != nil ? "\n\(other!)" : "")
				nextSetContent.sound = nil
				nextSetContent.categoryIdentifier = (workoutController?.isLastPart ?? false) ? endWorkoutNotificationCategory : endSetNotificationCategory
				
				notifications.append(UNNotificationRequest(identifier: nextSetNotification, content: nextSetContent, trigger: presentNow))
			}
		}
		
		let center = UNUserNotificationCenter.current()
		for n in notifications {
			center.add(n) { _ in }
		}
	}

	func askUpdateWeight(with data: UpdateWeightData) {
		currentWorkout.askUpdateWeight(with: data)
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
	}
	
}

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
		case endRestNotificationAction:
			workoutController?.endRest()
		case endSetNotificationAction:
			currentWorkout.skipAskUpdate = true
			workoutController?.endSet()
		case endSetWeightNotificationAction:
			currentWorkout.skipAskUpdate = false
			workoutController?.endSet()
		default:
			break
		}
	}
	
}

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
	
	func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date?) {
		guard dataManager.preferences.runningWorkout != nil else {
			return
		}
		
		DispatchQueue.main.async {
			if self.workoutController?.isCompleted ?? true {
				self.workoutController = ExecuteWorkoutController(mirrorWorkoutForViewController: self)
			}
			
			guard let controller = self.workoutController, controller.isMirroring else {
				return
			}
			
			
			controller.updateMirroredWorkout(withCurrentExercize: exercize, part: part, andTime: date)
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
