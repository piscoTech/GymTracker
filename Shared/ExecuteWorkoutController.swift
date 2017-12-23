//
//  ExecuteWorkoutController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 07/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

struct ExecuteWorkoutData {
	
	let workout: OrganizedWorkout
	let resume: Bool
	
}

struct UpdateWeightData {
	
	let workoutController: ExecuteWorkoutController
	let set: RepsSet
	
}

protocol ExecuteWorkoutControllerDelegate: AnyObject {
	
	func setWorkoutTitle(_ text: String)
	
	func setBPM(_ text: String)
	func startTimer(at date: Date)
	func stopTimer()
	
	func setCurrentExercizeViewHidden(_ hidden: Bool)
	func setExercizeName(_ name: String)
	func setCurrentSetViewHidden(_ hidden: Bool)
	func setCurrentSetText(_ text: NSAttributedString)
	func setOtherSetsViewHidden(_ hidden: Bool)
	func setOtherSetsText(_ text: NSAttributedString)
	func setSetDoneButtonHidden(_ hidden: Bool)
	
	func startRestTimer(to date: Date)
	func stopRestTimer()
	func setRestViewHidden(_ hidden: Bool)
	func setRestEndButtonHidden(_ hidden: Bool)
	
	func setWorkoutDoneViewHidden(_ hidden: Bool)
	func setWorkoutDoneText(_ text: String)
	func setWorkoutDoneButtonEnabled(_ enabled: Bool)
	func disableGlobalActions()
	
	func setNextUpTextHidden(_ hidden: Bool)
	func setNextUpText(_ text: NSAttributedString)
	
	func notifyEndRest()
	func endNotifyEndRest()
	func notifyExercizeChange(isRest: Bool)
	func askUpdateWeight(with data: UpdateWeightData)
	
	func workoutHasStarted()
	func exitWorkoutTracking()
	
}

class ExecuteWorkoutController: NSObject {
	
	private let source: RunningWorkoutSource
	private(set) var isMirroring: Bool
	
	static let workoutNameMetadataKey = "Workout"
	private let noHeart = "– –"
	private let nextTxt = NSLocalizedString("NEXT_EXERCIZE_FLAG", comment: "Next:")
	private let nextEndTxt = NSLocalizedString("NEXT_EXERCIZE_END", comment: "End")
	
	private let activityType = HKWorkoutActivityType.traditionalStrengthTraining
	private let isIndoor = true
	
	private var workout: OrganizedWorkout
	fileprivate var start: Date! = nil
	fileprivate var end: Date! = nil
	private var workoutIterator: WorkoutIterator
	private var currentStep: WorkoutStep?
	/// If the current part is the last set in the entire workout, used to correctly display notifications.
	private(set) var isLastPart = false
	/// If the current part is a rest.
	var isRestMode: Bool {
		return restStart != nil
	}
	/// The start time of teh current rest.
	private var restStart: Date?
	private var restTimer: Timer? = nil {
		didSet {
			DispatchQueue.main.async {
				oldValue?.invalidate()
			}
		}
	}
	private var restEndDate: Date?
	
	#if os(watchOS)
	private var session: HKWorkoutSession!
	#endif
	private var heartQuery: HKAnchoredObjectQuery! = nil
	private var invalidateBPM: Timer! = nil {
		didSet {
			DispatchQueue.main.async {
				oldValue?.invalidate()
			}
		}
	}
	fileprivate var workoutEvents: [HKWorkoutEvent] = []
	fileprivate var hasTerminationError = false
	private var terminateAndSave = true
	private(set) var isCompleted = false
	
	private weak var view: ExecuteWorkoutControllerDelegate!

	init(data: ExecuteWorkoutData, viewController: ExecuteWorkoutControllerDelegate, source: RunningWorkoutSource) {
		self.source = source
		self.isMirroring = false
		self.view = viewController
		self.workout = data.workout
		
		view.setWorkoutTitle(workout.name)
		view.setBPM(noHeart)
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setWorkoutDoneViewHidden(true)
		view.setNextUpTextHidden(true)
		
		appDelegate.dataManager.setRunningWorkout(workout.raw, fromSource: source)
		workoutIterator = WorkoutIterator(workout)
		
		if data.resume {
			start = appDelegate.dataManager.preferences.currentStart
			workoutIterator.loadPersistedState()
			restStart = appDelegate.dataManager.preferences.currentRestEnd != nil ? Date() : nil
		}
		
		currentStep = workoutIterator.next()
		workoutIterator.persistState()
		
		super.init()
		
		DispatchQueue.main.async {
			self.view.workoutHasStarted()
		}
		
		#if os(watchOS)
			do {
				let configuration = HKWorkoutConfiguration()
				configuration.activityType = activityType
				configuration.locationType = isIndoor ? .indoor : .outdoor
				
				session = try HKWorkoutSession(configuration: configuration)
				
				session.delegate = self
				healthStore.start(session)
			} catch {
				appDelegate.dataManager.setRunningWorkout(nil, fromSource: source)
				
				view.setWorkoutDoneText(NSLocalizedString("WORKOUT_START_ERR", comment: "Err starting"))
				view.setWorkoutDoneViewHidden(false)
				view.disableGlobalActions()
			}
		#else
			start = self.start ?? Date()
			
			DispatchQueue.main.async {
				self.workoutSessionStarted()
			}
		#endif
	}
	
