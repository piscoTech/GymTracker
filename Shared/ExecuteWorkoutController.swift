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
	
	let workout: Workout
	let resumeData: (start: Date, curExercize: Int, curPart: Int)?
	
}

struct UpdateWeightData {
	
	let workoutController: ExecuteWorkoutController
	let set: RepsSet
	let sum: Double
	let saveAddWeight: Bool
	
}

protocol ExecuteWorkoutViewController: AnyObject {
	
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
	
	func startRestTimer(for time: TimeInterval)
	func stopRestTimer()
	func setRestViewHidden(_ hidden: Bool)
	
	func setWorkoutDoneViewHidden(_ hidden: Bool)
	func setWorkoutDoneText(_ text: String)
	func setWorkoutDoneButtonEnabled(_ enabled: Bool)
	
	func setNextUpTextHidden(_ hidden: Bool)
	func setNextUpText(_ text: String)
	
	func notifyEndRest()
	func endNotifyEndRest()
	func notifyExercizeChange()
	func askUpdateWeight(with data: UpdateWeightData)
	func exitWorkoutTracking()
	
}

class ExecuteWorkoutController: NSObject {
	
	private let source: RunningWorkoutSource
	
	private let noHeart = "– –"
	private let nextTxt = NSLocalizedString("NEXT_EXERCIZE_FLAG", comment: "Next:")
	private let nextEndTxt = NSLocalizedString("NEXT_EXERCIZE_END", comment: "End")
	private let nextRestTxt = NSLocalizedString("NEXT_EXERCIZE_REST", comment: "rest")
	private let otherSetTxt = NSLocalizedString("OTHER_N_SET", comment: "other set")
	private let otherSetsTxt = NSLocalizedString("OTHER_N_SETS", comment: "other sets")
	private let activityType = HKWorkoutActivityType.traditionalStrengthTraining
	private let isIndoor = true
	
	private var restoring: Bool
	private var workout: Workout
	fileprivate var start: Date!
	fileprivate var end: Date!
	private var exercizes: [Exercize]
	private var curExercize: Int
	private var curPart: Int
	private var isRestMode: Bool
	private var restTimer: Timer?
	private var addWeight: Double
	
	#if os(watchOS)
	private var session: HKWorkoutSession!
	#endif
	private var heartQuery: HKAnchoredObjectQuery!
	private var invalidateBPM: Timer!
	fileprivate var workoutEvents: [HKWorkoutEvent]
	fileprivate var hasTerminationError: Bool
	private var terminateAndSave: Bool
	
	private weak var view: ExecuteWorkoutViewController!

	init(data: ExecuteWorkoutData, viewController: ExecuteWorkoutViewController, source: RunningWorkoutSource) {
		self.source = source
		self.view = viewController
		
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
		dataManager.setRunningWorkout(workout, fromSource: source)
		
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
			
			preferences.currentExercize = exercize
			preferences.currentPart = part
		} else {
			preferences.currentExercize = 0
			preferences.currentPart = 0
		}
		
		super.init()
		
		view.setBPM(noHeart)
		view.setCurrentSetViewHidden(true)
		view.setRestViewHidden(true)
		view.setWorkoutDoneViewHidden(true)
		view.setNextUpTextHidden(true)
		
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = activityType
		configuration.locationType = isIndoor ? .indoor : .outdoor
		
