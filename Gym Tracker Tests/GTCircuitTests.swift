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
	
	private var workout, complexWorkout: GTWorkout!
	
	#warning("Include also some choices")
	
    override func setUp() {
        super.setUp()
		
		var raw = dataManager.newWorkout()
		
		let nE = { () -> GTSimpleSetsExercize in
			let e = dataManager.newExercize()
			e.set(name: "Exercize")
			return e
		}

		let nR = { () -> GTRest in
			let r = dataManager.newRest()
			r.set(rest: 30)
			
			return r
		}
		
		raw.add(parts: nE(), nR(), nE(), nE(), nE(), nR())
		let c1 = dataManager.newCircuit() // 6
		raw.add(parts: c1)
		let e6, e7: GTSimpleSetsExercize
		do {
			e6 = nE()
			e7 = nE()
			c1.add(parts: e6, e7, nE())
		}
		raw.add(parts: nR(), nE(), nR(), nE(), nE(), nE())
		
		workout = raw
		e6.enableCircuitRest(true)
		e7.enableCircuitRest(true)
		c1[2]?.enableCircuitRest(true)
		
		raw = dataManager.newWorkout()
		let c2 = dataManager.newCircuit() // 0
		c2.add(parts: nE(), nE())
		let c3 = dataManager.newCircuit() //2
		c3.add(parts: nE(), nE(), nE())
		raw.add(parts: c2, nE(), c3)
		
		complexWorkout = raw
	}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
        super.tearDown()
    }
	
	func testCircuitValidity() {
		let c1 = workout[6] as! GTCircuit
		let e6 = c1[0] as! GTSimpleSetsExercize
		let e7 = c1[1] as! GTSimpleSetsExercize
		let e8 = c1[2] as! GTSimpleSetsExercize
		
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e8)
		_ = dataManager.newSet(for: e8)
		
		XCTAssertFalse(c1.isValid)
		XCTAssertEqual(c1.exercizesError, [1])

		let c2 = complexWorkout[0] as! GTCircuit
		let c3 = complexWorkout[2] as! GTCircuit
		
		let e0 = c2[0] as! GTSimpleSetsExercize
		let e1 = c2[1] as! GTSimpleSetsExercize
		let e3 = c3[0] as! GTSimpleSetsExercize
		let e4 = c3[1] as! GTSimpleSetsExercize
		let e5 = c3[2] as! GTSimpleSetsExercize
		
		_ = dataManager.newSet(for: e0)
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e1)
		
		XCTAssertFalse(c2.isValid)
		XCTAssertEqual(c2.exercizesError, [1])
		XCTAssertFalse(c3.isValid)
		XCTAssertEqual(c3.exercizesError, [])
		
		_ = dataManager.newSet(for: e0)
		_ = dataManager.newSet(for: e3)
		_ = dataManager.newSet(for: e4)
		_ = dataManager.newSet(for: e4)
		_ = dataManager.newSet(for: e5)
		_ = dataManager.newSet(for: e5)
	
		XCTAssertTrue(c2.isValid)
		XCTAssertEqual(c2.exercizesError, [])
		XCTAssertFalse(c3.isValid)
		XCTAssertEqual(c3.exercizesError, [0])
	}
	
	func testIsCircuit() {
		XCTAssertFalse((workout[0] as! GTSimpleSetsExercize).isInCircuit)
		XCTAssertFalse((workout[4] as! GTSimpleSetsExercize).isInCircuit)
		XCTAssertFalse((workout[12] as! GTSimpleSetsExercize).isInCircuit)
		
		let c1 = workout[6] as! GTCircuit
		XCTAssertTrue(c1[0]!.isInCircuit)
		XCTAssertTrue(c1[1]!.isInCircuit)
		XCTAssertTrue(c1[2]!.isInCircuit)
	}
	
	func testCircuitStatus() {
		XCTAssertNil((workout[0] as! GTSimpleSetsExercize).circuitStatus)
		XCTAssertNil((workout[4] as! GTSimpleSetsExercize).circuitStatus)
		
		let c1 = workout[6] as! GTCircuit
		if let (n, t) = c1[0]!.circuitStatus {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = c1[1]!.circuitStatus  {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = c1[2]!.circuitStatus  {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}

		XCTAssertNil((workout[12] as! GTSimpleSetsExercize).circuitStatus)
	}
	
	func testEnableRestPeriod() {
		let c1 = workout[6] as! GTCircuit
		
		XCTAssertTrue(c1[0]!.hasCircuitRest)
		XCTAssertTrue(c1[1]!.hasCircuitRest)
		XCTAssertTrue(c1[2]!.hasCircuitRest)
		
		XCTAssertFalse((workout[0] as! GTSimpleSetsExercize).hasCircuitRest)
		
		(workout[0] as! GTSimpleSetsExercize).enableCircuitRest(true)
		c1[1]!.enableCircuitRest(false)
		c1[2]!.enableCircuitRest(false)
		
		XCTAssertFalse(c1[1]!.hasCircuitRest)
		XCTAssertFalse(c1[2]!.hasCircuitRest)
		XCTAssertFalse((workout[0] as! GTSimpleSetsExercize).hasCircuitRest)
		
		c1[2]!.enableCircuitRest(true)
		XCTAssertTrue(c1[2]!.hasCircuitRest)
		
		#warning("Test also on a choice (should remain false)")
	}
	
	func testRemoveExercize() {
		#warning("Cellection level checks")
	}
	
	func testRestStatus() {
		var (g, l) = (workout[0] as! GTSimpleSetsExercize).restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		
		let c1 = workout[6] as! GTCircuit
		(g, l) = c1[0]!.restStatus
		XCTAssertTrue(g)
		XCTAssertTrue(l)
		
		(g, l) = c1[1]!.restStatus
		XCTAssertTrue(g)
		XCTAssertTrue(l)
		
		(g, l) = c1[2]!.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		
		let c2 = complexWorkout[0] as! GTCircuit
		(g, l) = c2[0]!.restStatus
		XCTAssertFalse(g)
		XCTAssertFalse(l)
		
		(g, l) = c2[1]!.restStatus
		XCTAssertFalse(g)
		XCTAssertFalse(l)
	}

	func testSubtree() {
		XCTFail()
	}
    
}
