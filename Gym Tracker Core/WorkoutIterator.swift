//
//  WorkoutIterator.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

protocol WorkoutStepNext {
	
	var description: NSAttributedString { get }
	func updateSecondaryInfoChange()
	
}

class WorkoutStepNextSet: WorkoutStepNext {
	
	private(set) var description: NSAttributedString
	
	let exercizeName: String
	let secondaryInfo: Double
	private(set) var change: Double
	let secondaryInfoLabel: NSAttributedString
	
	private let changeProvider: () -> Double
	
	fileprivate init(exercizeName: String, addInfo: Double, change: @escaping @autoclosure () -> Double, addInfoLabel: NSAttributedString) {
		self.changeProvider = change
		
		self.exercizeName = exercizeName
		self.secondaryInfo = addInfo
		self.change = changeProvider()
		self.secondaryInfoLabel = addInfoLabel
		
		self.description = NSAttributedString()
		
		self.generateString()
	}
	
	func updateSecondaryInfoChange() {
		change = changeProvider()
		generateString()
	}
	
	private func generateString() {
		let d = NSMutableAttributedString(string: exercizeName)
		
		if let w = secondaryInfo.secondaryInfoDescription(withChange: change) {
			d.append(NSAttributedString(string: ", "))
			d.append(w)
			d.append(secondaryInfoLabel)
		}
		
		self.description = d
	}
	
}

class WorkoutStepNextRest: WorkoutStepNext {
	
	let description: NSAttributedString
	let rest: TimeInterval
	
	static private let nextRestTxt = GTLocalizedString("NEXT_EXERCIZE_REST", comment: "rest")
	
	fileprivate init(rest: TimeInterval) {
		self.rest = rest
		description = NSAttributedString(string: String(format: Self.nextRestTxt, rest.getFormattedDuration()))
	}
	
	func updateSecondaryInfoChange() {}
	
}

public class WorkoutStep {
	
	/// The name of the current exercize, `nil` if a rest period.
	var exercizeName: String? {
		fatalError("Abstract property not implemented")
	}
	/// The info for the current set, i.e. reps and weight, `nil` if a rest period.
	var currentInfo: NSAttributedString? {
		fatalError("Abstract property not implemented")
	}
	/// Other sets weight for a normal exercize or circuit progress.
	///
	/// For a normal exercize looks like *2 other sets: 10kg, 12kg* or `nil` on the last set and for a rest period.
	///
	/// For a circuit looks like *Exercize 2/4, round 2/4*.
	var otherPartsInfo: NSAttributedString? {
		fatalError("Abstract property not implemented")
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
	let set: GTSet?
	
	var isRest: Bool {
		return exercizeName == nil && rest != nil
	}
	
	fileprivate init(rest: TimeInterval?, nextUp: WorkoutStepNext?, set: GTSet?, isLast: Bool) {
		self.rest = rest
		self.nextUp = nextUp
		self.set = set
		self.isLast = isLast
	}
	
	func updateSecondaryInfoChange() {
		nextUp?.updateSecondaryInfoChange()
	}
	
}

class WorkoutSetStep: WorkoutStep {
	
	override var exercizeName: String? {
		return exercize
	}
	override var currentInfo: NSAttributedString? {
		return mainDescription
	}

	private let exercize: String
	private var mainDescription: NSAttributedString
	
	private(set) var change: Double
	private let changeProvider: () -> Double
	
	fileprivate init(exercizeName: String, set: GTSet, change: @escaping () -> Double, rest: TimeInterval?, nextUp: WorkoutStepNext?, isLast: Bool) {
		self.exercize = exercizeName
		self.changeProvider = change
		self.change = change()
		self.mainDescription = set.mainInfoDescription(with: self.change)
		
		super.init(rest: rest, nextUp: nextUp, set: set, isLast: isLast)
	}
	
	override func updateSecondaryInfoChange() {
		super.updateSecondaryInfoChange()
		
		self.change = changeProvider()
		if let s = set {
			self.mainDescription = s.mainInfoDescription(with: self.change)
		}
	}
	
}

class WorkoutExercizeStep: WorkoutSetStep {
	
	typealias Other = (info: Double, label: NSAttributedString)

	override var otherPartsInfo: NSAttributedString? {
		return otherSets
	}
	
	let others: [Other]
	
	private var otherSets: NSAttributedString?
	
	static private let otherSetsTxt = GTLocalizedString("OTHER_%lld_SETS", comment: "other set(s)")
	
	fileprivate init(exercizeName: String, set: GTSet, change: @escaping @autoclosure () -> Double, rest: TimeInterval?, others: [Other], nextUp: WorkoutStepNext?, isLast: Bool) {
		self.otherSets = NSAttributedString()
		self.others = others
		
		super.init(exercizeName: exercizeName, set: set, change: change, rest: rest, nextUp: nextUp, isLast: isLast)
		
		self.generateString()
	}
	
