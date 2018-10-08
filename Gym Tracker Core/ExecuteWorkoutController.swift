//
//  ExecuteWorkoutController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 07/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

public struct ExecuteWorkoutData {
	
	public let workout: GTWorkout
	public let resume: Bool
	public let choices: [Int32]
	
	public init(workout w: GTWorkout, resume r: Bool, choices c: [Int32] = []) {
		self.workout = w
		self.resume = r
		self.choices = c
	}
	
}

public struct UpdateSecondaryInfoData: Equatable {
	
	public let workoutController: ExecuteWorkoutController
	public let set: GTSet
	
}

public protocol ExecuteWorkoutControllerDelegate: AnyObject {
	
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
	func askUpdateSecondaryInfo(with data: UpdateSecondaryInfoData)
	
	func workoutHasStarted()
	func exitWorkoutTracking()
	func globallyUpdateSecondaryInfoChange()
	
}

public class ExecuteWorkoutController: NSObject {
	
	private let dataManager: DataManager
	
	private let source: RunningWorkoutSource
	public private(set) var isMirroring: Bool
	
	static public let workoutNameMetadataKey = "Workout"
	private let noHeart = "– –"
	private let nextTxt = GTLocalizedString("NEXT_EXERCIZE_FLAG", comment: "Next:")
	private let nextEndTxt = GTLocalizedString("NEXT_EXERCIZE_END", comment: "End")
	
	private let activityType = HKWorkoutActivityType.traditionalStrengthTraining
	private let isIndoor = true
	
	private let data: ExecuteWorkoutData!
	private let workout: GTWorkout
	fileprivate var start: Date! = nil
	fileprivate var end: Date! = nil
	private var workoutIterator: WorkoutIterator!
	private var currentStep: WorkoutStep?
	/// If the current part is the last set in the entire workout, used to correctly display notifications.
	public var isLastPart: Bool {
		return currentStep?.isLast ?? false
	}
	/// If the current part is a rest.
	public var isRestMode: Bool {
		return restStart != nil
	}
	/// The start time of the current rest.
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
	public private(set) var isCompleted = false
	
	private weak var view: ExecuteWorkoutControllerDelegate!
	
	override private init() {
		fatalError("Not supported")
	}

	public init(data: ExecuteWorkoutData, viewController: ExecuteWorkoutControllerDelegate, source: RunningWorkoutSource, dataManager: DataManager) {
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
		
		let chList = workout.choices
		let ch = (data.resume
			? dataManager.preferences.currentChoices ?? []
			: data.choices
			).prefix(chList.count)
		self.choices = zip(chList, ch + [Int32](repeating: -1, count: max(0, chList.count - ch.count)))
			.map { $0 }	
	
		super.init()
		
		self.loadIterator()
	}
	
	typealias Choice = (choice: GTChoice, exercize: Int32)
	private var choices: [Choice]
	