	@available(watchOS, unavailable)
	init?(mirrorWorkoutForViewController viewController: ExecuteWorkoutControllerDelegate) {
		// FIXME: Implement me
		return nil
		guard let w = appDelegate.dataManager.preferences.runningWorkout?.getObject(fromDataManager: appDelegate.dataManager) as? Workout else {
			return nil
		}
		
		self.source = .watch
		self.isMirroring = true
		self.view = viewController
		self.workout = OrganizedWorkout(w)
		
		workoutIterator = WorkoutIterator(workout)
		currentStep = workoutIterator.next()
		
		view.setWorkoutTitle(workout.name)
		view.setBPM(noHeart)
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setWorkoutDoneViewHidden(true)
		view.setNextUpTextHidden(true)
		
		super.init()
		
		DispatchQueue.main.async {
			self.view.workoutHasStarted()
		}
	}
	
	// MARK: - Workout Handling
	
	fileprivate func workoutSessionStarted(_ date: Date? = nil) {
		appDelegate.dataManager.preferences.currentStart = start
		appDelegate.dataManager.sendWorkoutStartDate()
		
		let heartUnit = HKUnit.count().unitDivided(by: .minute())
		let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let predicate = HKQuery.predicateForSamples(withStart: date ?? self.start, end: nil, options: [])
		let handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { _, samples, _, _, _ in
			if let last = (samples as? [HKQuantitySample])?.sorted(by: { (a, b) -> Bool in
				return a.startDate < b.startDate
			}).last {
				DispatchQueue.main.async {
					self.invalidateBPM = Timer.scheduledTimer(withTimeInterval: 3 * 60, repeats: false) { _ in
						DispatchQueue.main.async {
							self.view.setBPM(self.noHeart)
						}
					}
					
					RunLoop.main.add(self.invalidateBPM!, forMode: .commonModes)
					self.view.setBPM(last.quantity.doubleValue(for: heartUnit).rounded().toString())
				}
			}
		}
		heartQuery = HKAnchoredObjectQuery(type: heartRate, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: handler)
		heartQuery.updateHandler = handler
		healthStore.execute(heartQuery)
		
		DispatchQueue.main.async {
			self.view.startTimer(at: self.start)
			self.view.setNextUpTextHidden(false)
			
			appDelegate.dataManager.sendWorkoutStatusUpdate(restStart: self.restStart)
			self.displayStep()
		}
	}
	
	private func endWorkoutSession() {
		guard !isMirroring else {
			return
		}
		
		#if os(watchOS)
			healthStore.end(session)
		#else
			end = Date()
			workoutSessionEnded()
		#endif
	}
	
	fileprivate func workoutSessionEnded(doSave: Bool = true) {
		self.view.stopTimer()
		self.view.disableGlobalActions()
		terminate()
		
		if !isMirroring && terminateAndSave && doSave {
			DispatchQueue.main.async {
				self.saveWorkout()
			}
		}
	}
	
	private func terminate() {
		if let heart = heartQuery {
			healthStore.stop(heart)
			heartQuery = nil
		}
		invalidateBPM = nil
		restTimer = nil
		
		view.endNotifyEndRest()
	}
	
	private func nextStep() {
		prepareNextStep()
		displayStep()
	}
	
	///Moves the point of workout execution to the next step.
	///- return: The current set, before advancing, if the current part is a set, `nil` otherwise.
	@discardableResult private func prepareNextStep() -> RepsSet? {
		guard !isMirroring else {
			return nil
		}
		
		guard let curStep = currentStep else {
			endWorkout()
			return nil
		}
		
		let set: RepsSet?
		if self.isRestMode {
			set = nil
			currentStep = workoutIterator.next()
			restStart = (currentStep?.isRest ?? false) ? Date() : nil
		} else { // Must be a set
			set = curStep.set
			if curStep.rest != nil {
				restStart = Date()
			} else {
				currentStep = workoutIterator.next()
				restStart = (currentStep?.isRest ?? false) ? Date() : nil
			}
		}
		
		workoutIterator.persistState()
		appDelegate.dataManager.sendWorkoutStatusUpdate(restStart: restStart)
		return set
	}
	
