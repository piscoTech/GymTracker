//
//  WorkoutIterator.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import MBLibrary

fileprivate let kg = NSAttributedString(string: "kg")

protocol WorkoutStepNext {
	
	var description: NSAttributedString { get }
	
}

struct WorkoutStepNextSet: WorkoutStepNext {
	
	let description: NSAttributedString
	
	let exercizeName: String
	let weight, change: Double
	
	fileprivate init(exercizeName: String, weight: Double, change: Double) {
		self.exercizeName = exercizeName
		self.weight = weight
		self.change = change
		
		let d = NSMutableAttributedString(string: exercizeName)
		
		if let w = weight.weightDescription(withChange: change) {
			d.append(NSAttributedString(string: ", "))
			d.append(w)
			d.append(kg)
		}
		
		description = d
	}
	
}

struct WorkoutStepNextRest: WorkoutStepNext {
	
	let description: NSAttributedString
	let rest: TimeInterval
	
	static private let nextRestTxt = NSLocalizedString("NEXT_EXERCIZE_REST", comment: "rest")
	
	fileprivate init(rest: TimeInterval) {
		self.rest = rest
		description = NSAttributedString(string: rest.getDuration(hideHours: true) + WorkoutStepNextRest.nextRestTxt)
	}
	
}

class WorkoutStep {
	
	/// The name of the current exercize, `nil` if a rest period.
	var exercizeName: String? {
		fatalError("Not implemented")
	}
	/// The number of reps and weight for the current set, `nil` if a rest period.
	var currentReps: NSAttributedString? {
		fatalError("Not implemented")
	}
	/// Other sets weight for a normal exercize or circuit progress.
	///
	/// For a normal exercize looks like *2 other sets: 10kg, 12kg* or `nil` on the last set and for a rest period.
	///
	/// For a circuit looks like *Exercize 2/4, round 2/4*.
	var otherPartsInfo: NSAttributedString? {
		fatalError("Not implemented")
	}
	/// Rest time for the current set or rest period.
	let rest: TimeInterval?
	/// Exercize name and weight for the next set, `nil` if at the last set.
	var nextUpInfo: NSAttributedString? {
		return nextUp?.description
	}
	
	let nextUp: WorkoutStepNext?
	let set: RepsSet?
	
	var isRest: Bool {
		return exercizeName == nil && rest != nil
	}
	
	fileprivate init(rest: TimeInterval?, nextUp: WorkoutStepNext?, set: RepsSet?) {
		self.rest = rest
		self.nextUp = nextUp
		self.set = set
	}
	
	func updateWeightChange(for iterator: WorkoutIterator) {
		fatalError("Not implemented")
	}
	
}

class WorkoutSetStep: WorkoutStep {
	
	typealias WorkoutSetStepData = (reps: Int, weight: Double, change: Double)
	
	override var exercizeName: String? {
		return exercize
	}
	override var currentReps: NSAttributedString? {
		return repsDescription
	}

	let reps: WorkoutSetStepData

	private let exercize: String
	private let repsDescription: NSAttributedString
	
	fileprivate init(exercizeName: String, reps: WorkoutSetStepData, rest: TimeInterval?, nextUp: WorkoutStepNext?, set: RepsSet) {
		self.exercize = exercizeName
		self.reps = reps
		
		let repsDescription = NSMutableAttributedString(string: "\(reps.reps)")
		if let w = reps.weight.weightDescription(withChange: reps.change) {
			repsDescription.append(NSAttributedString(string: timesSign))
			repsDescription.append(w)
		}
		self.repsDescription = repsDescription
		
		super.init(rest: rest, nextUp: nextUp, set: set)
	}
	
}

class WorkoutExercizeStep: WorkoutSetStep {

	override var otherPartsInfo: NSAttributedString? {
		return otherSets
	}
	
	let otherWeights: [Double]
	
	private let otherSets: NSAttributedString?
	
	static private let otherSetTxt = NSLocalizedString("OTHER_N_SET", comment: "other set")
	static private let otherSetsTxt = NSLocalizedString("OTHER_N_SETS", comment: "other sets")
	
	fileprivate init(exercizeName: String, reps: WorkoutSetStepData, rest: TimeInterval?, otherWeights other: [Double], nextUp: WorkoutStepNext?, set: RepsSet) {
		if other.count > 0 {
			let otherSets = NSMutableAttributedString(string: "\(other.count)\(other.count > 1 ? WorkoutExercizeStep.otherSetsTxt : WorkoutExercizeStep.otherSetTxt): ")
			otherSets.append(other.flatMap { weight -> NSAttributedString? in
				guard let w = weight.weightDescription(withChange: reps.change) else {
					return nil
				}
				
				let res = NSMutableAttributedString(attributedString: w)
				res.append(kg)
				
				return res
				}.joined(separator: ", "))
			
			self.otherSets = otherSets
		} else {
			self.otherSets = nil
		}
		self.otherWeights = other
		
		super.init(exercizeName: exercizeName, reps: reps, rest: rest, nextUp: nextUp, set: set)
	}
	
}

class WorkoutCircuitStep: WorkoutSetStep {

	typealias WorkoutCircuitStepData = (exercize: Int, totalExercize: Int, round: Int, totalRound: Int)
	
	override var otherPartsInfo: NSAttributedString? {
		return otherParts
	}
	
	let circuitCompletion: WorkoutCircuitStepData
	
	private let otherParts: NSAttributedString
	
	static private let exercize = NSLocalizedString("EXERCIZE", comment: "exercize")
	static private let round = NSLocalizedString("ROUND", comment: "round")