	private func loadIterator() {
		if let iter = WorkoutIterator(workout, choices: self.choices.map { $0.1 }, using: dataManager.preferences) {
			self.workoutIterator = iter
			self.completeStartup()
		} else {
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
	
	public func reportChoices(_ choices: [GTChoice: Int32]) {
		for (c, i) in choices {
			if let index = self.choices.firstIndex(where: { $0.choice == c }) {
				self.choices[index].exercize = i
			}
		}
		
		self.loadIterator()
	}
	
	/// Cancel the workout while choosing the exercizes as prompted by `askForChoices(_)` call to the view controller.
	///
	/// If the workout has already stared, i.e. choices (if any) have been reported with `reportChoices(_)`, use `cancelWorkout()` instead.
	public func cancelStartup() {
		guard self.workoutIterator == nil else {
			return
		}
		
		self.isCompleted = true
		self.terminateAndSave = false
		self.view.disableGlobalActions()
		terminate()
		dataManager.setRunningWorkout(nil, fromSource: source)
		view.exitWorkoutTracking()
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
				
				if #available(watchOS 5.0, *) {
					session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
					session.delegate = self
					
					session.startActivity(with: nil)
				} else {
					session = try HKWorkoutSession(configuration: configuration)
					session.delegate = self
					
					healthStore.start(session)
				}
			} catch {
				dataManager.setRunningWorkout(nil, fromSource: source)
				
				view.setWorkoutDoneText(GTLocalizedString("WORKOUT_START_ERR", comment: "Err starting"))
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
	public init?(mirrorWorkoutForViewController viewController: ExecuteWorkoutControllerDelegate, dataManager: DataManager) {
		guard let w = dataManager.preferences.runningWorkout?.getObject(fromDataManager: dataManager) as? GTWorkout else {
			return nil
		}
		
		self.dataManager = dataManager
		self.source = .watch
		self.isMirroring = true
		self.view = viewController
		self.choices = [] // This is useless while mirroring
		self.workout = w
		self.data = nil
		
		guard let iter = WorkoutIterator(workout, choices: dataManager.preferences.currentChoices ?? [], using: dataManager.preferences) else {
			return nil
		}
		workoutIterator = iter
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
	
	private func endWorkoutSession(ended: (() -> Void)? = nil) {
		guard !isMirroring else {
			return
		}
		
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setNextUpTextHidden(true)
		
		postEndAction = ended
		self.view.stopTimer()
		self.view.disableGlobalActions()
		terminate()
		
		view.setWorkoutDoneButtonEnabled(false)
		view.setWorkoutDoneText(GTLocalizedString("WORKOUT_ENDING", comment: "Ending..."))
		view.setWorkoutDoneViewHidden(false)
		
		end = Date()
		#if os(watchOS)
			if #available(watchOS 5.0, *) {
				session.end()
			} else {
				healthStore.end(session)
			}
		#else
			workoutSessionEnded()
		#endif
	}
	
	private var postEndAction: (() -> Void)?
	
	fileprivate func workoutSessionEnded(doSave: Bool = true) {
		postEndAction?()
		postEndAction = nil
		
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
		workoutIterator?.destroyPersistedState()
		
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
		
		let endTxt = hasTerminationError ? GTLocalizedString("WORKOUT_STOP_ERR", comment: "Err") + "\n" : ""
		view.setWorkoutDoneText(GTLocalizedString("WORKOUT_SAVING", comment: "Saving..."))
		dataManager.setRunningWorkout(nil, fromSource: source)
		
		let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
		let device = HKDevice.local()
		
		let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
		let devicePredicate = HKQuery.predicateForObjects(from: [device])
		let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
		let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		
		let chList = choices.map { c -> GTChoice in
			c.0.lastChosen = c.1
			
			return c.0
		}
		if !dataManager.persistChangesForObjects(chList, andDeleteObjects: []) {
			dataManager.discardAllChanges()
		}
		
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
						self.view.setWorkoutDoneText(endTxt + GTLocalizedString("WORKOUT_SAVED", comment: "Saved"))
					} else {
						self.view.setWorkoutDoneText(endTxt + GTLocalizedString("WORKOUT_SAVE_ERROR", comment: "Error"))
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
	public func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date?) {
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
	public func mirroredWorkoutHasEnded() {
		guard isMirroring else {
			return
		}
		
		workoutSessionEnded()
		view.exitWorkoutTracking()
	}
	
	func refreshView() {
		displayStep()
	}
	
	public func endRest() {
		guard !isMirroring, isRestMode else {
			return
		}
		
		view.stopRestTimer()
		view.endNotifyEndRest()
		restTimer = nil
		
		nextStep()
	}
	
	public func endSet(endTime: Date? = nil, secondaryInfoChange change: Double? = nil) {
		guard !isMirroring, !isRestMode else {
			return
		}
		
		if let set = prepareNextStep(setEndTime: endTime) {
			if let ch = change {
				self.setSecondaryInfoChange(ch, for: set, refreshView: false)
			} else {
				view.askUpdateSecondaryInfo(with: UpdateSecondaryInfoData(workoutController: self, set: set))
			}
		}
		displayStep()
	}
	
	public func isManaging(_ p: GTPart) -> Bool {
		return p.parentHierarchy.contains { ($0 as? GTWorkout) == workout }
	}
	
	public func isManaging(_ s: GTSet) -> Bool {
		return isManaging(s.exercize)
	}
	
	public func secondaryInfoChange(for s: GTSet, forProposingChange: Bool = false) -> Double {
		guard !forProposingChange else {
			return workoutIterator.secondaryInfoChange(for: s.exercize)
		}
		
		let (ch, cur) = workoutIterator.secondaryInfoChange(for: s)
		
		if cur {
			return isRestMode ? 0 : ch
		} else {
			return ch
		}
	}
	
	public func setSecondaryInfoChange(_ change: Double, for set: GTSet) {
		setSecondaryInfoChange(change, for: set, refreshView: true)
	}
	
	private func setSecondaryInfoChange(_ change: Double, for set: GTSet, refreshView: Bool) {
		guard !isMirroring else {
			return
		}
		
		let success = {
			self.workoutIterator.setSecondaryInfoChange(change, for: set.exercize)
			self.currentStep?.updateSecondaryInfoChange()
			self.view.globallyUpdateSecondaryInfoChange()
			if refreshView {
				self.displayStep(isRefresh: true)
			}
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
	
	public func endWorkout() {
		guard !isMirroring else {
			return
		}
		
		endWorkoutSession()
	}
	
	public func cancelWorkout() {
		guard !isMirroring, workoutIterator != nil else {
			return
		}
		
		self.isCompleted = true
		self.terminateAndSave = false
		endWorkoutSession {
			self.dataManager.setRunningWorkout(nil, fromSource: self.source)
			self.view.exitWorkoutTracking()
		}
	}
	
	// MARK: - Notification Information Gathering
	
	public var currentRestTime: (duration: TimeInterval, endTime: Date)? {
		guard isRestMode, let rest = currentStep?.rest, let end = self.restEndDate else {
			return nil
		}
		
		return (rest, end)
	}
	
	public var currentSetInfo: (exercize: String, setInfo: String, otherSetsInfo: String?)? {
		guard !(currentStep?.isRest ?? true), let e = currentStep?.exercizeName, let s = currentStep?.currentInfo else {
			return nil
		}
		
		return (e, s.string, currentStep?.otherPartsInfo?.string)
	}
	
	public var currentSetRawInfo: (secondaryInfo: Double, change: Double)? {
		guard !(currentStep?.isRest ?? true), let set = currentStep?.set else {
			return nil
		}
		
		return (set.secondaryInfo, secondaryInfoChange(for: set))
	}
	
	public var currentIsRestPeriod: Bool {
		return currentStep?.isRest ?? false
	}
	
}

// MARK: - HealthKit Integration
#if os(watchOS)

extension ExecuteWorkoutController: HKWorkoutSessionDelegate {

	public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		if fromState == .notStarted && toState == .running {
			start = self.start ?? date
			
			workoutSessionStarted(date)
		}
		
		if toState == .ended {
			workoutSessionEnded(doSave: fromState == .running || fromState == .paused)
		}
	}
	
	public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		hasTerminationError = true
	}
	
	public func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
		workoutEvents.append(event)
	}
	
}

#endif