	private func displayStep(isRefresh: Bool = false) {
		guard let curStep = currentStep else {
			if isMirroring {
				view.exitWorkoutTracking()
			} else {
				endWorkout()
			}
			
			return
		}
		
		isLastPart = curStep.nextUpInfo == nil
		let setRest: TimeInterval?
		
		if curStep.isRest {
			setRest = curStep.rest
			view.setCurrentExercizeViewHidden(true)
		} else {
			view.setCurrentExercizeViewHidden(false)
			view.setExercizeName(curStep.exercizeName ?? "")
			
			if isRestMode {
				setRest = curStep.rest
				view.setCurrentSetViewHidden(true)
				view.setSetDoneButtonHidden(true)
			} else {
				setRest = nil
				view.setCurrentSetViewHidden(false)
				view.setCurrentSetText(curStep.currentReps ?? NSAttributedString())
				view.setSetDoneButtonHidden(isMirroring)
			}
			
			if let oth = curStep.otherPartsInfo {
				view.setOtherSetsText(oth)
				view.setOtherSetsViewHidden(false)
			} else {
				view.setOtherSetsViewHidden(true)
			}
		}
		
		if let restTime = setRest {
			let start = restStart ?? Date()
			let endTime = max(appDelegate.dataManager.preferences.currentRestEnd ?? start.addingTimeInterval(restTime), start)
			let endsIn = endTime.timeIntervalSince(start)
			self.restStart = start
			self.restEndDate = endTime
			appDelegate.dataManager.preferences.currentRestEnd = endTime
			
			view.startRestTimer(to: endTime)
			view.setRestViewHidden(false)
			// Hide end rest button if mirroring
			view.setRestEndButtonHidden(isMirroring)
			
			DispatchQueue.main.async {
				self.restTimer = Timer.scheduledTimer(withTimeInterval: endsIn, repeats: false) { _ in
					self.view.stopRestTimer()
					if !isRefresh && !self.isMirroring {
						self.view.notifyEndRest()
					}
				}
				RunLoop.main.add(self.restTimer!, forMode: .commonModes)
			}
		} else {
			appDelegate.dataManager.preferences.currentRestEnd = nil
			self.restEndDate = nil
			
			view.stopRestTimer()
			view.setRestViewHidden(true)
		}
		
		if !isRefresh && !isMirroring {
			view.notifyExercizeChange(isRest: setRest != nil)
		}
		
		let nextUp = NSMutableAttributedString(string: nextTxt)
		nextUp.append(curStep.nextUpInfo ?? NSAttributedString(string: nextEndTxt))
		view.setNextUpText(nextUp)
	}
	
	private func saveWorkout() {
		guard !isMirroring else {
			return
		}
		
		let endTxt = hasTerminationError ? NSLocalizedString("WORKOUT_STOP_ERR", comment: "Err") + "\n" : ""
		appDelegate.dataManager.setRunningWorkout(nil, fromSource: source)
		
		let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
		let device = HKDevice.local()
		
		let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
		let devicePredicate = HKQuery.predicateForObjects(from: [device])
		let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
		let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		
		// Access workout's name on the main thread as callback are called in the background
		let workoutName = self.workout.name
		
		let query = HKSampleQuery(sampleType: activeEnergyType, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortByDate]) { _, res, _ in
			var totalEnergy: HKQuantity?
			let energySamples = res as? [HKQuantitySample]
			if let energy = energySamples {
				let energyUnit = HKUnit.kilocalorie()
				totalEnergy = HKQuantity(unit: energyUnit, doubleValue: energy.reduce(0) { $0 + $1.quantity.doubleValue(for: energyUnit) })
			}
			
			let workout = HKWorkout(activityType: self.activityType,
			                        start: self.start,
			                        end: self.end,
			                        duration: self.end.timeIntervalSince(self.start),
			                        totalEnergyBurned: totalEnergy,
			                        totalDistance: nil,
			                        device: HKDevice.local(),
			                        metadata: [
										HKMetadataKeyIndoorWorkout: self.isIndoor,
										ExecuteWorkoutController.workoutNameMetadataKey: workoutName
									]
			)
			
			healthStore.save(workout, withCompletion: { success, _ in
				let complete = {
					self.isCompleted = true
					self.view.setWorkoutDoneButtonEnabled(true)
					if success {
						self.view.setWorkoutDoneText(endTxt + NSLocalizedString("WORKOUT_SAVED", comment: "Saved"))
					} else {
						self.view.setWorkoutDoneText(endTxt + NSLocalizedString("WORKOUT_SAVE_ERROR", comment: "Error"))
					}
				}
				
				if success {
					if let energy = energySamples {
						healthStore.add(energy, to: workout) { _, _ in
							DispatchQueue.main.async(execute: complete)
						}
					} else {
						DispatchQueue.main.async(execute: complete)
					}
				} else {
					DispatchQueue.main.async(execute: complete)
				}
			})
		}
		
