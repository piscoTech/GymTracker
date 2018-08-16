//
//  GTSimpleRepsExercizeTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class GTSimpleRepsExercizeTests: XCTestCase {
	
	private var e: GTSimpleSetsExercize!

    override func setUp() {
		super.setUp()
		
        e = dataManager.newExercize()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }

    func testIsValidParent() {
		XCTAssertFalse(e.isValid)
		
		e.set(name: "E")
		XCTAssertFalse(e.isValid)
		
		_ = dataManager.newSet(for: e)
		XCTAssertFalse(e.isValid)
		
		let w = dataManager.newWorkout()
		w.add(parts: e)
		XCTAssertTrue(e.isValid)
		XCTAssertEqual(e.parentLevel as? GTWorkout, w)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		XCTAssertTrue(e.isValid)
		XCTAssertEqual(e.parentLevel as? GTCircuit, c)
		
		let ch = dataManager.newChoice()
		ch.add(parts: e)
		XCTAssertTrue(e.isValid)
		XCTAssertEqual(e.parentLevel as? GTChoice, ch)
    }
	
	func testSetList() {
		XCTAssertEqual(e.setList, [])
		
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.setList, [s1, s2])
	}
	
	func testSetSubscript() {
		XCTAssertNil(e[-1])
		XCTAssertNil(e[0])
		XCTAssertNil(e[1])
		
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertNil(e[-1])
		XCTAssertEqual(e[0], s1)
		XCTAssertEqual(e[1], s2)
		XCTAssertNil(e[2])
	}
	
	func testSetCount() {
		XCTAssertEqual(e.setsCount, 0)
		
		_ = dataManager.newSet(for: e)
		_ = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.setsCount, 2)
	}
	
	func testSetName() {
		let n = "Ex"
		e.set(name: n)
		XCTAssertEqual(e.name, n)
	}
	
	func testChoice() {
		XCTAssertFalse(e.isInChoice)
		XCTAssertNil(e.choiceStatus)
	
		let c = dataManager.newChoice()
		c.add(parts: e, dataManager.newExercize())
		
		XCTAssertTrue(e.isInChoice)
		if let (n, t) = e.choiceStatus {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in choice")
		}
	}
	
	func testInCircuit() {
		XCTAssertFalse(e.isInCircuit)
		XCTAssertNil(e.circuitStatus)
		
		let c = dataManager.newCircuit()
		c.add(parts: e, dataManager.newExercize())
		
		XCTAssertTrue(e.isInCircuit)
		if let (n, t) = e.circuitStatus {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in circuit")
		}
		
		let ch = dataManager.newChoice()
		ch.add(parts: e)
		XCTAssertFalse(e.isInCircuit)
		XCTAssertNil(e.circuitStatus)
		
		c.add(parts: ch)
		if let (n, t) = e.circuitStatus {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in circuit")
		}
	}
	
	func testCircuitRest() {
		XCTAssertFalse(e.hasCircuitRest)
		e.enableCircuitRest(true)
		XCTAssertFalse(e.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		e.enableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		
		let ch = dataManager.newChoice()
		ch.add(parts: e)
		XCTAssertFalse(e.hasCircuitRest)
		c.add(parts: ch)
		e.enableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
	}

	func testRestStatus() {
		var (g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		(g, l) = e.restStatus
		XCTAssertFalse(g)
		XCTAssertFalse(l)
		e.enableCircuitRest(true)
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		let e2 = dataManager.newExercize()
		c.add(parts: e2)
		e2.enableCircuitRest(true)
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertTrue(l)
		(g, l) = e2.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		
		let ch = dataManager.newChoice()
		ch.add(parts: e)
		c.add(parts: ch)
		(g, l) = e.restStatus
		XCTAssertFalse(g)
		XCTAssertFalse(l)
		e.enableCircuitRest(true)
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		ch.add(parts: dataManager.newExercize())
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		c.add(parts: dataManager.newExercize())
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertTrue(l)
	}
	
	func testRemoveSet() {
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.setsCount, 2)
		e.removeSet(s1)
		XCTAssertEqual(e.setsCount, 1)
		XCTAssertEqual(e[0], s2)
	}
	
	func testCompactSets() {
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertTrue(e.compactSets().isEmpty)
		XCTAssertEqual(e.setsCount, 2)
		XCTAssertEqual(e[0], s1)
		XCTAssertEqual(e[1], s2)
		
		s1.set(mainInfo: 0)
		XCTAssertEqual(e.compactSets(), [s1])
		XCTAssertEqual(e.setsCount, 1)
		XCTAssertEqual(e[0], s2)
	}
	
	func testSubtree() {
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.subtreeNodeList, [e, s1, s2])
	}

}