	fileprivate init(exercizeName: String, reps: WorkoutSetStepData, rest: TimeInterval?, circuitCompletion: WorkoutCircuitStepData, nextUp: WorkoutStepNext?, set: RepsSet) {
		self.otherParts = NSAttributedString(string: "\(WorkoutCircuitStep.exercize) \(circuitCompletion.exercize)/\(circuitCompletion.totalExercize), \(WorkoutCircuitStep.round) \(circuitCompletion.round)/\(circuitCompletion.totalRound)")
		self.circuitCompletion = circuitCompletion
		
		super.init(exercizeName: exercizeName, reps: reps, rest: rest, nextUp: nextUp, set: set)
	}
	
}

class WorkoutRestStep: WorkoutStep {
	
	override var exercizeName: String? {
		return nil
	}
	override var currentReps: NSAttributedString? {
		return nil
	}
	override var otherPartsInfo: NSAttributedString? {
		return nil
	}
	
	init(rest: TimeInterval, nextUp: WorkoutStepNext) {
		super.init(rest: rest, nextUp: nextUp, set: nil)
	}
}

/// Iterates over a workout.
///
/// Before creation make sure that the workout is valid and every settings is valid by calling `purgeInvalidSettings()`.
///
/// After creation make sure not to change the structure of workout, i.e. how exercizes and sets are ordered and arranged in circuit, after creation, weight update is fine. Any change in exercize arrangement will not be reflected, change in number of sets can result in unexpected behaviour.
class WorkoutIterator: IteratorProtocol {
	
	let workout: OrganizedWorkout
	
	private let exercizes: [[Exercize]]
	/// The current exercize, rest or circuit.
	private var curExercize = 0
	/// The current part, i.e. set, inside the current exercize or circuit, this identifies both the set and, if any, its subsequent rest period.
	private var curPart = 0
	
	private let preferences: Preferences

	init(_ w: OrganizedWorkout, using preferences: Preferences? = nil) {
		workout = w
		self.preferences = preferences ?? appDelegate.dataManager.preferences
		guard w.validityStatus.global else {
			exercizes = []
			return
		}
		
		var list = w.exercizes
		var exGroups = [[Exercize]]()
		
		while let e = list.first {
			let group: [Exercize]
			if let (_, t) = w.circuitStatus(for: e) {
				// This will always be called for the first exercize in a circuit
				group = Array(list.prefix(t))
			} else {
				group = [e]
			}
			
			exGroups.append(group)
			list.removeFirst(group.count)
		}
		
		exercizes = exGroups
	}
	
	// MARK: - Manage cache of weight changes
	
	func weightChange(for e: Exercize) -> Double {
		return 0
	}
	
	// MARK: - Manage steps
	
	/// Save the state of the iterator so that after reloading it the first call to `next()` will give the same result as the last one before saving.
	func persistState() {
		var e = curExercize
		var p = curPart - 1
		if p < 0 {
			if e > 0 {
				e -= 1
				let eGroup = exercizes[e]
				p = eGroup[0].isRest ? 0 : eGroup.count * eGroup[0].sets.count - 1
			} else {
				p = 0
			}
		}
		
		preferences.currentExercize = e
		preferences.currentPart = p
		// TODO: Also save weight change cache
	}
	
	func loadPersistedState() {
		curExercize = max(0, preferences.currentExercize)
		curPart = max(0, preferences.currentPart)
		
		if curExercize < exercizes.count { // The saved status is mid workout
			let eGroup = exercizes[curExercize]
			let maxPart = eGroup[0].isRest ? 0 : eGroup.count * eGroup[0].sets.count - 1
			if curPart > maxPart { // Current part exceeds the limit, jump to next exercize
				curExercize += 1
				curPart = 0
			}
		}
		
		// TODO: Also load weight change cache
	}
	
	func next() -> WorkoutStep? {
		guard exercizes.count > curExercize else {
			return nil
		}
		
		func prepareNext(with e: Exercize, set: Int = 0) -> WorkoutStepNext {
			if e.isRest {
				return WorkoutStepNextRest(rest: e.rest)
			} else {
				return WorkoutStepNextSet(exercizeName: e.name ?? "", weight: e[Int32(set)]?.weight ?? 0, change: self.weightChange(for: e))
			}
		}
		
		let curGroup = exercizes[curExercize]
		if curGroup[0].isRest { // Rest period
			curExercize += 1
			curPart = 0
			// Here we assume the workout is valid and unused data is purged, i.e. after a rest there is always another exercize
			return WorkoutRestStep(rest: curGroup[0].rest, nextUp: prepareNext(with: exercizes[curExercize][0]))
		} else { // Set
			if curGroup.count > 1 { // Circuit
				return nil
			} else { // Single exercize
				let e = curGroup[0]
				let s = e[Int32(curPart)]!
				let isLast = curPart == e.sets.count - 1
				var next: WorkoutStepNext?
				
				let reps = WorkoutSetStep.WorkoutSetStepData(reps: Int(s.reps), s.weight, weightChange(for: e))
				let (globalRest, lastRest) = workout.restStatus(for: e) ?? (false, false)
				let rest = (isLast && lastRest) || (!isLast && globalRest) ? s.rest : nil
				let others = e.setList[(curPart + 1)...].map { $0.weight }
				if curExercize + 1 < exercizes.count {
					next = prepareNext(with: exercizes[curExercize + 1][0])
				}
				
				if isLast {
					curPart = 0
					curExercize += 1
				} else {
					curPart += 1
				}
				return WorkoutExercizeStep(exercizeName: e.name ?? "", reps: reps, rest: (rest ?? 0) > 0 ? rest : nil, otherWeights: others, nextUp: next, set: s)
			}
		}
	}
	
}
