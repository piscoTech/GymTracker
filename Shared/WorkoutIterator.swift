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
	func updateWeightChange()
	
}

class WorkoutStepNextSet: WorkoutStepNext {
	
	private(set) var description: NSAttributedString
	
	let exercizeName: String
	let weight: Double
	private(set) var change: Double
	
	private let changeProvider: () -> Double
	
	fileprivate init(exercizeName: String, weight: Double, change: @escaping () -> Double) {
		self.changeProvider = change
		
		self.exercizeName = exercizeName
		self.weight = weight
		self.change = changeProvider()
		
		self.description = NSAttributedString()
		
		self.generateString()
	}
	
	func updateWeightChange() {
		change = changeProvider()
		generateString()
	}
	
	private func generateString() {
		let d = NSMutableAttributedString(string: exercizeName)
		
		if let w = weight.weightDescription(withChange: change) {
			d.append(NSAttributedString(string: ", "))
			d.append(w)
			d.append(kg)
		}
		
		self.description = d
	}
	
}

class WorkoutStepNextRest: WorkoutStepNext {
	
	let description: NSAttributedString
	let rest: TimeInterval
	
	static private let nextRestTxt = NSLocalizedString("NEXT_EXERCIZE_REST", comment: "rest")
	
	fileprivate init(rest: TimeInterval) {
		self.rest = rest
		description = NSAttributedString(string: rest.getDuration(hideHours: true) + WorkoutStepNextRest.nextRestTxt)
	}
	
	func updateWeightChange() {}
	
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
	/// Whether this is the last step in the entire workout
	let isLast: Bool
	
	let nextUp: WorkoutStepNext?
	let set: RepsSet?
	
	var isRest: Bool {
		return exercizeName == nil && rest != nil
	}
	
	fileprivate init(rest: TimeInterval?, nextUp: WorkoutStepNext?, set: RepsSet?, isLast: Bool) {
		self.rest = rest
		self.nextUp = nextUp
		self.set = set
		self.isLast = isLast
	}
	
	func updateWeightChange() {
		nextUp?.updateWeightChange()
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

	private(set) var reps: WorkoutSetStepData

	private let exercize: String
	private var repsDescription: NSAttributedString
	
	private let changeProvider: () -> Double
	
	fileprivate init(exercizeName: String, reps: Int, weight: Double, change: @escaping () -> Double, rest: TimeInterval?, nextUp: WorkoutStepNext?, set: RepsSet, isLast: Bool) {
		self.exercize = exercizeName
		self.changeProvider = change
		self.reps = (reps, weight, change())
		self.repsDescription = NSAttributedString()
		
		super.init(rest: rest, nextUp: nextUp, set: set, isLast: isLast)
		
		self.generateString()
	}
	
	private func generateString() {
		let repsDescription = NSMutableAttributedString(string: "\(reps.reps)")
		if let w = reps.weight.weightDescription(withChange: reps.change) {
			repsDescription.append(NSAttributedString(string: timesSign))
			repsDescription.append(w)
			repsDescription.append(kg)
		}
		self.repsDescription = repsDescription
	}
	
	override func updateWeightChange() {
		super.updateWeightChange()
		
		self.reps.change = changeProvider()
		self.generateString()
	}
	
}

class WorkoutExercizeStep: WorkoutSetStep {

	override var otherPartsInfo: NSAttributedString? {
		return otherSets
	}
	
	let otherWeights: [Double]
	
	private var otherSets: NSAttributedString?
	
	static private let otherSetTxt = NSLocalizedString("OTHER_N_SET", comment: "other set")
	static private let otherSetsTxt = NSLocalizedString("OTHER_N_SETS", comment: "other sets")
	
	fileprivate init(exercizeName: String, reps: Int, weight: Double, change: @escaping () -> Double, rest: TimeInterval?, otherWeights other: [Double], nextUp: WorkoutStepNext?, set: RepsSet, isLast: Bool) {
		self.otherSets = NSAttributedString()
		self.otherWeights = other
		
		super.init(exercizeName: exercizeName, reps: reps, weight: weight, change: change, rest: rest, nextUp: nextUp, set: set, isLast: isLast)
		
		self.generateString()
	}
	
	func generateString() {
		if otherWeights.count > 0 {
			let otherSets = NSMutableAttributedString(string: "\(otherWeights.count)\(otherWeights.count > 1 ? WorkoutExercizeStep.otherSetsTxt : WorkoutExercizeStep.otherSetTxt): ")
			otherSets.append(otherWeights.map { weight -> NSAttributedString in
				let w = weight.weightDescriptionEvenForZero(withChange: reps.change)
				let res = NSMutableAttributedString(attributedString: w)
				res.append(kg)
				
				return res
				}.joined(separator: ", "))
			
			self.otherSets = otherSets
		} else {
			self.otherSets = nil
		}
	}
	
