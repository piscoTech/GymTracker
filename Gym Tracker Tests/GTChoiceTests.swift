//
//  GTChoiceTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class GTChoiceTests: XCTestCase {

	private var ch: GTChoice!
	
    override func setUp() {
        ch = dataManager.newChoice()
    }
	
	private func newValidExercize() -> GTSimpleSetsExercize {
		let e = dataManager.newExercize()
		e.set(name: "Exercize")
		_ = dataManager.newSet(for: e)
		
		return e
	}

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

	func testIsValidParent() {
		XCTAssertFalse(ch.isValid)
		
		ch.add(parts: newValidExercize())
		XCTAssertFalse(ch.isValid)

		let w = dataManager.newWorkout()
		w.add(parts: ch)
		XCTAssertFalse(ch.isValid)
		ch.add(parts: newValidExercize())
		XCTAssertTrue(ch.isValid)
		XCTAssertEqual(ch.parentLevel as? GTWorkout, w)

		let c = dataManager.newCircuit()
		c.add(parts: ch)
		XCTAssertTrue(ch.isValid)
		XCTAssertEqual(ch.parentLevel as? GTCircuit, c)
	}
	
	func testInCircuitError() {
		XCTAssertNil(ch.inCircuitExercizesError)
		
		let c = dataManager.newCircuit()
		c.add(parts: ch)
		
		XCTAssertEqual(ch.inCircuitExercizesError, [])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e1, e2)
		
		XCTAssertTrue(ch.isValid)
		XCTAssertEqual(ch.inCircuitExercizesError, [])
		
		_ = dataManager.newSet(for: e1)
		
		XCTAssertFalse(ch.isValid)
		XCTAssertEqual(ch.inCircuitExercizesError, [1])
		
		let e3 = newValidExercize()
		ch.add(parts: e3)
		
		XCTAssertFalse(ch.isValid)
		XCTAssertEqual(ch.inCircuitExercizesError, [0])
	}
	
	func testInCircuit() {
		XCTAssertFalse(ch.isInCircuit)
		XCTAssertNil(ch.circuitStatus)
		
		let c = dataManager.newCircuit()
		c.add(parts: ch, dataManager.newExercize())
		
		XCTAssertTrue(ch.isInCircuit)
		if let (n, t) = ch.circuitStatus {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in circuit")
		}
	}
	
	func testCircuitRest() {
		XCTAssertFalse(ch.hasCircuitRest)
		ch.enableCircuitRest(true)
		XCTAssertFalse(ch.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: ch)
		ch.enableCircuitRest(true)
		XCTAssertFalse(ch.hasCircuitRest)
	}
	
	func testSetCount() {
		XCTAssertNil(ch.setsCount)
		
		let e2 = newValidExercize()
		ch.add(parts: newValidExercize(), e2)
		
		XCTAssertEqual(ch.setsCount, 1)
		
		_ = dataManager.newSet(for: e2)
		
		XCTAssertNil(ch.setsCount)
	}
	
	func testExList() {
		XCTAssertEqual(ch.exercizeList, [])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)
		
		XCTAssertEqual(ch.exercizeList, [e2, e1])
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)

		ch.add(parts: e2)
		XCTAssertEqual(ch.exercizeList, [e1, e2])
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
	}
	
	func testSetSubscript() {
		XCTAssertNil(ch[-1])
		XCTAssertNil(ch[0])
		XCTAssertNil(ch[1])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)

		XCTAssertNil(ch[-1])
		XCTAssertEqual(ch[0], e2)
		XCTAssertEqual(ch[1], e1)
		XCTAssertNil(ch[2])
	}
	
	func testRemovePart() {
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)
		
		XCTAssertEqual(ch.exercizes.count, 2)
		
		ch.remove(part: e2)
		XCTAssertEqual(ch.exercizes.count, 1)
		XCTAssertEqual(ch[0], e1)
	}
	
	func testSubtree() {
		XCTFail()
	}

}
