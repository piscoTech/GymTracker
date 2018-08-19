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
	
	let workout: GTWorkout
	let resume: Bool
	let choices: [Int32]
	
}

struct UpdateSecondaryInfoData {
	
	let workoutController: ExecuteWorkoutController
	let set: GTSet
	
}

protocol ExecuteWorkoutControllerDelegate: AnyObject {
	
	func setWorkoutTitle(_ text: String)
	func askForChoices(_ choices: [GTChoice])
	
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
	func askUpdateWeight(with data: UpdateSecondaryInfoData)
	
	func workoutHasStarted()
	func exitWorkoutTracking()
	
}

class ExecuteWorkoutController: NSObject {
	
	private let dataManager: DataManager
	
	private let source: RunningWorkoutSource
	private(set) var isMirroring: Bool
	
	static let workoutNameMetadataKey = "Workout"
	private let noHeart = "– –"
	private let nextTxt = NSLocalizedString("NEXT_EXERCIZE_FLAG", comment: "Next:")
	private let nextEndTxt = NSLocalizedString("NEXT_EXERCIZE_END", comment: "End")
	
	private let activityType = HKWorkoutActivityType.traditionalStrengthTraining
	private let isIndoor = true
	
	private let data: ExecuteWorkoutData!
	private let workout: GTWorkout
	fileprivate var start: Date! = nil
	fileprivate var end: Date! = nil
	private var workoutIterator: WorkoutIterator!
	private var currentStep: WorkoutStep?
	/// If the current part is the last set in the entire workout, used to correctly display notifications.
	var isLastPart: Bool {
		return currentStep?.isLast ?? false
	}
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
	
	override private init() {
		fatalError("Not supported")
	}

	init(data: ExecuteWorkoutData, viewController: ExecuteWorkoutControllerDelegate, source: RunningWorkoutSource, dataManager: DataManager) {
		self.dataManager = dataManager
		self.source = source
		self.isMirroring = false
		self.view = viewController
		self.workout = data.workout
		self.data = data
		
		view.setWorkoutTitle(workout.name)
		view.setBPM(noHeart)
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setWorkoutDoneViewHidden(true)
		view.setNextUpTextHidden(true)
		
		super.init()
		
		self.loadIterator()
	}
	
	typealias Choice = (choice: GTChoice, exercize: Int32)
	private var choices: [Choice]!
	
	private func loadIterator() {
		if let iter = WorkoutIterator(workout, choices: self.choices?.map { $0.1 } ?? data.choices, using: dataManager.preferences) {
			self.workoutIterator = iter
			self.completeStartup()
		} else {
			if self.choices == nil {
				let chList = workout.choices
				let ch = data.choices
				
				self.choices = zip(chList, ch + [Int32](repeating: -1, count: max(0, chList.count - ch.count))).map { $0 }
			}
			
			var ask = [GTChoice]()
			for (c, i) in choices {
				if i < 0 || i >= c.exercizes.count {
					ask.append(c)
				}
			}
			
			DispatchQueue.main.async {
				self.view.askForChoices(ask)
			}
		}
	}
	
	func reportChoices(_ choices: [GTChoice: Int32]) {
		for (c, i) in choices {
			if let index = self.choices.firstIndex(where: { $0.choice == c }) {
				self.choices[index].exercize = i
			}
		}
		
		self.loadIterator()
	}
	
