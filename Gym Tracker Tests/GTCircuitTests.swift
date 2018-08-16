//
//  GTCircuitTests.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class GTCircuitTests: XCTestCase {
	
	private var circuit, choice: GTCircuit!
	
	private func newValidExercize() -> GTSimpleSetsExercize {
		let e = dataManager.newExercize()
		e.set(name: "Exercize")
		_ = dataManager.newSet(for: e)
		
		return e
	}
	
    override func setUp() {
        super.setUp()
		
		let nE = { () -> GTSimpleSetsExercize in
			let e = dataManager.newExercize()
			e.set(name: "Exercize")
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
		
		let e6 = circuit[0] as! GTSimpleSetsExercize
		let e7 = circuit[1] as! GTSimpleSetsExercize
		let e8 = circuit[2] as! GTSimpleSetsExercize
		
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e8)
		_ = dataManager.newSet(for: e8)
		
		XCTAssertFalse(circuit.isValid)
		XCTAssertEqual(circuit.exercizesError, [1])
		
		_ = dataManager.newSet(for: e7)
		
		XCTAssertFalse(circuit.isValid)
		XCTAssertEqual(circuit.exercizesError, [])
		
		let w = dataManager.newWorkout()
		w.add(parts: circuit)
		XCTAssertTrue(circuit.isValid)
		XCTAssertEqual(circuit.exercizesError, [])
		XCTAssertEqual(circuit.parentLevel as? GTWorkout, w)

		let e1 = choice[0] as! GTSimpleSetsExercize
		let e2 = choice[1] as! GTSimpleSetsExercize
		let ch = choice[2] as! GTChoice
		let e3 = ch[0]!
		let e4 = ch[1]!
		
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		_ = dataManager.newSet(for: e3)
		_ = dataManager.newSet(for: e4)
		_ = dataManager.newSet(for: e4)
		
		XCTAssertFalse(choice.isValid)
		XCTAssertEqual(choice.exercizesError, [2])
		
		w.add(parts: choice)
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		_ = dataManager.newSet(for: e3)
		
		XCTAssertTrue(choice.isValid)
		XCTAssertEqual(choice.exercizesError, [])
	}
	
	func testExList() {
		let c = dataManager.newCircuit()
		XCTAssertEqual(c.exercizeList, [])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(c.exercizeList, [e2, e1])
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
		
		c.add(parts: e2)
		XCTAssertEqual(c.exercizeList, [e1, e2])
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
	}
	
	func testSetSubscript() {
		let c = dataManager.newCircuit()
		XCTAssertNil(c[-1])
		XCTAssertNil(c[0])
		XCTAssertNil(c[1])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertNil(c[-1])
		XCTAssertEqual(c[0], e2)
		XCTAssertEqual(c[1], e1)
		XCTAssertNil(c[2])
	}
	
	func testMove() {
		let c = dataManager.newCircuit()
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
		
		c.movePartAt(number: 0, to: 1)
		
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
		
		c.movePartAt(number: 1, to: 0)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
	}
	
	func testRemovePart() {
		let c = dataManager.newCircuit()
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(c.exercizes.count, 2)
		
		c.remove(part: e2)
		XCTAssertEqual(c.exercizes.count, 1)
		XCTAssertEqual(c[0], e1)
	}

	func testSubtree() {
		let e1 = choice[0] as! GTSimpleSetsExercize
		let e2 = choice[1] as! GTSimpleSetsExercize
		let ch = choice[2] as! GTChoice
		let e3 = ch[0]!
		let e4 = ch[1]!
		
		let sets = Set(arrayLiteral: dataManager.newSet(for: e1), dataManager.newSet(for: e2), dataManager.newSet(for: e3), dataManager.newSet(for: e4), dataManager.newSet(for: e4), dataManager.newSet(for: e1), dataManager.newSet(for: e2), dataManager.newSet(for: e3))
		
		XCTAssertEqual(choice.subtreeNodeList, Set(arrayLiteral: ch, e1, e2, e3, e4, choice).union(sets))
	}
    
}
