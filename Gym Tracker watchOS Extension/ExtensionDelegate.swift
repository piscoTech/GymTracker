//
//  ExtensionDelegate.swift
//  Gym Tracker watchOS Extension
//
//  Created by Marco Boschi on 20/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import HealthKit
import AVFoundation
import GymTrackerCore

class ExtensionDelegate: NSObject, WKExtensionDelegate, DataManagerDelegate {
	
	weak var workoutList: WorkoutListInterfaceController?
	weak var executeWorkout: ExecuteWorkoutInterfaceController?
	
	private(set) var dataManager: DataManager!

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
		
		dataManager = DataManager(for: .application)
		dataManager.delegate = self
		
		try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
		
		if let src = dataManager.preferences.runningWorkoutSource, src == .watch,
			let workoutID = dataManager.preferences.runningWorkout {
			if let workout = workoutID.getObject(fromDataManager: dataManager) as? GTWorkout {
				let data = ExecuteWorkoutData(workout: workout, resume: true)
				self.startWorkout(with: data, reloadNow: true)
			}
		}
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
	
	func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
		// Wait for workout data
	}
	
	func remoteWorkoutStart(_ workout: GTWorkout) {
		guard executeWorkout == nil else {
			return
		}
		
		self.startWorkout(with: ExecuteWorkoutData(workout: workout, resume: false))
	}

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted()
            default:
                // Make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
	
	func restoreDefaultState() {
		DispatchQueue.main.async {
			WKInterfaceController.reloadRootControllers(withNames: ["workoutList"], contexts: nil)
		}
	}
	
	func startWorkout(with data: ExecuteWorkoutData, reloadNow: Bool = false) {
		let r = { WKInterfaceController.reloadRootControllers(withNames: ["executeWorkout", "workoutDetail"], contexts: [data, WorkoutDetailData(listController: nil, workout: data.workout)]) }
		
		if reloadNow {
			r()
		} else {
			DispatchQueue.main.async(execute: r)
		}
	}
	
	// MARK: - Data Manager Delegate
	
	func refreshData() {
		DispatchQueue.main.async {
			self.workoutList?.reloadData()
		}
	}
	
	func enableEdit() {
		DispatchQueue.main.async {
			self.workoutList?.setEnable(true)
		}
	}
	
	func cancelAndDisableEdit() {
		DispatchQueue.main.async {
			self.workoutList?.setEnable(false)
		}
	}

}