	private func completeStartup() {
		dataManager.setRunningWorkout(workout, fromSource: source)
		
		if data.resume {
			start = dataManager.preferences.currentStart
			workoutIterator.loadPersistedState()
			restStart = dataManager.preferences.currentRestEnd != nil ? Date() : nil
		}
		
		currentStep = workoutIterator.next()
		workoutIterator.persistState()
		
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
				dataManager.setRunningWorkout(nil, fromSource: source)
				
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
	init?(mirrorWorkoutForViewController viewController: ExecuteWorkoutControllerDelegate, dataManager: DataManager) {
		guard let w = dataManager.preferences.runningWorkout?.getObject(fromDataManager: dataManager) as? GTWorkout else {
			return nil
		}
		
		self.dataManager = dataManager
		self.source = .watch
		self.isMirroring = true
		self.view = viewController
		#warning("Load choices from proferences")
		self.workout = w
		self.data = nil
		
		workoutIterator = WorkoutIterator(workout, choices: [], using: dataManager.preferences)!
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
		dataManager.preferences.currentStart = start
		dataManager.sendWorkoutStartDate()
		
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
					
					RunLoop.main.add(self.invalidateBPM!, forMode: .common)
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
			
			self.dataManager.sendWorkoutStatusUpdate(restStart: self.restStart)
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
		workoutIterator.destroyPersistedState()
		
		view.endNotifyEndRest()
	}
	
	private func nextStep() {
		prepareNextStep()
		displayStep()
	}
	
	///Moves the point of workout execution to the next step.
	///- parameter setEndTime: If the current step is a set followed by a rest period, pass a non-nil value to manually specify the time when that rest period has started. This is used when handling weight updates directly inside a notification (on iOS 12 and later) to consider the time spent changing the weight part of the rest period.
	///- returns: The current set, before advancing, if the current part is a set, `nil` otherwise.
	@discardableResult private func prepareNextStep(setEndTime: Date? = nil) -> GTSet? {
		guard !isMirroring else {
			return nil
		}
		
		guard let curStep = currentStep else {
			endWorkout()
			return nil
		}
		
		let set: GTSet?
		if self.isRestMode {
			set = nil
			currentStep = workoutIterator.next()
			restStart = (currentStep?.isRest ?? false) ? Date() : nil
		} else { // Must be a set
			set = curStep.set
			let restStart = setEndTime ?? Date()
			if curStep.rest != nil {
				self.restStart = restStart
			} else {
				currentStep = workoutIterator.next()
				self.restStart = (currentStep?.isRest ?? false) ? restStart : nil
			}
		}
		
		workoutIterator.persistState()
		dataManager.sendWorkoutStatusUpdate(restStart: restStart)
		return set
	}
	
	private func displayStep(isRefresh: Bool = false) {
		guard let curStep = currentStep else {
			if isMirroring {
				view.exitWorkoutTracking()
			} else if !isRefresh {
				endWorkout()
			}
			
			return
		}
		let doNotify = !isRefresh && !self.isMirroring
		
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
				view.setCurrentSetText(curStep.currentInfo ?? NSAttributedString())
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
			let endTime = max(dataManager.preferences.currentRestEnd ?? start.addingTimeInterval(restTime), start)
			let endsIn = endTime.timeIntervalSinceNow
			self.restStart = start
			self.restEndDate = endTime
			dataManager.preferences.currentRestEnd = endTime
			
			view.startRestTimer(to: endTime)
			view.setRestViewHidden(false)
			// Hide end rest button if mirroring
			view.setRestEndButtonHidden(isMirroring)
			
			if doNotify {
				DispatchQueue.main.async {
					self.restTimer = Timer.scheduledTimer(withTimeInterval: endsIn, repeats: false) { _ in
						self.view.stopRestTimer()
						self.view.notifyEndRest()
					}
					RunLoop.main.add(self.restTimer!, forMode: .common)
				}
			}
		} else {
			dataManager.preferences.currentRestEnd = nil
			self.restEndDate = nil
			
			view.stopRestTimer()
			view.setRestViewHidden(true)
		}
		
		if doNotify {
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
		dataManager.setRunningWorkout(nil, fromSource: source)
		
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
		guard isMirroring else {
			return
		}
		
		if self.start == nil {
			start = dataManager.preferences.currentStart
			workoutSessionStarted()
		}
		
		dataManager.preferences.currentExercize = exercize
		dataManager.preferences.currentPart = part
		self.restStart = date
		
		workoutIterator.loadPersistedState()
		currentStep = workoutIterator.next()
		
		displayStep()
	}
	
	@available(watchOS, unavailable)
	func mirroredWorkoutHasEnded() {
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
	
	func endSet(endTime: Date? = nil, secondaryInfoChange change: Double? = nil) {
		guard !isMirroring, !isRestMode else {
			return
		}
		
		if let set = prepareNextStep(setEndTime: endTime) {
			if let ch = change {
				self.setSecondaryInfoChange(ch, for: set)
			} else {
				view.askUpdateWeight(with: UpdateSecondaryInfoData(workoutController: self, set: set))
			}
		}
		displayStep()
	}
	
	func secondaryInfoChange(for s: GTSet) -> Double {
		return workoutIterator.secondaryInfoChange(for: s.exercize)
	}
	
	func setSecondaryInfoChange(_ change: Double, for set: GTSet) {
		guard !isMirroring else {
			return
		}
		
		let success = {
			self.workoutIterator.setSecondaryInfoChange(change, for: set.exercize)
			self.currentStep?.updateSecondaryInfoChange()
			self.displayStep(isRefresh: true)
		}
		
		if change != 0 {
			// Avoid unnecessary saves
			set.set(secondaryInfo: change + set.secondaryInfo)
			if dataManager.persistChangesForObjects([set], andDeleteObjects: []) {
				success()
			} else {
				dataManager.discardAllChanges()
			}
		} else {
			success()
		}
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
		dataManager.setRunningWorkout(nil, fromSource: source)
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
		guard !(currentStep?.isRest ?? true), let e = currentStep?.exercizeName, let s = currentStep?.currentInfo else {
			return nil
		}
		
		return (e, s.string, currentStep?.otherPartsInfo?.string)
	}
	
	var currentSetRawInfo: (secondaryInfo: Double, change: Double)? {
		guard !(currentStep?.isRest ?? true), let set = currentStep?.set else {
			return nil
		}
		
		return (set.secondaryInfo, secondaryInfoChange(for: set))
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
