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
	
	// FIXME: Make an OrganizedWorkout
	let workout: Workout
	let resumeData: (start: Date, curExercize: Int, curPart: Int)?
	
}

struct UpdateWeightData {
	
	let workoutController: ExecuteWorkoutController
	let set: RepsSet
	let sum: Double
	let saveAddWeight: Bool
	
}

protocol ExecuteWorkoutControllerDelegate: AnyObject {
	
	func setWorkoutTitle(_ text: String)
	
	func setBPM(_ text: String)
	func startTimer(at date: Date)
	func stopTimer()
	
	func setCurrentExercizeViewHidden(_ hidden: Bool)
	func setExercizeName(_ name: String)
	func setCurrentSetViewHidden(_ hidden: Bool)
	func setCurrentSetText(_ text: String)
	func setOtherSetsViewHidden(_ hidden: Bool)
	func setOtherSetsText(_ text: String)
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
	func setNextUpText(_ text: String)
	
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
	
	private var restoring: Bool
	private var workout: Workout
	fileprivate var start: Date!
	fileprivate var end: Date!
	private var exercizes: [Exercize]
	/// The current exercize, rest or circuit.
	private var curExercize: Int // TODO: Remove
	/// The current set inside the current exercize or circuit, this identifies both the set and, if any, its subsequent rest period.
	private var curPart: Int // TODO: Remove
	private(set) var isLastPart = false
	private(set) var isRestMode: Bool
	private var restTimer: Timer? {
		didSet {
			DispatchQueue.main.async {
				oldValue?.invalidate()
			}
		}
	}
	private var addWeight: Double
	private var restEndDate: Date?
	
	#if os(watchOS)
	private var session: HKWorkoutSession!
	#endif
	private var heartQuery: HKAnchoredObjectQuery!
	private var invalidateBPM: Timer! {
		didSet {
			DispatchQueue.main.async {
				oldValue?.invalidate()
			}
		}
	}
	fileprivate var workoutEvents: [HKWorkoutEvent]
	fileprivate var hasTerminationError: Bool
	private var terminateAndSave: Bool
	private(set) var isCompleted = false
	
	private weak var view: ExecuteWorkoutControllerDelegate!

	init(data: ExecuteWorkoutData, viewController: ExecuteWorkoutControllerDelegate, source: RunningWorkoutSource) {
		self.source = source
		self.isMirroring = false
		self.view = viewController
		
		view.setWorkoutTitle("")
		view.setBPM(noHeart)
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setWorkoutDoneViewHidden(true)
		view.setNextUpTextHidden(true)
		
		restoring = false
		start = nil
		end = nil
		curExercize = 0
		curPart = 0
		isRestMode = false
		restTimer = nil
		addWeight = 0
		
		heartQuery = nil
		invalidateBPM = nil
		workoutEvents = []
		hasTerminationError = false
		terminateAndSave = true
		
		workout = data.workout
		exercizes = workout.exercizeList
		appDelegate.dataManager.setRunningWorkout(workout, fromSource: source)
		
		if let (date, exercize, part) = data.resumeData {
			restoring = true
			start = date
			curPart = part
			curExercize = exercize
			
			for _ in 0 ..< exercize {
				guard exercizes.count > 0 else {
					break
				}
				
				exercizes.remove(at: 0)
			}
			
			appDelegate.dataManager.preferences.currentExercize = exercize
			appDelegate.dataManager.preferences.currentPart = part
		} else {
			appDelegate.dataManager.preferences.currentExercize = 0
			appDelegate.dataManager.preferences.currentPart = 0
		}
		
		super.init()
		
		view.setWorkoutTitle(workout.name)
		
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
		guard let workout = appDelegate.dataManager.preferences.runningWorkout?.getObject(fromDataManager: appDelegate.dataManager) as? Workout else {
			return nil
		}
		
		self.source = .watch
		self.isMirroring = true
		self.view = viewController
		
		view.setWorkoutTitle("")
		view.setBPM(noHeart)
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setWorkoutDoneViewHidden(true)
		view.setNextUpTextHidden(true)
		
		restoring = false
		start = nil
		end = nil
		curExercize = 0
		curPart = 0
		isRestMode = false
		restTimer = nil
		addWeight = 0
		
		heartQuery = nil
		invalidateBPM = nil
		workoutEvents = []
		hasTerminationError = false
		terminateAndSave = true
		
		self.workout = workout
		exercizes = workout.exercizeList
		
		super.init()
		
		view.setWorkoutTitle(workout.name)
		
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
			
			appDelegate.dataManager.sendWorkoutStatusUpdate()
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
		
		guard let curEx = exercizes.first else {
			endWorkout()
			return nil
		}
		
		var set: RepsSet?
		
		if curEx.isRest {
			exercizes.remove(at: 0)
			curPart = 0
			
			appDelegate.dataManager.preferences.currentExercize += 1
			appDelegate.dataManager.preferences.currentPart = curPart
		} else {
			if curPart % 2 == 0 {
				set = curEx[Int32(curPart / 2)]
			}
			
			let maxPart = 2 * curEx.sets.count - 1
			curPart += 1
			if curPart >= maxPart {
				exercizes.remove(at: 0)
				curPart = 0
				
				appDelegate.dataManager.preferences.currentExercize += 1
			}
			
			appDelegate.dataManager.preferences.currentPart = curPart
		}
		
		appDelegate.dataManager.sendWorkoutStatusUpdate()
		return set
	}
	