		healthStore.execute(query)
	}
	
	// MARK: - Workout Actions
	
	@available(watchOS, unavailable)
	func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date?) {
		// FIXME: Implement me
		fatalError("Reimplementation in progress")
		guard isMirroring else {
			return
		}
		
		if self.start == nil {
			start = appDelegate.dataManager.preferences.currentStart
			workoutSessionStarted()
		}
		
		restStart = date
//		for _ in 0 ..< min(exercizes.count, exercize - curExercize) {
//			_ = exercizes.remove(at: 0)
//		}
//
//		curExercize = exercize
//		curPart = part
//
//		appDelegate.dataManager.preferences.currentExercize = curExercize
//		appDelegate.dataManager.preferences.currentPart = curPart
//
//		self.restoring = true
		displayStep()
	}
	
	@available(watchOS, unavailable)
	func mirroredWorkoutHasEnded() {
		// FIXME: Implement me
		fatalError("Reimplementation in progress")
		guard isMirroring else {
			return
		}
		
		workoutSessionEnded()
		view.exitWorkoutTracking()
	}
	
	func refreshView() {
		displayStep()
	}
	
	func endRest() {
		guard !isMirroring, isRestMode else {
			return
		}
		
		view.stopRestTimer()
		view.endNotifyEndRest()
		restTimer = nil
		
		nextStep()
	}
	
	func endSet() {
		guard !isMirroring, !isRestMode else {
			return
		}
		
		if let set = prepareNextStep() {
			view.askUpdateWeight(with: UpdateWeightData(workoutController: self, set: set))
		}
		displayStep()
	}
	
	func weightChange(for s: RepsSet) -> Double {
		return workoutIterator.weightChange(for: s.exercize)
	}
	
	func setWeightChange(_ change: Double, for: RepsSet) {
		guard !isMirroring else {
			return
		}
		
		// TODO: Forward to WorkoutIterator
		// TODO: Uncomment next lines after implementation
//		currentStep?.updateWeightChange(for: workoutIterator)
//		displayStep(isRefresh: true)
	}
	
	func endWorkout() {
		guard !isMirroring else {
			return
		}
		
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setNextUpTextHidden(true)
		
		view.setWorkoutDoneButtonEnabled(false)
		view.setWorkoutDoneText(NSLocalizedString("WORKOUT_SAVING", comment: "Saving..."))
		view.setWorkoutDoneViewHidden(false)
		
		endWorkoutSession()
	}
	
	func cancelWorkout() {
		guard !isMirroring else {
			return
		}
		
		self.isCompleted = true
		self.terminateAndSave = false
		endWorkoutSession()
		terminate()
		appDelegate.dataManager.setRunningWorkout(nil, fromSource: source)
		view.exitWorkoutTracking()
	}
	
	// MARK: - Notification Information Gathering
	
	var currentRestTime: (duration: TimeInterval, endTime: Date)? {
		guard isRestMode, let rest = currentStep?.rest, let end = self.restEndDate else {
			return nil
		}
		
		return (rest, end)
	}
	
	var currentSetInfo: (exercize: String, setInfo: String, otherSetsInfo: String?)? {
		guard !(currentStep?.isRest ?? true), let e = currentStep?.exercizeName, let s = currentStep?.currentReps else {
			return nil
		}
		
		return (e, s.string, currentStep?.otherPartsInfo?.string)
	}
	
	var currentIsRestPeriod: Bool {
		return currentStep?.isRest ?? false
	}
	
}

// MARK: - HealthKit Integration
#if os(watchOS)

extension ExecuteWorkoutController: HKWorkoutSessionDelegate {

	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		if fromState == .notStarted && toState == .running {
			start = self.start ?? date
			
			workoutSessionStarted(date)
		}
		
		if toState == .ended {
			end = date
			
			workoutSessionEnded(doSave: fromState == .running || fromState == .paused)
		}
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		hasTerminationError = true
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
		workoutEvents.append(event)
	}
	
}

#endif
