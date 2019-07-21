//
//  GTCircuitTests.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import MBLibrary
@testable import GymTrackerCore

class GTCircuitTests: XCTestCase {
	
	private var circuit, choice: GTCircuit!
	
	private func newValidExercise() -> GTSimpleSetsExercise {
		let e = dataManager.newExercise()
		e.set(name: "Exercise")
		_ = dataManager.newSet(for: e)
		
		return e
	}
	
    override func setUp() {
        super.setUp()
		
		let nE = { () -> GTSimpleSetsExercise in
			let e = dataManager.newExercise()
			e.set(name: "Exercise")
			return e
		}
		
		circuit = dataManager.newCircuit()
		do {
			let e6 = nE()
			let e7 = nE()
			let e8 = nE()
			
			circuit.add(parts: e6, e7, e8)
			e6.enableCircuitRest(true)
			e7.enableCircuitRest(true)
			e8.enableCircuitRest(true)
		}
		
		choice = dataManager.newCircuit()
		do {
			let e1 = nE()
			let e2 = nE()
			let e3 = nE()
			let e4 = nE()
			let ch = dataManager.newChoice()
			
			choice.add(parts: e1, e2, ch)
			ch.add(parts: e3, e4)
			e1.enableCircuitRest(true)
			e4.enableCircuitRest(true)
		}
	}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }
	
	func testIsValidParent() {
		XCTAssertFalse(circuit.isValid)
		XCTAssertFalse(circuit.isSubtreeValid)
		
		let e6 = circuit[0] as! GTSimpleSetsExercise
		let e7 = circuit[1] as! GTSimpleSetsExercise
		let e8 = circuit[2] as! GTSimpleSetsExercise
		
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e8)
		_ = dataManager.newSet(for: e8)
		
		XCTAssertFalse(circuit.isSubtreeValid)
		XCTAssertFalse(circuit.isValid)
		XCTAssertEqual(circuit.exercisesError, [1])
		
		_ = dataManager.newSet(for: e7)
		
		XCTAssertTrue(circuit.isSubtreeValid)
		XCTAssertFalse(circuit.isValid)
		XCTAssertEqual(circuit.exercisesError, [])
		
		let w = dataManager.newWorkout()
		w.add(parts: circuit)
		XCTAssertTrue(circuit.isSubtreeValid)
		XCTAssertTrue(circuit.isValid)
		XCTAssertEqual(circuit.exercisesError, [])
		XCTAssertEqual(circuit.parentLevel as? GTWorkout, w)

		let e1 = choice[0] as! GTSimpleSetsExercise
		let e2 = choice[1] as! GTSimpleSetsExercise
		let ch = choice[2] as! GTChoice
		let e3 = ch[0]!
		let e4 = ch[1]!
		
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		_ = dataManager.newSet(for: e3)
		_ = dataManager.newSet(for: e4)
		_ = dataManager.newSet(for: e4)
		
		XCTAssertFalse(choice.isSubtreeValid)
		XCTAssertFalse(choice.isValid)
		XCTAssertEqual(choice.exercisesError, [2])
		
		w.add(parts: choice)
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		_ = dataManager.newSet(for: e3)
		
		XCTAssertTrue(circuit.isSubtreeValid)
		XCTAssertTrue(choice.isValid)
		XCTAssertEqual(choice.exercisesError, [])
	}
	
	func testReorderParent() {
		let w = dataManager.newWorkout()
		w.add(parts: circuit, dataManager.newExercise())
		
		let w2 = dataManager.newWorkout()
		w2.add(parts: circuit)
		
		XCTAssertNotEqual(w[0], circuit)
		XCTAssertEqual(w[0]?.order, 0)
		XCTAssertEqual(w.exercises.count, 1)
	}
	
	func testPurgeSetting() {
		let e = dataManager.newExercise()
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		XCTAssertTrue(circuit.purge().isEmpty)
		XCTAssertTrue(e.hasCircuitRest)
		
		circuit.add(parts: e)
		XCTAssertTrue(e.hasCircuitRest)
		XCTAssertTrue(circuit.purge().isEmpty)
		XCTAssertTrue(e.hasCircuitRest)
	}
	
	func testExList() {
		let c = dataManager.newCircuit()
		XCTAssertEqual(c.exerciseList, [])
		
		let e1 = newValidExercise()
		let e2 = newValidExercise()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(c.exerciseList, [e2, e1])
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
		
		c.add(parts: e2)
		XCTAssertEqual(c.exerciseList, [e1, e2])
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
	}
	
	func testSetSubscript() {
		let c = dataManager.newCircuit()
		XCTAssertNil(c[-1])
		XCTAssertNil(c[0])
		XCTAssertNil(c[1])
		
		let e1 = newValidExercise()
		let e2 = newValidExercise()
		c.add(parts: e2, e1)
		
		XCTAssertNil(c[-1])
		XCTAssertEqual(c[0], e2)
		XCTAssertEqual(c[1], e1)
		XCTAssertNil(c[2])
	}
	
	func testMove() {
		let c = dataManager.newCircuit()
		let e1 = newValidExercise()
		let e2 = newValidExercise()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
		
		c.movePart(at: 0, to: 1)
		
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
		
		c.movePart(at: 1, to: 0)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
	}
	
	func testRemovePart() {
		let c = dataManager.newCircuit()
		let e1 = newValidExercise()
		let e2 = newValidExercise()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(c.exercises.count, 2)
		
		c.remove(part: e2)
		XCTAssertEqual(c.exercises.count, 1)
		XCTAssertEqual(c[0], e1)
	}

	func testSubtree() {
		let e1 = choice[0] as! GTSimpleSetsExercise
		let e2 = choice[1] as! GTSimpleSetsExercise
		let ch = choice[2] as! GTChoice
		let e3 = ch[0]!
		let e4 = ch[1]!
		
		let sets = Set(arrayLiteral: dataManager.newSet(for: e1), dataManager.newSet(for: e2), dataManager.newSet(for: e3), dataManager.newSet(for: e4), dataManager.newSet(for: e4), dataManager.newSet(for: e1), dataManager.newSet(for: e2), dataManager.newSet(for: e3))
		
		XCTAssertEqual(choice.subtreeNodes, Set(arrayLiteral: ch, e1, e2, e3, e4, choice).union(sets))
	}
	
	func testExport() {
		let e6 = circuit[0] as! GTSimpleSetsExercise
		let e7 = circuit[1] as! GTSimpleSetsExercise
		let e8 = circuit[2] as! GTSimpleSetsExercise
		
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e8)
		_ = dataManager.newSet(for: e8)
		
		let xml = circuit.export()
		assert(string: xml, containsInOrder: [GTCircuit.circuitTag, GTCircuit.exercisesTag, GTSimpleSetsExercise.exerciseTag, GTSimpleSetsExercise.hasCircuitRestTag, "</", GTSimpleSetsExercise.exerciseTag, GTSimpleSetsExercise.exerciseTag, GTSimpleSetsExercise.hasCircuitRestTag, "</", GTSimpleSetsExercise.exerciseTag, GTSimpleSetsExercise.exerciseTag, GTSimpleSetsExercise.hasCircuitRestTag, "</", GTSimpleSetsExercise.exerciseTag, "</", GTCircuit.exercisesTag, "</", GTCircuit.circuitTag])
	}
	
	static func validXml() -> XMLNode {
		let xml = XMLNode(name: GTCircuit.circuitTag)
		let exs = XMLNode(name: GTCircuit.exercisesTag)
		xml.add(child: exs)
		exs.add(child: GTSimpleSetsExerciseTests.validXml())
		exs.add(child: GTSimpleSetsExerciseTests.validXml(name: 2))
		exs.add(child: GTChoiceTests.validXml())
		
		return xml
	}
	
	func testImport() {
		do {
			_ = try GTCircuit.import(fromXML: XMLNode(name: ""), withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertEqual(o, [])
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			
			_ = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertEqual(o.count, 1)
			XCTAssertTrue(o.first is GTCircuit)
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExerciseTests.validXml())
			
			_ = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTCircuit) && !($0 is GTSimpleSetsExercise) && !($0 is GTRepsSet) })
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExerciseTests.validXml())
			exs.add(child: GTSimpleSetsExerciseTests.validXml(name: 2))
			exs.add(child: GTSimpleSetsExerciseTests.validXml(name: 3))
			
			let c = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertTrue(c.isSubtreeValid)
			
			XCTAssertEqual(c.exercises.count, 3)
			XCTAssertEqual((c[0] as? GTSimpleSetsExercise)?.name, "Ex 1")
			XCTAssertEqual((c[1] as? GTSimpleSetsExercise)?.name, "Ex 2")
			XCTAssertEqual((c[2] as? GTSimpleSetsExercise)?.name, "Ex 3")
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercisesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExerciseTests.validXml())
			exs.add(child: GTSimpleSetsExerciseTests.validXml(name: 2))
			let chXml = GTChoiceTests.validXml()
			exs.add(child: chXml)
			chXml.children[0].children[1].children[1].add(child: GTRepsSetTests.validXml())
			
			_ = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTError.importFailure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTCircuit) && !($0 is GTSimpleSetsExercise) && !($0 is GTRepsSet) && !($0 is GTChoice)})
		} catch _ {
			XCTFail()
		}
		
		do {
			let c = try GTCircuit.import(fromXML: GTCircuitTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(c.isSubtreeValid)
			
			XCTAssertEqual(c.exercises.count, 3)
			XCTAssertEqual((c[0] as? GTSimpleSetsExercise)?.name, "Ex 1")
			XCTAssertEqual((c[1] as? GTSimpleSetsExercise)?.name, "Ex 2")
			XCTAssertTrue(c[2] is GTChoice)
		} catch _ {
			XCTFail()
		}
		
		do {
			let o = try GTDataObject.import(fromXML: GTCircuitTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(o is GTCircuit)
		} catch _ {
			XCTFail()
		}
	}
    
}