	private func displayStep(withTime time: Date? = nil) {
		guard let curEx = exercizes.first else {
			if isMirroring {
				view.exitWorkoutTracking()
			} else {
				endWorkout()
			}
			
			return
		}
		
		isLastPart = isLastPart || (exercizes.count == 1 && curPart == 2 * curEx.sets.count - 2)
		
		var setRest: TimeInterval?
		
		if curEx.isRest {
			setRest = curEx.rest
			view.setCurrentExercizeViewHidden(true)
		} else {
			view.setCurrentExercizeViewHidden(false)
			
			let setN = curPart / 2
			guard let set = curEx[Int32(setN)] else {
				if !isMirroring {
					nextStep()
				}
				
				return
			}
			
			if curPart == 0 {
				// Reset add weight for new exercize
				addWeight = 0
			}
			
			let setInfoText = {
				guard let (ex, _, other) = self.currentSetInfo else {
					return
				}
				
				self.view.setExercizeName(ex)
				if let other = other {
					self.view.setOtherSetsText(other)
					self.view.setOtherSetsViewHidden(false)
				} else {
					self.view.setOtherSetsViewHidden(true)
				}
			}
			
			if curPart % 2 == 0 {
				setRest = nil
				view.setCurrentSetText(set.description)
				
				setInfoText()
				
				view.setCurrentSetViewHidden(false)
				// Hide end button if mirroring
				view.setSetDoneButtonHidden(isMirroring)
			} else {
				setRest = set.rest
				
				if restoring {
					setInfoText()
					
					restoring = false
				}
				
				view.setCurrentSetViewHidden(true)
				view.setSetDoneButtonHidden(true)
			}
		}
		
		if let restTime = setRest {
			guard restTime > 0 else {
				// A rest time of 0:00 is allowed between sets, jump to next set
				if !isMirroring {
					nextStep()
				}
				
				return
			}
			
			let now = Date()
			var endTime = appDelegate.dataManager.preferences.currentRestEnd ?? (time ?? now).addingTimeInterval(restTime)
			if endTime < now {
				endTime = now
			}
			let endsIn = endTime.timeIntervalSince(now)
			appDelegate.dataManager.preferences.currentRestEnd = endTime
			self.restEndDate = endTime
			
			view.startRestTimer(to: endTime)
			view.setRestViewHidden(false)
			// Hide end rest button if mirroring
			view.setRestEndButtonHidden(isMirroring)
			
			DispatchQueue.main.async {
				self.restTimer = Timer.scheduledTimer(withTimeInterval: endsIn, repeats: false) { _ in
					self.view.stopRestTimer()
					if !self.isMirroring {
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
		
		if !isMirroring {
			view.notifyExercizeChange(isRest: setRest != nil)
		}
		isRestMode = setRest != nil
		
		if exercizes.count >= 2 {
			let txt: String
			let nextEx = exercizes[1]
			if nextEx.isRest {
				txt = nextEx.rest.getDuration(hideHours: true) //+ nextRestTxt
			} else {
				let nextWeight = nextEx[0]?.weight ?? 0
				txt = nextEx.name! + (nextWeight > 0 ? ", \(nextWeight.toString())kg" : "")
			}
			view.setNextUpText(nextTxt + txt)
		} else {
			view.setNextUpText(nextTxt + nextEndTxt)
		}
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
	func updateMirroredWorkout(withCurrentExercize exercize: Int, part: Int, andTime date: Date) {
		guard isMirroring else {
			return
		}
		
		if self.start == nil {
			start = appDelegate.dataManager.preferences.currentStart
			workoutSessionStarted()
		}
		
		for _ in 0 ..< min(exercizes.count, exercize - curExercize) {
			_ = exercizes.remove(at: 0)
		}
		
		curExercize = exercize
		curPart = part
		
		appDelegate.dataManager.preferences.currentExercize = curExercize
		appDelegate.dataManager.preferences.currentPart = curPart
		
		self.restoring = true
		displayStep(withTime: date)
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
		// TODO: Save `nil` in preferences for current rest end
	}
	
	func endSet() {
		guard !isMirroring, !isRestMode else {
			return
		}
		
		if let set = prepareNextStep() {
			// The next part has already been prepared so the current part is 0 only if the exercize has changed
			view.askUpdateWeight(with: UpdateWeightData(workoutController: self, set: set, sum: addWeight, saveAddWeight: curPart != 0))
		}
		displayStep()
	}
	
	func setAddWeight(_ add: Double) {
		guard !isMirroring else {
			return
		}
		
		addWeight = add
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
	
	// MARK: - Information Gathering
	
	var currentRestTime: (duration: TimeInterval, endTime: Date)? {
		guard let curEx = exercizes.first, let end = self.restEndDate else {
			return nil
		}
		
		if curEx.isRest {
			return (curEx.rest, end)
		} else {
			guard let set = curEx[Int32(curPart / 2)], curPart % 2 == 1 else {
				return nil
			}
			
			return (set.rest, end)
		}
	}
	
	var currentSetInfo: (exercize: String, setInfo: String, otherSetsInfo: String?)? {
		let setN = curPart / 2
		guard let curEx = exercizes.first, !curEx.isRest, let set = curEx[Int32(setN)] else {
			return nil
		}
		
		var other: String?
		let otherSet = Array(curEx.setList.suffix(from: setN + 1))
		if otherSet.count > 0 {
			other = "\(otherSet.count) other: " + otherSet.map { $0.description }.joined(separator: ", ")
		}
		
		return (curEx.name ?? "", set.description, other)
	}
	
	var currentIsRestExercize: Bool {
		return exercizes.first?.isRest ?? true
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
