//
//  WorkoutIterator.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import MBLibrary

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
	
	fileprivate init(rest: TimeInterval?, nextUp: WorkoutStepNext?) {
		self.rest = rest
		self.nextUp = nextUp
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
	
	fileprivate init(exercizeName: String, reps: WorkoutSetStepData, rest: TimeInterval?, nextUp: WorkoutStepNext?) {
		self.exercize = exercizeName
		self.reps = reps
		
		let repsDescription = NSMutableAttributedString(string: "\(reps.reps)")
		if let w = reps.weight.weightDescription(withChange: reps.change) {
			repsDescription.append(NSAttributedString(string: timesSign))
			repsDescription.append(w)
		}
		self.repsDescription = repsDescription
		
		super.init(rest: rest, nextUp: nextUp)
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
	
	fileprivate init(exercizeName: String, reps: WorkoutSetStepData, rest: TimeInterval?, otherWeights other: [Double], nextUp: WorkoutStepNext?) {
		let otherSets = NSMutableAttributedString(string: "\(other.count)\(other.count > 1 ? WorkoutExercizeStep.otherSetsTxt : WorkoutExercizeStep.otherSetTxt): ")
		let kg = NSAttributedString(string: "kg")
		otherSets.append(other.flatMap { weight -> NSAttributedString? in
			guard let w = weight.weightDescription(withChange: reps.change) else {
				return nil
			}
			
			let res = NSMutableAttributedString(attributedString: w)
			res.append(kg)
			
			return res
		}.joined(separator: ", "))
		
		self.otherSets = otherSets
		self.otherWeights = other
		
		super.init(exercizeName: exercizeName, reps: reps, rest: rest, nextUp: nextUp)
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

	fileprivate init(exercizeName: String, reps: WorkoutSetStepData, rest: TimeInterval?, circuitCompletion: WorkoutCircuitStepData, nextUp: WorkoutStepNext?) {
		self.otherParts = NSAttributedString(string: "\(WorkoutCircuitStep.exercize) \(circuitCompletion.exercize)/\(circuitCompletion.totalExercize), \(WorkoutCircuitStep.round) \(circuitCompletion.round)/\(circuitCompletion.totalRound)")
		self.circuitCompletion = circuitCompletion
		
		super.init(exercizeName: exercizeName, reps: reps, rest: rest, nextUp: nextUp)
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
		super.init(rest: rest, nextUp: nextUp)
	}
}

/// Iterates over a workout.
///
/// Before creation make sure that the workout is valid and every settings is valid by calling `purgeInvalidSettings()`.
///
/// After creation make sure not to change the structure of workout, i.e. how exercizes and sets are ordered and arranged in circuit, after creation, weight update is fine. Any change in exercize arrangement will not be reflected, change in number of sets can result in unexpected behaviour.
class WorkoutIterator: IteratorProtocol {
	
	private let exercizes: [[Exercize]]
	/// The current exercize, rest or circuit.
	private var curExercize = 0
	/// The current set inside the current exercize or circuit, this identifies both the set and, if any, its subsequent rest period.
	private var curSet = 0

	init(_ w: OrganizedWorkout) {
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
	
	func next() -> WorkoutStep? {
		guard exercizes.count > curExercize else {
			return nil
		}
		
		return nil
	}
	
}
