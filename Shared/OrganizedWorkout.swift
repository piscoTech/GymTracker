//
//  OrganizedWorkout.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 14/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

class OrganizedWorkout {
	
	private(set) var raw: Workout
	
	init(_ wrkt: Workout) {
		raw = wrkt
	}
	
	// MARK: - Underlying Layer Accessors
	
	var name: String {
		get {
			return raw.name
		}
		set {
			raw.set(name: newValue)
		}
	}
	
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
	
	var count: Int {
		return raw.exercizes.count
	}
	
	var isEmpty: Bool {
		return raw.exercizes.isEmpty
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
	
	func compactExercizes() -> (start: [Exercize], end: [Exercize], middle: [(e: Exercize, oldOrder: Int)]) {
		let (s, e, m) = raw.compactExercizes()
		
		return (s, e, m.map { ($0, Int($1)) })
	}
	
	/// Move the exercize at the specified index to a new location, the old exercize at `to` index will have index `dest+1` if the exercize is being moved towards the start of the workout, `dest-1` otherwise.
	///
	/// The moved exercize will retain or gain the status of circuit only if moved after *and* before exercizes that are part of the same circuit.
	func moveExercizeAt(number from: Int, to dest: Int) {
		guard let exercize = self[from] else {
			return
		}
		
		// Determine the circuit status of the moving exercize
		let newCircuitStatus: Bool
		do {
			let newPrev, newNext: Exercize?
			if dest < from {
				newPrev = self[dest - 1]
				newNext = self[dest]
			} else { // dest > from
				newPrev = self[dest]
				newNext = self[dest + 1]
			}
			if let p = newPrev, let n = newNext {
				if let (pN, pT) = circuitStatus(for: p), let (nN, nT) = circuitStatus(for: n) {
					newCircuitStatus = pT == nT && pN + 1 == nN
				} else {
					newCircuitStatus = false
				}
			} else {
				newCircuitStatus = false
			}
		}
		
		handleCircuitAroundRemovedExercize(exercize) {
			self.raw.moveExercizeAt(number: from, to: dest)
		}
		
		let moving = self[dest]!
		makeCircuit(exercize: moving, isCircuit: newCircuitStatus)
		if newCircuitStatus {
			chainCircuit(for: moving, chain: true)
		}
	}
	
	func removeExercize(_ e: Exercize) {
		handleCircuitAroundRemovedExercize(e) {
			self.raw.removeExercize(e)
		}
	}
	
	private func verifyExercize(_ e: Exercize) {
		precondition(e.workout == raw, "Exercize does not belong to this workout")
	}
	
	// MARK: - Validation
	
	/// Whether or not the workout is valid.
	///
	/// The workout is valid if the underling `Workout` is valid and all exercizes in a circuit have the same number of sets.
	///
	/// An exercize has its index included in `circuitError` if it's considered invalid due to the circuit it belongs to, i.e. it has not the same number of sets as the most frequent sets count in the circuit.
	var validityStatus: (global: Bool, circuitError: Set<Int>) {
		var global = raw.isValid
		var circuitError = Set<Int>()
		
		var circuitSetsInfo: (first: Int, counts: [Int])?
		for e in exercizes {
			global = global && e.isValid
			
			if e.isCircuit, circuitSetsInfo == nil {
				circuitSetsInfo = (Int(e.order), [])
			}
			circuitSetsInfo?.counts.append(e.sets.count)
			
			if !e.isCircuit {
				if let (start, counts) = circuitSetsInfo {
					var counter = [Int: Int]()
					var max = 0
					var mode: Int?
					
					for i in counts {
						let count = (counter[i] ?? 0) + 1
						counter[i] = count
						
						if count == max {
							mode = mode ?? max
						} else if count > max {
							mode = i
							max = count
						}
					}
					
					circuitError.formUnion(zip(counts, 0 ..< counts.count).filter { $0.0 != mode }.map { $0.1 + start })
				}
				
				circuitSetsInfo = nil
			}
		}
		
		return (global && circuitError.isEmpty, circuitError)
	}
	
	func purgeInvalidSettings() {
		for e in exercizes {
			if e.isRest {
				e.makeCircuit(false)
				e.enableCircuitRest(false)
			} else {
				let prev = e.previous
				let next = e.next
				
				let chain = e.isCircuit && !(next?.isRest ?? true)
				e.makeCircuit(chain)
				let rest = e.hasCircuitRest && (chain || (prev?.isCircuit ?? false))
				e.enableCircuitRest(rest)
			}
		}
	}
	
	// MARK: - Circuit Support
	
	func isCircuit(_ exercize: Exercize) -> Bool {
		verifyExercize(exercize)
		
		return exercize.isCircuit || exercize.previous?.isCircuit ?? false
	}
	
	func circuitStatus(for exercize: Exercize) -> (number: Int, total: Int)? {
		guard isCircuit(exercize) else {
			return nil
		}
		
		var number = 1
		var e = exercize
		while let prev = e.previous, prev.isCircuit {
			number += 1
			e = prev
		}
		
		var total = number
		e = exercize
		while let next = e.next, e.isCircuit {
			total += 1
			e = next
		}
		
		return (number, total)
	}
	
	/// Whether or not the exercize has mid-sets rests, always `true` outside circuits, and wheter the last set has an explit rest, can be `true` only inside a circuit.
	///
	/// `last` is always `false` if `global` is `false`, returns `nil` for rest periods.
	func restStatus(for exercize: Exercize) -> (global: Bool, last: Bool)? {
		verifyExercize(exercize)
		guard !exercize.isRest else {
			return nil
		}
		
		guard let (n, t) = circuitStatus(for: exercize) else {
			return (true, false)
		}
		
		if exercize.hasCircuitRest {
			return (true, n != t)
		} else {
			return (false, false)
		}
	}
	
	/// Whether or not the passed exercize can become part of a circuit, if the exercize is already in one this function always return `true`.
	func canBecomeCircuit(exercize: Exercize) -> Bool {
		verifyExercize(exercize)
		
		guard !exercize.isRest else {
			return false
		}
		
		guard !isCircuit(exercize) else {
			return true
		}
		
		if !(exercize.next?.isRest ?? true) {
			return true
		}
		
		if let prev = exercize.previous {
			return isCircuit(prev)
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
			exercize.enableCircuitRest(false)
			
			if let p = exercize.previous {
				p.makeCircuit(false)
				fixCircuitStatus(for: p)
			}
			if let n = exercize.next {
				fixCircuitStatus(for: n)
			}
		} else {
			guard canBecomeCircuit(exercize: exercize) else {
				return
			}
			
			guard !self.isCircuit(exercize) else {
				return
			}
			
			if let next = exercize.next, !next.isRest {
				exercize.makeCircuit(true) // Start circuit with next one
				return
			}
			
			// Exercize can only become a circuit by joing the previous circuit, if any
			if let prev = exercize.previous {
				if self.isCircuit(prev) {
					prev.makeCircuit(true)
					// Add exercize at the end of the circuit of the previous exercize
				}
			}
		}
	}
	
	/// Whether or not the `isCircuit` property can be set to `true` for the passed exercize, i.e. the next exercize can become part of the current circuit, if the exercize is not in a circuit this function always returns `false`, it returns always `true` if the exercize is already chaining.
	func canChainCircuit(for exercize: Exercize) -> Bool {
		verifyExercize(exercize)
		
		guard isCircuit(exercize) else {
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
			fixCircuitStatus(for: exercize)
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
		
		if enable {
			exercize.enableCircuitRest(isCircuit(exercize))
		} else {
			exercize.enableCircuitRest(false)
		}
	}
	
	private func fixCircuitStatus(for exercize: Exercize) {
		if !isCircuit(exercize) {
			exercize.enableCircuitRest(false)
		}
	}
	
	private func handleCircuitAroundRemovedExercize(_ exercize: Exercize, withRemoveAction action: () -> ()) {
		verifyExercize(exercize)
		
		// Determine the circuit status of previous and next exercizes on the old position
		var fixCircuit = [Exercize]()
		// Leaving behind a circuit that should cease to exists
		if let (n, t) = circuitStatus(for: exercize), t == 2 {
			if n == 1, let next = exercize.next {
				fixCircuit.append(next)
			}
			if n == 2, let prev = exercize.previous {
				prev.makeCircuit(false)
				fixCircuit.append(prev)
			}
		}
		if let p = exercize.previous {
			let preventJoinPrevNext: Bool
			
			if let n = exercize.next, let (nN, nT) = circuitStatus(for: n) {
				if let (pN, pT) = circuitStatus(for: p) {
					preventJoinPrevNext = pT != nT || pN + 2 != nN
				} else {
					preventJoinPrevNext = false
				}
			} else {
				preventJoinPrevNext = true
			}
			
			if preventJoinPrevNext {
				p.makeCircuit(false)
				fixCircuit.append(p)
			}
		}
		
		action()
		
		for e in fixCircuit {
			fixCircuitStatus(for: e)
		}
	}
	
}
