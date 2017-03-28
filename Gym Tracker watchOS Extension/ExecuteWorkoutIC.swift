//
//  ExecuteWorkoutInterfaceController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 24/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import HealthKit
import Foundation

class ExecuteWorkoutInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
	
	@IBOutlet weak var timerLbl: WKInterfaceTimer!
	@IBOutlet weak var bpmLbl: WKInterfaceLabel!
	
	@IBOutlet weak var currentSetGrp: WKInterfaceGroup!
	@IBOutlet weak var exercizeNameLbl: WKInterfaceLabel!
	@IBOutlet weak var currentSetInfoGrp: WKInterfaceGroup!
	@IBOutlet weak var setRepWeightLbl: WKInterfaceLabel!
	@IBOutlet weak var otherSetsLbl: WKInterfaceLabel!
	@IBOutlet weak var doneSetBtn: WKInterfaceButton!
	
	@IBOutlet weak var restGrp: WKInterfaceGroup!
	
	@IBOutlet weak var restLbl: WKInterfaceTimer!
	@IBOutlet weak var nextUpLbl: WKInterfaceLabel!
	
	@IBOutlet weak var workoutDoneGrp: WKInterfaceGroup!
	@IBOutlet weak var workoutDoneLbl: WKInterfaceLabel!
	@IBOutlet weak var workoutDoneBtn: WKInterfaceButton!
	
	private let noHeart = "– –"
	private let nextTxt = NSLocalizedString("NEXT_EXERCIZE_FLAG", comment: "Next:")
	private let nextEndTxt = NSLocalizedString("NEXT_EXERCIZE_END", comment: "End")
	private let nextRestTxt = NSLocalizedString("NEXT_EXERCIZE_REST", comment: "rest")
	private let otherSetTxt = NSLocalizedString("OTHER_N_SET", comment: "other set")
	private let otherSetsTxt = NSLocalizedString("OTHER_N_SETS", comment: "other sets")
	
	private var workout: Workout!
	private var start: Date!
	private var end: Date!
	private var exercizes: [Exercize]!
	private var curPart = 0
	private var isRestMode = false
	private var restTimer: Timer?
	var addWeight = 0.0
	
	private var session: HKWorkoutSession!
	private var heartQuery: HKAnchoredObjectQuery!
	private var invalidateBPM: Timer!
	private var workoutEvents = [HKWorkoutEvent]()
	private var hasTerminationError = false
	private var terminateAndSave = true
	
	override func awake(withContext context: Any?) {
        super.awake(withContext: context)
		
		guard let workout = context as? Workout else {
			appDelegate.restoredefaultState()
			return
		}
		
		appDelegate.executeWorkout = self
		self.workout = workout
        dataManager.setRunningWorkout(workout, fromSource: .watch)
		
		exercizes = workout.exercizeList
		
		bpmLbl.setText(noHeart)
		currentSetGrp.setHidden(true)
		restGrp.setHidden(true)
		workoutDoneGrp.setHidden(true)
		nextUpLbl.setHidden(true)
		
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = .traditionalStrengthTraining
		configuration.locationType = .indoor
		
		do {
			session = try HKWorkoutSession(configuration: configuration)
			
			session.delegate = self
			healthStore.start(session)
		} catch {
			workoutDoneLbl.setText(NSLocalizedString("WORKOUT_START_ERR", comment: "Err starting"))
			workoutDoneGrp.setHidden(false)
		}
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		if fromState == .notStarted && toState == .running {
			start = date
			
			let heartUnit = HKUnit.count().unitDivided(by: .minute())
			let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
			let predicate = HKQuery.predicateForSamples(withStart: date, end: nil, options: [])
			let handler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { _, samples, _, _, _ in
				if let last = (samples as? [HKQuantitySample])?.sorted(by: { (a, b) -> Bool in
					return a.startDate < b.startDate
				}).last {
					self.invalidateBPM?.invalidate()
					self.invalidateBPM = Timer.scheduledTimer(withTimeInterval: 3 * 60, repeats: false) { _ in
						DispatchQueue.main.async {
							self.bpmLbl.setText(self.noHeart)
						}
					}
					DispatchQueue.main.async {
						RunLoop.main.add(self.invalidateBPM!, forMode: .commonModes)
						self.bpmLbl.setText(last.quantity.doubleValue(for: heartUnit).rounded().toString())
					}
				}
			}
			heartQuery = HKAnchoredObjectQuery(type: heartRate, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: handler)
			heartQuery.updateHandler = handler
			healthStore.execute(heartQuery)
			
			DispatchQueue.main.async {
				self.timerLbl.setDate(date)
				self.timerLbl.start()
				self.nextUpLbl.setHidden(false)
				
				self.nextStep(true)
			}
		}
		if toState == .ended {
			end = date
			timerLbl.stop()
			if let heart = heartQuery {
				healthStore.stop(heart)
			}
			invalidateBPM?.invalidate()
			restTimer?.invalidate()
			
			if terminateAndSave && (fromState == .running || fromState == .paused) {
				DispatchQueue.main.async {
					self.saveWorkout()
				}
			}
		}
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		hasTerminationError = true
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
		workoutEvents.append(event)
	}
	
	private func nextStep(_ isInitialSetup: Bool = false) {
		if !isInitialSetup {
			guard let curEx = exercizes.first else {
				endWorkout()
				return
			}
			
			if curEx.isRest {
				exercizes.remove(at: 0)
				curPart = 0
			} else {
				let maxPart = 2 * curEx.sets.count - 1
				curPart += 1
				if curPart >= maxPart {
					exercizes.remove(at: 0)
					curPart = 0
				}
			}
		}
		
		guard let curEx = exercizes.first else {
			endWorkout()
			return
		}
		
		var setRest: TimeInterval?
		
		if curEx.isRest {
			setRest = curEx.rest
			currentSetGrp.setHidden(true)
		} else {
			currentSetGrp.setHidden(false)
			
			let setN = curPart / 2
			guard let set = curEx.set(n: Int32(setN)) else {
				nextStep()
				return
			}
			
			if curPart == 0 {
				// Reset add weight for new exercize
				addWeight = 0
			}
			
			if curPart % 2 == 0 {
				setRest = nil
				exercizeNameLbl.setText(curEx.name)
				setRepWeightLbl.setText(set.description)
				
				let otherSet = Array(curEx.setList.suffix(from: setN + 1))
				if otherSet.count > 0 {
					otherSetsLbl.setText("\(otherSet.count)\(otherSet.count > 1 ? otherSetsTxt : otherSetTxt): " + otherSet.map { "\($0.weight.toString())kg" }.joined(separator: ", "))
					otherSetsLbl.setHidden(false)
				} else {
					otherSetsLbl.setHidden(true)
				}
				
				currentSetInfoGrp.setHidden(false)
				doneSetBtn.setHidden(false)
			} else {
				setRest = set.rest
				currentSetInfoGrp.setHidden(true)
				doneSetBtn.setHidden(true)
			}
		}
		
		if let restTime = setRest {
			guard restTime > 0 else {
				// A rest time of 0:00 is allowed between sets, jump to next set
				nextStep()
				return
			}
			
			restLbl.setDate(Date().addingTimeInterval(restTime))
			restLbl.start()
			restGrp.setHidden(false)
			
			restTimer = Timer.scheduledTimer(withTimeInterval: restTime, repeats: false) { _ in
				self.restLbl.stop()
				let sound = WKHapticType.stop
				WKInterfaceDevice.current().play(sound)
				DispatchQueue.main.async {
					self.restTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
						WKInterfaceDevice.current().play(sound)
					}
					RunLoop.main.add(self.restTimer!, forMode: .commonModes)
				}
				
			}
			RunLoop.main.add(restTimer!, forMode: .commonModes)
		} else {
			restLbl.stop()
			restGrp.setHidden(true)
		}
		
		if !isInitialSetup {
			WKInterfaceDevice.current().play(.click)
		}
		isRestMode = setRest != nil
		
		if exercizes.count >= 2 {
			let txt: String
			let nextEx = exercizes[1]
			if nextEx.isRest {
				txt = nextEx.rest.getDuration(hideHours: true) + nextRestTxt
			} else {
				txt = nextEx.name!
			}
			nextUpLbl.setText(nextTxt + txt)
		} else {
			nextUpLbl.setText(nextTxt + nextEndTxt)
		}
	}
	
	@IBAction func endRest() {
		guard isRestMode else {
			return
		}
		
		restLbl.stop()
		restTimer?.invalidate()
		restTimer = nil
		
		nextStep()
	}
	
	@IBAction func endSet() {
		guard !isRestMode else {
			return
		}
		
		if let curEx = exercizes.first, !curEx.isRest, let set = curEx.set(n: Int32(curPart / 2)) {
			let maxPart = 2 * curEx.sets.count - 1
			presentController(withName: "updateWeight", context: UpdateWeightData(workoutController: self, set: set, sum: addWeight, saveAddWeight: curPart < maxPart - 1))
		}
		nextStep()
	}
	
	@IBAction func endWorkout() {
		currentSetGrp.setHidden(true)
		restGrp.setHidden(true)
		nextUpLbl.setHidden(true)
		
		workoutDoneBtn.setEnabled(false)
		workoutDoneLbl.setText(NSLocalizedString("WORKOUT_SAVING", comment: "Saving..."))
		workoutDoneGrp.setHidden(false)
		
		healthStore.end(self.session)
	}
	
	private func saveWorkout() {
		let endTxt = hasTerminationError ? NSLocalizedString("WORKOUT_STOP_ERR", comment: "Err") + "\n" : ""
		dataManager.setRunningWorkout(nil, fromSource: .watch)
		
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
			
			let workout = HKWorkout(activityType: self.session.workoutConfiguration.activityType,
				start: self.start,
				end: self.end,
				duration: self.end.timeIntervalSince(self.start),
				totalEnergyBurned: totalEnergy,
				totalDistance: nil,
				device: HKDevice.local(),
				metadata: [HKMetadataKeyIndoorWorkout : true]
			)
			
			healthStore.save(workout, withCompletion: { success, _ in
				let complete = {
					self.workoutDoneBtn.setEnabled(true)
					if success {
						self.workoutDoneLbl.setText(endTxt + NSLocalizedString("WORKOUT_SAVED", comment: "Saved"))
					} else {
						self.workoutDoneLbl.setText(endTxt + NSLocalizedString("WORKOUT_SAVE_ERROR", comment: "Error"))
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
	
	@IBAction func cancelWorkout() {
		self.terminateAndSave = false
		healthStore.end(self.session)
		dataManager.setRunningWorkout(nil, fromSource: .watch)
		exitWorkout()
	}
	
	@IBAction func exitWorkout() {
		appDelegate.restoredefaultState()
	}

}