	func generateString() {
		if others.count > 0 {
			let otherSets = NSMutableAttributedString(string: String(format: Self.otherSetsTxt, others.count))
			otherSets.append(others.map { i, l -> NSAttributedString in
				let iDesc = i.secondaryInfoDescriptionEvenForZero(withChange: change)
				let res = NSMutableAttributedString(attributedString: iDesc)
				res.append(l)
				
				return res
				}.joined(separator: ", "))
			
			self.otherSets = otherSets
		} else {
			self.otherSets = nil
		}
	}
	
	override func updateSecondaryInfoChange() {
		super.updateSecondaryInfoChange()
		
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
	
	static private let progress = GTLocalizedString("CIRCUIT_PROGRESS", comment: "Ex x/y, Round z/w")

	fileprivate init(exercizeName: String, set: GTSet, change: @escaping @autoclosure () -> Double, rest: TimeInterval?, circuitCompletion: WorkoutCircuitStepData, nextUp: WorkoutStepNext?, isLast: Bool) {
		self.otherParts = NSAttributedString(
			string: String(format: Self.progress,
						   circuitCompletion.exercize, circuitCompletion.totalExercizes,
						   circuitCompletion.round, circuitCompletion.totalRounds)
		)
		self.circuitCompletion = circuitCompletion
		
		super.init(exercizeName: exercizeName, set: set, change: change, rest: rest, nextUp: nextUp, isLast: isLast)
	}
	
}

class WorkoutRestStep: WorkoutStep {
	
