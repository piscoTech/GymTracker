//
//  OrganizedWorkout.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 14/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

// TODO: Make IteratorProtocol, next() must return nil if invalid
class OrganizedWorkout {
	
	private(set) var raw: Workout
	
	init(_ wrkt: Workout) {
		raw = wrkt
	}
	
	// MARK: - Underlying Layer Accessors
	
	func set(name: String) {
		raw.set(name: name)
	}
	
	var archived: Bool {
		get {
			return raw.archived
		}
		set {
			raw.archived = newValue
		}
	}
	
	var exercizes: [Exercize] {
		return raw.exercizeList
	}
	
	subscript (n: Int) -> Exercize? {
		return raw[Int32(n)]
	}
	
	var hasExercizes: Bool {
		return raw.hasExercizes
	}
	
	func moveExercizeAt(number from: Int, to dest: Int) {
		raw.moveExercizeAt(number: from, to: dest)
		recalculateCircuitStatus()
	}
	
	private func verifyExercize(_ e: Exercize) {
		precondition(e.workout == raw, "Exercize does not belong to this workout")
	}
	
	// MARK: - Circuit Support
	
	/// Whether or not the workout is valid.
	///
	/// The workout is valid if the underling `Workout` is valid and all exercizes in a circuit have the same number of sets.
	var validityStatus: (global: Bool, circuitError: [Int]) {
		var global = raw.isValid
		var circuitError = [Int]()
		
		var circuitCount: Int?
		for e in raw.exercizeList {
			global = global && e.isValid
			
			if e.isCircuit, circuitCount == nil {
				circuitCount = e.sets.count
			}
			
			if let c = circuitCount, c != e.sets.count {
				global = false
				circuitError.append(Int(e.order))
			}
			
			if !e.isCircuit {
				circuitCount = nil
			}
		}
		
		return (global, circuitError)
	}
	
	func circuitStatus(for exercize: Exercize) -> (isInCircuit: Bool, number: Int?, total: Int?) {
		verifyExercize(exercize)
		
		let inCircuit = exercize.isCircuit || exercize.previous?.isCircuit ?? false
		
		let number: Int?
		let total: Int?
		if inCircuit {
			var n = 1
			var e = exercize
			while let prev = e.previous, prev.isCircuit {
				n += 1
				e = prev
			}
			
			number = n
			var t = n
			e = exercize
			while let next = e.next, e.isCircuit {
				t += 1
				e = next
			}
			
			total = t
		} else {
			number = nil
			total = nil
		}
		
		return (inCircuit, number, total)
	}
	
	/// Whether or not the passed exercize can become part of a circuit, if the exercize is already in one this function always return `true`.
	func canBecomeCircuit(exercize: Exercize) -> Bool {
		verifyExercize(exercize)
		
		guard !exercize.isRest else {
			return false
		}
		
		let (status, _, _) = circuitStatus(for: exercize)
		guard !status else {
			return true
		}
		
		if !(exercize.next?.isRest ?? true) {
			return true
		}
		
		if let prev = exercize.previous {
			let (prevStatus, _, _) = circuitStatus(for: prev)
			return prevStatus
		}
		
		return false
	}
	
	/// Make the passed exercize part of an existing circuit or create a new one starting with the passed exercize.
	///
	/// This function manipulates the `isCircuit` property of the passed exercize or the previuos one respectively if the previuos exercize is part of a crcuit or not.
	func makeCircuit(exercize: Exercize, isCircuit: Bool) {
		verifyExercize(exercize)
		
		if !isCircuit {
			exercize.makeCircuit(false)
			exercize.previous?.makeCircuit(false)
		} else {
			guard canBecomeCircuit(exercize: exercize) else {
				return
			}
			
			let (status, _, _) = circuitStatus(for: exercize)
			guard !status else {
				return
			}
			
			// Exercize can become a circuit and is not already in one
			if let prev = exercize.previous {
				let (prevStatus, _, _) = circuitStatus(for: prev)
				if prevStatus {
					prev.makeCircuit(true)
					// Add exercize at the end of the circuit of the previous exercize
				}
			}
			
			if let next = exercize.next, !next.isRest {
				exercize.makeCircuit(true) // Start (or continue) circuit with next one
			}
		}
	}
	
	/// Whether or not the `isCircuit` property can be set to `true` for the passed exercize, i.e. the next exercize can become part of the current circuit, if the exercize is not in a circuit this function always returns `false`, it returns always `true` if the exercize is already chaining.
	func canChainCircuit(for exercize: Exercize) -> Bool {
		verifyExercize(exercize)
		
		let (status, _, _) = circuitStatus(for: exercize)
		guard status else {
			return false
		}
		guard !exercize.isCircuit else {
			return true
		}
		
		return !(exercize.next?.isRest ?? true)
	}
	
	/// Set the `isCircuit` property for the passed exercize adding the next exercize to the current circuit.
	func chainCircuit(for exercize: Exercize, chain: Bool) {
		verifyExercize(exercize)
		
		if !chain {
			exercize.makeCircuit(false)
		} else {
			guard canChainCircuit(for: exercize) else {
				return
			}
			
			exercize.makeCircuit(true)
		}
	}
	
	/// Enable or disable the use of rest period for the current exercize inside the circuit, this function has not effect if the exercize is outside of a circuit.
	func enableCircuitRestPeriods(for exercize: Exercize, enable: Bool) {
		verifyExercize(exercize)
		
		// FIXME: Implement me
	}
	
	private func recalculateCircuitStatus() {
		// FIXME: Implement me
	}
	
}