	override func updateWeightChange() {
		super.updateWeightChange()
		
		self.generateString()
	}
	
}

class WorkoutCircuitStep: WorkoutSetStep {

	typealias WorkoutCircuitStepData = (exercize: Int, totalExercizes: Int, round: Int, totalRounds: Int)
	
	override var otherPartsInfo: NSAttributedString? {
		return otherParts
	}
	
	let circuitCompletion: WorkoutCircuitStepData
	
	private let otherParts: NSAttributedString
	
	static private let exercize = NSLocalizedString("EXERCIZE", comment: "exercize")
	static private let round = NSLocalizedString("ROUND", comment: "round")

	fileprivate init(exercizeName: String, reps: Int, weight: Double, change: @escaping () -> Double, rest: TimeInterval?, circuitCompletion: WorkoutCircuitStepData, nextUp: WorkoutStepNext?, set: RepsSet, isLast: Bool) {
		self.otherParts = NSAttributedString(string: "\(WorkoutCircuitStep.exercize) \(circuitCompletion.exercize)/\(circuitCompletion.totalExercizes), \(WorkoutCircuitStep.round) \(circuitCompletion.round)/\(circuitCompletion.totalRounds)")
		self.circuitCompletion = circuitCompletion
		
		super.init(exercizeName: exercizeName, reps: reps, weight: weight, change: change, rest: rest, nextUp: nextUp, set: set, isLast: isLast)
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
		// A workout can never end with a rest
		super.init(rest: rest, nextUp: nextUp, set: nil, isLast: false)
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
	
	private var weightChanges: [CDRecordID : Double] = [:]
	
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
			for e in group {
				weightChanges[e.recordID] = 0
			}
		}
		
		exercizes = exGroups
	}
	
	// MARK: - Manage cache of weight changes
	
	func weightChange(for e: Exercize) -> Double {
		let id = e.recordID
		precondition(weightChanges.keys.contains(id), "Exercize does not belong the the workout")
		
		return weightChanges[id]!
	}
	
	func setWeightChange(_ w: Double, for e: Exercize) {
		let id = e.recordID
		precondition(weightChanges.keys.contains(id), "Exercize does not belong the the workout")
		
		weightChanges[id] = w.rounded(to: 0.5)
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
		preferences.weightChangeCache = weightChanges
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
		
		let cache = preferences.weightChangeCache
		for (e, w) in weightChanges {
			weightChanges[e] = cache[e]?.rounded(to: 0.5) ?? w
		}
	}
	
	func destroyPersistedState() {
		preferences.weightChangeCache = [:]
	}
	
	func next() -> WorkoutStep? {
		guard exercizes.count > curExercize else {
			return nil
		}
		
		func prepareNext(with e: Exercize, set: Int = 0) -> WorkoutStepNext {
			if e.isRest {
				return WorkoutStepNextRest(rest: e.rest)
			} else {
				return WorkoutStepNextSet(exercizeName: e.name ?? "", weight: e[Int32(set)]?.weight ?? 0, change: { self.weightChange(for: e) } )
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
				let eT = curGroup.count
				let eC = curPart % eT
				let rC = curPart / eT
				let e = curGroup[eC]
				let s = e[Int32(rC)]!
				let rT = e.sets.count
				var next: WorkoutStepNext?
				
				let isLastRound = rC + 1 == rT
				let isLast: Bool
				if eC + 1 == eT && isLastRound {
					isLast = true
					curPart = 0
					curExercize += 1
				} else {
					isLast = false
					curPart += 1
				}
				let (globalRest, lastRest) = workout.restStatus(for: e) ?? (false, false)
				let rest = (isLast && lastRest) || (!isLast && globalRest) ? s.rest : nil
				if !isLast {
					let nE = curPart % eT
					let nR = curPart / eT
					next = prepareNext(with: curGroup[nE], set: nR)
				} else if curExercize < exercizes.count {
					next = prepareNext(with: exercizes[curExercize][0])
				}
				
				return WorkoutCircuitStep(exercizeName: e.name ?? "", reps: Int(s.reps), weight: s.weight, change: { self.weightChange(for: e) },
										  rest: (rest ?? 0) > 0 ? rest : nil, circuitCompletion: (eC + 1, eT, rC + 1, rT), nextUp: next, set: s, isLast: isLast && next == nil)
			} else { // Single exercize
				let e = curGroup[0]
				let s = e[Int32(curPart)]!
				let isLast = curPart == e.sets.count - 1
				var next: WorkoutStepNext?
				
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
				return WorkoutExercizeStep(exercizeName: e.name ?? "", reps: Int(s.reps), weight: s.weight, change: { self.weightChange(for: e) },
										   rest: (rest ?? 0) > 0 ? rest : nil, otherWeights: others, nextUp: next, set: s, isLast: isLast && next == nil)
			}
		}
	}
	
}
