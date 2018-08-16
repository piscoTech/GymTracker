//
//  GTSetsExercize.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTSetsExercize)
class GTSetsExercize: GTExercize {
	
	final private let circuitKey = "circuit"
	final private let hasCircuitRestKey = "hasCircuitRest"

    @NSManaged private(set) var hasCircuitRest: Bool
	@NSManaged private(set) var circuit: GTCircuit?
	
	override func set(workout w: GTWorkout?) {
		super.set(workout: w)
		
		if w != nil {
			set(circuit: nil)
		}
	}
	
	/// Make the exercize a part of the given circuit.
	///
	/// Unless when passing `nil`, don't call this method directly but rather call `add(parts:_)` on the circuit.
	func set(circuit c: GTCircuit?) {
		let old = self.circuit
		
		self.circuit = c
		old?.recalculatePartsOrder()
		#warning("Call recalculatePartsOrder() on old value, and test")
		
		if c == nil {
			enableCircuitRest(false)
		} else {
			set(workout: nil)
		}
	}
	
	///Enables rest periods in circuits for this exercize.
	func enableCircuitRest(_ r: Bool) {
		self.hasCircuitRest = isInCircuit && r
	}
	
	/// The number of sets part of this exercize, or `nil` if it cannot be determined.
	var setsCount: Int? {
		fatalError("Abstract property not implemented")
	}
	
	// MARK: - Circuit Support
	
	/// Whether the exercize is at some point part of a circuit.
	var isInCircuit: Bool {
		return self.parentHierarchy.first { $0 is GTCircuit } != nil
	}
	
	/// The position of the exercize in the circuit, `nil` outside of circuits.
	var circuitStatus: (number: Int, total: Int)? {
		let hierarchy = self.parentHierarchy
		guard let cIndex = hierarchy.index(where: { $0 is GTCircuit }),
			let c = hierarchy[cIndex] as? GTCircuit,
			let exInCircuit = cIndex > hierarchy.startIndex
				? hierarchy[hierarchy.index(before: cIndex)] as? GTPart
				: self
			else {
			return nil
		}
		
		return (Int(exInCircuit.order) + 1, c.exercizes.count)
	}
	
	/// Whether or not the exercize has mid-sets rests, always `true` outside circuits, and wheter the last set has an explit rest, can be `true` only inside a circuit.
	///
	/// `last` is always `false` if `global` is `false`.
	var restStatus: (global: Bool, last: Bool) {
		guard let (n, t) = circuitStatus else {
			return (true, false)
		}
		
		if self.hasCircuitRest {
			return (true, n != t)
		} else {
			return (false, false)
		}
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		if let c = circuit?.recordID.wcRepresentation {
			obj[circuitKey] = c
		}
		obj[hasCircuitRestKey] = hasCircuitRest
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let hasCircuitRest = src[hasCircuitRestKey] as? Bool else {
				return false
		}
		
		self.circuit = CDRecordID(wcRepresentation: src[circuitKey] as? [String])?.getObject(fromDataManager: dataManager) as? GTCircuit
		self.hasCircuitRest = hasCircuitRest
		
		return true
	}

}
