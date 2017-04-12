//
//  AppDelegate.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/11/2016.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	weak var tabController: TabBarController!
	weak var workoutList: WorkoutListTableViewController!
	weak var currentWorkout: CurrentWorkoutViewController!
	weak var completedWorkouts: CompletedWorkoutsTableViewController!
	weak var settings: SettingsViewController!
	
	fileprivate(set) var workoutController: ExecuteWorkoutController?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		do {
			let view = UIView.appearance()
			view.tintColor = #colorLiteral(red: 0.7568627451, green: 0.9215686275, blue: 0.2, alpha: 1)
			DestructiveButton.appearance().tintColor = .red
			
			let table = UITableView.appearance()
			table.backgroundColor = .black
			table.separatorColor = #colorLiteral(red: 0.2243117094, green: 0.2243117094, blue: 0.2243117094, alpha: 1)
			
			let cell = UITableViewCell.appearance()
			cell.backgroundColor = #colorLiteral(red: 0.0393620953, green: 0.0393620953, blue: 0.0393620953, alpha: 1)
			cell.selectionStyle = .gray
			
			let textColor = #colorLiteral(red: 0.9198423028, green: 0.9198423028, blue: 0.9198423028, alpha: 1)
			UILabel.appearance().textColor = textColor
			UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
			HeartLabel.appearance().textColor = #colorLiteral(red: 1, green: 0.1882352941, blue: 0, alpha: 1)
			
			let textField = UITextField.appearance()
			textField.textColor = textColor
			textField.keyboardAppearance = .dark
			
			UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
		}
		
		tabController = self.window!.rootViewController as! TabBarController
		tabController.delegate = tabController
		tabController.tabBar.items![1].selectedImage = #imageLiteral(resourceName: "Workout Active")
		tabController.tabBar.items![2].selectedImage = #imageLiteral(resourceName: "Completed List Active")
		tabController.tabBar.items![3].selectedImage = #imageLiteral(resourceName: "Settings Active")
		
		tabController.loadNeededControllers()
		
		if !preferences.authorized || preferences.authVersion < authRequired {
			authorizeHealthAccess()
		}
		
		if preferences.runningWorkout != nil, let src = preferences.runningWorkoutSource {
			if src == .watch {
				self.updateMirroredWorkout(withCurrentExercize: preferences.currentExercize, part: preferences.currentPart, andTime: Date())
			} else {
				self.startLocalWorkout()
			}
		} else {
			self.exitWorkoutTracking()
		}
		
		dataManager.delegate = self
		
		return true
	}
	
	func authorizeHealthAccess() {
		healthStore.requestAuthorization(toShare: healthWriteData, read: healthReadData) { success, _ in
			if success {
				preferences.authorized = true
				preferences.authVersion = authRequired
			}
		}
	}
	
	func applicationShouldRequestHealthAuthorization(_ application: UIApplication) {
		healthStore.handleAuthorizationForExtension { success, _ in
			if success {
				preferences.authorized = true
				preferences.authVersion = authRequired
			}
		}
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
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
	}
	
}

extension AppDelegate: ExecuteWorkoutControllerDelegate {
	
	func startWorkout(_ workout: Workout) {
		tabController.selectedIndex = 1
		
		startLocalWorkout(workout)
	}
	
	fileprivate func startLocalWorkout(_ workout: Workout? = nil) {
		guard workoutController == nil, workout == nil || (workout != nil && preferences.runningWorkout == nil) else {
			return
		}
		
		let data: ExecuteWorkoutData
		if let w = workout {
			data = ExecuteWorkoutData(workout: w, resumeData: nil)
		} else {
			guard let wID = preferences.runningWorkout, let w = wID.getObject() as? Workout, let src = preferences.runningWorkoutSource, src == .phone else {
				return
			}
			
			data = ExecuteWorkoutData(workout: w, resumeData: (start: preferences.currentStart, curExercize: preferences.currentExercize, curPart: preferences.currentPart))
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
	
	func setCurrentSetText(_ text: String) {
		currentWorkout.setCurrentSetText(text)
	}
	
	func setOtherSetsViewHidden(_ hidden: Bool) {
		currentWorkout.setOtherSetsViewHidden(hidden)
	}
	
	func setOtherSetsText(_ text: String) {
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
	
	func setNextUpText(_ text: String) {
		currentWorkout.setNextUpText(text)
	}
	
	func notifyEndRest() {
		
	}
	
	func endNotifyEndRest() {
		
	}
	
	func notifyExercizeChange() {
		
	}
	
	func askUpdateWeight(with data: UpdateWeightData) {
		currentWorkout.askUpdateWeight(with: data)
	}
	
	func workoutHasStarted() {
		currentWorkout.workoutHasStarted()
	}
	
	func exitWorkoutTracking() {
		workoutController = nil
		currentWorkout.exitWorkoutTracking()
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
	
	func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date) {
		guard preferences.runningWorkout != nil else {
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

