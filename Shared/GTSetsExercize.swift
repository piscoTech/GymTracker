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
	
	func set(circuit c: GTCircuit?) {
		self.circuit = c
		
		if c == nil {
			hasCircuitRest = false
		} else {
			set(workout: nil)
		}
	}
	
	///Enables rest periods in circuits for this exercize.
	func enableCircuitRest(_ r: Bool) {
		self.hasCircuitRest = circuit != nil && r
	}
	
	override var parent: GTDataObject {
		return [workout, circuit].compactMap { $0 }.first!
	}
	
	// MARK: - Circuit Support
	
	/// Whether the exercize is directly part of a circuit.
	var isDirectlyInCircuit: Bool {
		return circuit != nil
	}
	
	/// Whether the exercize is at some point part of a circuit.
	var isInCircuit: Bool {
		#error("OR the parent collection is in a circuit")
		return circuit != nil
	}
	
	/// The position of the exercize in the circuit, `nil` outside of circuits.
	var circuitStatus: (number: Int, total: Int)? {
		#error("Fetch any parent circuit, not just directly connected")
		guard let c = circuit else {
			return nil
		}
		
		return (Int(self.order), c.exercizes.count)
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