		#if os(watchOS)
			do {
				session = try HKWorkoutSession(configuration: configuration)
				
				session.delegate = self
				healthStore.start(session)
			} catch {
				view.setWorkoutDoneText(NSLocalizedString("WORKOUT_START_ERR", comment: "Err starting"))
				view.setWorkoutDoneViewHidden(false)
			}
		#else
			start = self.start ?? Date()
		#endif
	}
	
	// MARK: - Workout Handling
	
	fileprivate func workoutSessionStarted(_ date: Date? = nil) {
		preferences.currentStart = start
		
		let heartUnit = HKUnit.count().unitDivided(by: .minute())
		let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
		let predicate = HKQuery.predicateForSamples(withStart: date ?? self.start, end: nil, options: [])
		let handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { _, samples, _, _, _ in
			if let last = (samples as? [HKQuantitySample])?.sorted(by: { (a, b) -> Bool in
				return a.startDate < b.startDate
			}).last {
				self.invalidateBPM?.invalidate()
				self.invalidateBPM = Timer.scheduledTimer(withTimeInterval: 3 * 60, repeats: false) { _ in
					DispatchQueue.main.async {
						self.view.setBPM(self.noHeart)
					}
				}
				DispatchQueue.main.async {
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
			
			self.displayStep()
		}
	}
	
	private func endWorkoutSession() {
		#if os(watchOS)
			healthStore.end(session)
		#else
			end = Date()
			workoutSessionEnded()
		#endif
	}
	
	fileprivate func workoutSessionEnded(doSave: Bool = true) {
		self.view.stopTimer()
		terminate()
		
		if terminateAndSave && doSave {
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
		invalidateBPM?.invalidate()
		invalidateBPM = nil
		restTimer?.invalidate()
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
		guard let curEx = exercizes.first else {
			endWorkout()
			return nil
		}
		
		if curEx.isRest {
			exercizes.remove(at: 0)
			curPart = 0
			
			preferences.currentExercize += 1
			preferences.currentPart = curPart
			
			return nil
		} else {
			var set: RepsSet?
			if curPart % 2 == 0 {
				set = curEx.set(n: Int32(curPart / 2))
			}
			
			let maxPart = 2 * curEx.sets.count - 1
			curPart += 1
			if curPart >= maxPart {
				exercizes.remove(at: 0)
				curPart = 0
				
				preferences.currentExercize += 1
			}
			
			preferences.currentPart = curPart
			
			return set
		}
	}
	
	private func displayStep() {
		guard let curEx = exercizes.first else {
			endWorkout()
			return
		}
		
		var setRest: TimeInterval?
		
		if curEx.isRest {
			setRest = curEx.rest
			view.setCurrentExercizeViewHidden(true)
		} else {
			view.setCurrentExercizeViewHidden(false)
			
			let setN = curPart / 2
			guard let set = curEx.set(n: Int32(setN)) else {
				nextStep()
				return
			}
			
			if curPart == 0 {
				// Reset add weight for new exercize
				addWeight = 0
			}
			
			let setInfoText = {
				self.view.setExercizeName(curEx.name ?? "")
				let otherSet = Array(curEx.setList.suffix(from: setN + 1))
				if otherSet.count > 0 {
					self.view.setOtherSetsText("\(otherSet.count)\(otherSet.count > 1 ? self.otherSetsTxt : self.otherSetTxt): " + otherSet.map { "\($0.weight.toString())kg" }.joined(separator: ", "))
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
				view.setSetDoneButtonHidden(false)
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
				nextStep()
				return
			}
			
			view.startRestTimer(for: restTime)
			view.setRestViewHidden(false)
			
			restTimer = Timer.scheduledTimer(withTimeInterval: restTime, repeats: false) { _ in
				self.view.stopRestTimer()
				self.view.notifyEndRest()
			}
			RunLoop.main.add(restTimer!, forMode: .commonModes)
		} else {
			view.stopRestTimer()
			view.setRestViewHidden(true)
		}
		
		view.notifyExercizeChange()
		isRestMode = setRest != nil
		
		if exercizes.count >= 2 {
			let txt: String
			let nextEx = exercizes[1]
			if nextEx.isRest {
				txt = nextEx.rest.getDuration(hideHours: true) + nextRestTxt
			} else {
				txt = nextEx.name!
			}
			view.setNextUpText(nextTxt + txt)
		} else {
			view.setNextUpText(nextTxt + nextEndTxt)
		}
	}
	
	func endRest() {
		guard isRestMode else {
			return
		}
		
		view.stopRestTimer()
		view.endNotifyEndRest()
		restTimer?.invalidate()
		restTimer = nil
		
		nextStep()
	}
	
	func endSet() {
		guard !isRestMode else {
			return
		}
		
		if let set = prepareNextStep() {
			// The next part has already been prepared so the current part is 0 only if the exercize has changed
			view.askUpdateWeight(with: UpdateWeightData(workoutController: self, set: set, sum: addWeight, saveAddWeight: curPart != 0))
		}
		displayStep()
	}
	
	func setAddWeight(_ add: Double) {
		addWeight = add
	}
	
	func endWorkout() {
		view.setCurrentExercizeViewHidden(true)
		view.setRestViewHidden(true)
		view.setNextUpTextHidden(true)
		
		view.setWorkoutDoneButtonEnabled(false)
		view.setWorkoutDoneText(NSLocalizedString("WORKOUT_SAVING", comment: "Saving..."))
		view.setWorkoutDoneViewHidden(false)
		
		endWorkoutSession()
	}
	
	private func saveWorkout() {
		let endTxt = hasTerminationError ? NSLocalizedString("WORKOUT_STOP_ERR", comment: "Err") + "\n" : ""
		dataManager.setRunningWorkout(nil, fromSource: source)
		
		let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
		let device = HKDevice.local()
		
		let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
		let devicePredicate = HKQuery.predicateForObjects(from: [device])
		let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
		let sortByDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		
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
			                        metadata: [HKMetadataKeyIndoorWorkout : self.isIndoor]
			)
			
			healthStore.save(workout, withCompletion: { success, _ in
				let complete = {
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
	
	func cancelWorkout() {
		self.terminateAndSave = false
		endWorkoutSession()
		terminate()
		dataManager.setRunningWorkout(nil, fromSource: source)
		view.exitWorkoutTracking()
	}
	
}

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