	override var exercizeName: String? {
		return nil
	}
	override var currentInfo: NSAttributedString? {
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
public class WorkoutIterator: IteratorProtocol {
	
	let workout: GTWorkout
	
	private let exercizes: [[GTPart]]
	/// The current exercize, rest or circuit.
	private var curExercize = 0
	/// The current part, i.e. set, inside the current exercize or circuit, this identifies both the set and, if any, its subsequent rest period.
	private var curPart = 0
	
	private var secondaryInfoChanges: [CDRecordID : Double]
	
	private let preferences: Preferences

	init?(_ w: GTWorkout, choices: [Int32], using preferences: Preferences) {
		workout = w
		self.preferences = preferences
		guard w.isValid else {
			return nil
		}
		
		var chCount: Int = 0
		var parts = [[GTPart]]()
		
		for p in w.exercizeList {
			if p is GTRest {
				parts.append([p])
			} else if p is GTSimpleSetsExercize {
				parts.append([p])
			} else if let choice = p as? GTChoice {
				guard choices.count > chCount, let e = choice[choices[chCount]] else {
					return nil
				}
				chCount += 1
				parts.append([e])
			} else if let circuit = p as? GTCircuit {
				do {
					let group = try circuit.exercizeList.map { e -> GTPart in
						if let choice = e as? GTChoice {
							guard choices.count > chCount, let e = choice[choices[chCount]] else {
								throw GTError.generic
							}
							chCount += 1
							return e
						} else if e is GTSimpleSetsExercize {
							return e
						}
						
						throw GTError.generic
					}
					parts.append(group)
				} catch _ {
					return nil
				}
			} else {
				return nil
			}
		}

		guard chCount == choices.count else {
			return nil
		}
		
		preferences.currentChoices = choices
		exercizes = parts
		let realEx = exercizes.joined().compactMap { ($0 as? GTExercize)?.recordID }
		secondaryInfoChanges = Dictionary(uniqueKeysWithValues: zip(realEx, [Double](repeating: 0, count: realEx.count)))
	}
	
	// MARK: - Manage cache of secondary info changes
	
	public func isManaging(_ p: GTPart) -> Bool {
		return exercizes.contains { $0.contains(p) }
	}
	
	/// Fetch the secondary info change for the given exercize.
	/// - returns: The secondary info change for the given exercize ignoring the workout progress.
	func secondaryInfoChange(for e: GTSimpleSetsExercize) -> Double {
		let id = e.recordID
		let masterW = exercizes[0][0].parentHierarchy.compactMap { $0 as? GTWorkout }.first
		let curW = e.parentHierarchy.compactMap { $0 as? GTWorkout }.first
		precondition(masterW == curW, "Exercize does not belong to the workout")
		
		return secondaryInfoChanges[id] ?? 0
	}
	
	/// Fetch the secondary info change for the given set.
	/// - returns: The secondary info change for the given set if not yet completed, `0` otherwise, and whether the set is the current one.
	func secondaryInfoChange(for s: GTSet) -> (change: Double, current: Bool) {
		let change = secondaryInfoChange(for: s.exercize)
		
		guard let (n, group) = exercizes.enumerated().first(where: { $1.contains(s.exercize) }) else {
			preconditionFailure("Set does not belong to the workout")
		}
		
		let sOrder = Int(s.order)
		let (curE, curP) = currentState()
		if n < curE {
			return (0, false)
		} else if n > curE {
			return (change, false)
		} else if group.count == 1 { // Set belongs to the current exercize (single)
			if sOrder < curP {
				return (0, false)
			} else {
				return (change, sOrder == curP)
			}
		} else { // Set belongs to the current circuit
			let sPart = sOrder * group.count + Int(s.exercize.order)
			
			if sPart < curP {
				return (0, false)
			} else {
				return (change, sPart == curP)
			}
		}
	}
	
	func setSecondaryInfoChange(_ c: Double, for e: GTSimpleSetsExercize) {
		let id = e.recordID
		precondition(secondaryInfoChanges.keys.contains(id), "Exercize does not belong to the workout")
		
		secondaryInfoChanges[id] = c.rounded(to: 0.5)
	}
	
	// MARK: - Manage steps
	
	private func currentState() -> (exercize: Int, part: Int) {
		var e = curExercize
		var p = curPart - 1
		if p < 0 {
			if e > 0 {
				e -= 1
				let eGroup = exercizes[e]
				if let se = eGroup.first as? GTSimpleSetsExercize {
					p = eGroup.count * se.sets.count - 1
				} else {
					p = 0
				}
			} else {
				p = 0
			}
		}
		
		return (e, p)
	}
	
	/// Save the state of the iterator so that after reloading it the first call to `next()` will give the same result as the last one before saving.
	func persistState() {
		let (e, p) = currentState()
		
		preferences.currentExercize = e
		preferences.currentPart = p
		preferences.secondaryInfoChangeCache = secondaryInfoChanges
	}
	
	func loadPersistedState() {
		curExercize = max(0, preferences.currentExercize)
		curPart = max(0, preferences.currentPart)
		
		if curExercize < exercizes.count { // The saved status is mid workout
			let eGroup = exercizes[curExercize]
			let maxPart: Int
			if let se = eGroup.first as? GTSimpleSetsExercize {
				maxPart = eGroup.count * se.sets.count - 1
			} else {
				maxPart = 0
			}
			if curPart > maxPart { // Current part exceeds the limit, jump to next exercize
				curExercize += 1
				curPart = 0
			}
		}
		
		let cache = preferences.secondaryInfoChangeCache
		for (e, w) in secondaryInfoChanges {
			secondaryInfoChanges[e] = cache[e]?.rounded(to: 0.5) ?? w
		}
	}
	
	func destroyPersistedState() {
		preferences.secondaryInfoChangeCache = [:]
	}
	
	public func next() -> WorkoutStep? {
		guard exercizes.count > curExercize else {
			return nil
		}
		
		func prepareNext(with p: GTPart, set: Int = 0) -> WorkoutStepNext {
			if let r = p as? GTRest {
				return WorkoutStepNextRest(rest: r.rest)
			} else {
				let e = p as! GTSimpleSetsExercize
				let set = e[Int32(set)]
				
				return WorkoutStepNextSet(exercizeName: e.name, addInfo: set?.secondaryInfo ?? 0, change: self.secondaryInfoChange(for: e), addInfoLabel: set?.secondaryInfoLabel ?? NSAttributedString())
			}
		}
		
		let curGroup = exercizes[curExercize]
		if let rest = curGroup.first as? GTRest { // Rest period
			curExercize += 1
			curPart = 0
			// Here we assume the workout is valid and unused data is purged, i.e. after a rest there is always another exercize
			return WorkoutRestStep(rest: rest.rest, nextUp: prepareNext(with: exercizes[curExercize][0]))
		} else { // Set
			if curGroup.count > 1 { // Circuit
				let eT = curGroup.count
				let eC = curPart % eT
				let rC = curPart / eT
				let e = curGroup[eC] as! GTSimpleSetsExercize
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
				let (globalRest, lastRest) = e.restStatus
				let rest = (isLast && lastRest) || (!isLast && globalRest) ? s.rest : nil
				if !isLast {
					let nE = curPart % eT
					let nR = curPart / eT
					next = prepareNext(with: curGroup[nE], set: nR)
				} else if curExercize < exercizes.count {
					next = prepareNext(with: exercizes[curExercize][0])
				}
				
				return WorkoutCircuitStep(exercizeName: e.name, set: s, change: self.secondaryInfoChange(for: e), rest: (rest ?? 0) > 0 ? rest : nil, circuitCompletion: (eC + 1, eT, rC + 1, rT), nextUp: next, isLast: isLast && next == nil)
			} else { // Single exercize
				let e = curGroup[0] as! GTSimpleSetsExercize
				let s = e[Int32(curPart)]!
				let isLast = curPart == e.sets.count - 1
				var next: WorkoutStepNext?
				
				let (globalRest, lastRest) = e.restStatus
				let rest = (isLast && lastRest) || (!isLast && globalRest) ? s.rest : nil
				let others: [WorkoutExercizeStep.Other] = e.setList[(curPart + 1)...].map { ($0.secondaryInfo, $0.secondaryInfoLabel) }
				if curExercize + 1 < exercizes.count {
					next = prepareNext(with: exercizes[curExercize + 1][0])
				}
				
				if isLast {
					curPart = 0
					curExercize += 1
				} else {
					curPart += 1
				}
				
				return WorkoutExercizeStep(exercizeName: e.name, set: s, change: self.secondaryInfoChange(for: e), rest: (rest ?? 0) > 0 ? rest : nil, others: others, nextUp: next, isLast: isLast && next == nil)
			}
		}
	}
	
}
