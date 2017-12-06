//
//  OrganizedWorkoutTest.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest

class OrganizedWorkoutTest: XCTestCase {
	
	var workout, complexWorkout: OrganizedWorkout!
    
    override func setUp() {
        super.setUp()
		
		var raw = dataManager.newWorkout()
		
		let newExercize = { () -> Exercize in
			let e = dataManager.newExercize(for: raw)
			e.set(name: "Exercize")
			
			return e
		}
		let newRest = {
			let r = dataManager.newExercize(for: raw)
			r.set(rest: 30)
		}
		
		_ = newExercize()
		newRest() // 1
		_ = newExercize()
		_ = newExercize() // 3
		_ = newExercize()
		newRest() // 5
		let e6 = newExercize()
		let e7 = newExercize() // 7
		_ = newExercize()
		newRest() // 9
		_ = newExercize()
		newRest() // 11
		_ = newExercize()
		_ = newExercize() // 13
		_ = newExercize()
		
		workout = OrganizedWorkout(raw)
		e6.makeCircuit(true)
		e6.enableCircuitRest(true)
		e7.makeCircuit(true)
		e7.enableCircuitRest(true)
		workout[8]?.enableCircuitRest(true)
		
		raw = dataManager.newWorkout()
		let c0 = newExercize()
		_ = newExercize() // 1
		_ = newExercize()
		let c3 = newExercize() // 3
		let c4 = newExercize()
		_ = newExercize() // 5
		
		complexWorkout = OrganizedWorkout(raw)
		c0.makeCircuit(true)
		c3.makeCircuit(true)
		c4.makeCircuit(true)
		// 0,1 and 3,4,5 are a circuit
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testIsCircuit() {
		XCTAssertFalse(workout.isCircuit(workout[0]!))
		XCTAssertFalse(workout.isCircuit(workout[1]!))
		XCTAssertFalse(workout.isCircuit(workout[4]!))
		XCTAssertFalse(workout.isCircuit(workout[14]!))
		
		XCTAssertTrue(workout.isCircuit(workout[6]!))
		XCTAssertTrue(workout.isCircuit(workout[7]!))
		XCTAssertTrue(workout.isCircuit(workout[8]!))
	}
	
	func testCircuitStatus() {
		XCTAssertNil(workout.circuitStatus(for: workout[0]!))
		XCTAssertNil(workout.circuitStatus(for: workout[1]!))
		XCTAssertNil(workout.circuitStatus(for: workout[4]!))
		
		if let (n, t) = workout.circuitStatus(for: workout[6]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = workout.circuitStatus(for: workout[7]!) {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = workout.circuitStatus(for: workout[8]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		XCTAssertNil(workout.circuitStatus(for: workout[14]!))
	}
    
    func testCanBecomeCircuit() {
		// No exercize after and no circuit before
        XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[0]!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[10]!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[14]!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[4]!))
		
		// Exercize after
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout[2]!))
		
		// Already in circuit
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout[6]!))
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout[7]!))
		
		// Is rest
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[1]!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[5]!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[9]!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout[11]!))
		
		// No exercize after but circuit before
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout[8]!))
    }
	
	func testMakeCircuit() {
		let e2 = workout[2]!
		let e3 = workout[3]!
		let e4 = workout[4]!
		workout.makeCircuit(exercize: e3, isCircuit: true)
		workout.makeCircuit(exercize: e2, isCircuit: true)
		
		XCTAssertTrue(e2.isCircuit)
		XCTAssertTrue(e3.isCircuit)
		XCTAssertFalse(e4.isCircuit)
		XCTAssertTrue(workout.isCircuit(e4))
		
		let e6 = workout[6]!
		let e7 = workout[7]!
		let e8 = workout[8]!
		workout.makeCircuit(exercize: e8, isCircuit: false)
		workout.makeCircuit(exercize: e7, isCircuit: false)
		
		XCTAssertFalse(workout[5]!.isCircuit)
		XCTAssertFalse(e6.isCircuit)
		XCTAssertFalse(workout.isCircuit(workout[6]!))
		XCTAssertFalse(e7.isCircuit)
		XCTAssertFalse(e8.isCircuit)
		XCTAssertFalse(workout.isCircuit(e8))
		
		workout.makeCircuit(exercize: e3, isCircuit: false)
		
		XCTAssertFalse(workout[1]!.isCircuit)
		XCTAssertFalse(e2.isCircuit)
		XCTAssertFalse(e3.isCircuit)
		XCTAssertFalse(e4.isCircuit)
		XCTAssertFalse(workout.isCircuit(e4))
		
		XCTAssertTrue(complexWorkout[0]!.isCircuit)
		XCTAssertFalse(complexWorkout[1]!.isCircuit)
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[1]!) {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Unexpected nil")
		}
		
		XCTAssertFalse(complexWorkout[2]!.isCircuit)
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[2]!))
		
		XCTAssertTrue(complexWorkout[3]!.isCircuit)
		XCTAssertTrue(complexWorkout[4]!.isCircuit)
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[5]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		complexWorkout.makeCircuit(exercize: complexWorkout[2]!, isCircuit: true) // 0,1 and 2,3,4,5 are a circuit
		XCTAssertTrue(complexWorkout[2]!.isCircuit)
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 4)
		} else {
			XCTFail("Unexpected nil")
		}
		
		complexWorkout.makeCircuit(exercize: complexWorkout[2]!, isCircuit: false) // Back to 0,1 and 3,4,5
		XCTAssertTrue(complexWorkout[0]!.isCircuit)
		XCTAssertFalse(complexWorkout[1]!.isCircuit)
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[1]!) {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Unexpected nil")
		}
		
		XCTAssertFalse(complexWorkout[2]!.isCircuit)
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[2]!))
		
		XCTAssertTrue(complexWorkout[3]!.isCircuit)
		XCTAssertTrue(complexWorkout[4]!.isCircuit)
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[5]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testMakeCircuitForceChainBefore() {
		let e2 = workout[2]!
		let e3 = workout[3]!
		let e4 = workout[4]!
		workout.makeCircuit(exercize: e2, isCircuit: true)
		workout.makeCircuit(exercize: e4, isCircuit: true)
		
		XCTAssertTrue(e2.isCircuit)
		XCTAssertTrue(e3.isCircuit)
		XCTAssertFalse(e4.isCircuit)
		
		if let (n, t) = workout.circuitStatus(for: e2) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = workout.circuitStatus(for: e3) {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = workout.circuitStatus(for: e4) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testUnmakeCircuitAfter() {
		complexWorkout[0]!.enableCircuitRest(true)
		complexWorkout[1]!.enableCircuitRest(true)
		
		complexWorkout.makeCircuit(exercize: complexWorkout[1]!, isCircuit: false)
		
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[0]!))
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[1]!))
		XCTAssertFalse(complexWorkout[0]!.hasCircuitRest)
		XCTAssertFalse(complexWorkout[1]!.hasCircuitRest)
	}
	
	func testUnmakeCircuitBefore() {
		complexWorkout[0]!.enableCircuitRest(true)
		complexWorkout[1]!.enableCircuitRest(true)
		
		complexWorkout.makeCircuit(exercize: complexWorkout[0]!, isCircuit: false)
		
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[0]!))
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[1]!))
		XCTAssertFalse(complexWorkout[0]!.hasCircuitRest)
		XCTAssertFalse(complexWorkout[1]!.hasCircuitRest)
	}
	
	func testUnmakeCircuitMid() {
		complexWorkout[3]!.enableCircuitRest(true)
		complexWorkout[4]!.enableCircuitRest(true)
		complexWorkout[5]!.enableCircuitRest(true)
		
		complexWorkout.makeCircuit(exercize: complexWorkout[4]!, isCircuit: false)
		
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[3]!))
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[4]!))
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[5]!))
		XCTAssertFalse(complexWorkout[3]!.hasCircuitRest)
		XCTAssertFalse(complexWorkout[4]!.hasCircuitRest)
		XCTAssertFalse(complexWorkout[5]!.hasCircuitRest)
	}
	
	func testCanChainCircuit() {
		XCTAssertFalse(workout.canChainCircuit(for: workout[0]!))
		XCTAssertFalse(workout.canChainCircuit(for: workout[1]!))
		XCTAssertFalse(workout.canChainCircuit(for: workout[3]!))
		XCTAssertFalse(workout.canChainCircuit(for: workout[5]!))
		XCTAssertFalse(workout.canChainCircuit(for: workout[8]!))
		XCTAssertFalse(workout.canChainCircuit(for: workout[14]!))
		
		XCTAssertTrue(workout.canChainCircuit(for: workout[6]!))
		XCTAssertTrue(workout.canChainCircuit(for: workout[7]!))
		
		XCTAssertTrue(complexWorkout.canChainCircuit(for: complexWorkout[1]!))
		XCTAssertFalse(complexWorkout.canChainCircuit(for: complexWorkout[2]!))
		
		workout[2]!.makeCircuit(true)
		complexWorkout[1]!.makeCircuit(true)
		
		XCTAssertTrue(workout.canChainCircuit(for: workout[3]!))
		XCTAssertTrue(workout.isCircuit(workout[2]!))
		
		XCTAssertTrue(complexWorkout.canChainCircuit(for: complexWorkout[2]!))
		XCTAssertTrue(complexWorkout.isCircuit(complexWorkout[2]!))
	}
	
	func testChainCircuit() {
		complexWorkout.chainCircuit(for: complexWorkout[1]!, chain: true)
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[3]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		complexWorkout.chainCircuit(for: complexWorkout[2]!, chain: true)
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 6)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[3]!) {
			XCTAssertEqual(n, 4)
			XCTAssertEqual(t, 6)
		} else {
			XCTFail("Unexpected nil")
		}
		
		workout.chainCircuit(for: workout[7]!, chain: false)
		XCTAssertFalse(workout.isCircuit(workout[8]!))
		if let (n, t) = workout.circuitStatus(for: workout[7]!) {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Unexpected nil")
		}
		
		workout.chainCircuit(for: workout[6]!, chain: false)
		XCTAssertFalse(workout.isCircuit(workout[6]!))
		XCTAssertFalse(workout.isCircuit(workout[7]!))
	}
	
	func testEnableRestPeriod() {
		XCTAssertTrue(workout[6]!.hasCircuitRest)
		XCTAssertTrue(workout[7]!.hasCircuitRest)
		XCTAssertTrue(workout[8]!.hasCircuitRest)
		
		XCTAssertFalse(workout[0]!.hasCircuitRest)
		
		workout.enableCircuitRestPeriods(for: workout[0]!, enable: true)
		workout.enableCircuitRestPeriods(for: workout[7]!, enable: false)
		workout.enableCircuitRestPeriods(for: workout[8]!, enable: false)
		
		XCTAssertFalse(workout[7]!.hasCircuitRest)
		XCTAssertFalse(workout[8]!.hasCircuitRest)
		XCTAssertFalse(workout[0]!.hasCircuitRest)
		
		workout.enableCircuitRestPeriods(for: workout[8]!, enable: true)
		XCTAssertTrue(workout[8]!.hasCircuitRest)
	}
	
	func testMoveExercizeNoCircuit() {
		let e6 = workout[6]!
		let e7 = workout[7]!
		workout.moveExercizeAt(number: 6, to: 1)
		workout.moveExercizeAt(number: 7, to: 2)
		
		XCTAssertEqual(e6, workout[1])
		XCTAssertEqual(e7, workout[2])
		
		XCTAssertFalse(workout.isCircuit(workout[0]!))
		XCTAssertFalse(workout.isCircuit(workout[1]!))
		XCTAssertFalse(workout.isCircuit(workout[2]!))
		XCTAssertFalse(workout.isCircuit(workout[8]!))
		XCTAssertFalse(workout[0]!.hasCircuitRest)
		XCTAssertFalse(workout[1]!.hasCircuitRest)
		XCTAssertFalse(workout[2]!.hasCircuitRest)
		XCTAssertFalse(workout[8]!.hasCircuitRest)
		
		let c4 = complexWorkout[4]!
		let c0 = complexWorkout[0]!
		complexWorkout.moveExercizeAt(number: 4, to: 0)
		XCTAssertEqual(c4, complexWorkout[0])
		XCTAssertEqual(c0, complexWorkout[1])
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[0]!)) // Old 4
		if let (n0, _) = complexWorkout.circuitStatus(for: complexWorkout[1]!) { // Old 0
			XCTAssertEqual(n0, 1)
		} else {
			XCTFail("Unexpected nil")
		}
		XCTAssertTrue(complexWorkout.isCircuit(complexWorkout[4]!)) // Old 3
		XCTAssertTrue(complexWorkout.isCircuit(complexWorkout[5]!))
		
		complexWorkout.moveExercizeAt(number: 1, to: 5)
		XCTAssertEqual(c0, complexWorkout[5])
		XCTAssertEqual(c4, complexWorkout[0])
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[0]!)) // Old 4
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[1]!)) // Old 1
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[5]!)) // Old 0
		if let (n5, t5) = complexWorkout.circuitStatus(for: complexWorkout[4]!) { // Old 5
			XCTAssertEqual(n5, t5)
			XCTAssertEqual(t5, 2)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testMoveExercizeCircuit() {
		complexWorkout.moveExercizeAt(number: 3, to: 1) // 0,3(now 1),1(now 2) and 4,5 are a circuit; 2(now 3) still not a circuit
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[0]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[1]!) { // Old 3
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!) { // Old 1
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[3]!))
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[4]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[5]!) {
		XCTAssertEqual(n, 2)
		XCTAssertEqual(t, 2)
		} else {
			XCTFail("Unexpected nil")
		}
		
		complexWorkout.moveExercizeAt(number: 2, to: 4) // 0,3(now 1) and 4(now 3),1(now 4),5 are a circuit; 2(now 2 again) still not a circuit
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[0]!) {
		XCTAssertEqual(n, 1)
		XCTAssertEqual(t, 2)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[1]!) {
		XCTAssertEqual(n, 2)
		XCTAssertEqual(t, 2)
		} else {
			XCTFail("Unexpected nil")
		}
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[2]!))
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[3]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[4]!) {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[5]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testMoveExercizeMultipleCircuits() {
		complexWorkout[1]!.makeCircuit(true) // 0,1,2 and 3,4,5 are now a circuit
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[3]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		
		let c2 = complexWorkout[2]!
		complexWorkout.moveExercizeAt(number: 2, to: 1) // 0,1,2 and 3,4,5 are a circuit
		XCTAssertEqual(c2, complexWorkout[1]!)
		if let (n, t) = complexWorkout.circuitStatus(for: c2) {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!) {
			XCTAssertEqual(n, 3)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
		if let (n, t) = complexWorkout.circuitStatus(for: complexWorkout[3]!) {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 3)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testMoveExercizeUnmakeCircuitAfter() {
		complexWorkout[0]!.enableCircuitRest(true)
		complexWorkout[1]!.enableCircuitRest(true)
		
		complexWorkout.moveExercizeAt(number: 1, to: 5)
		
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[0]!))
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[5]!))
		XCTAssertFalse(complexWorkout[0]!.hasCircuitRest)
		XCTAssertFalse(complexWorkout[5]!.hasCircuitRest)
	}
	
	func testMoveExercizeUnmakeCircuitBefore() {
		complexWorkout[0]!.enableCircuitRest(true)
		complexWorkout[1]!.enableCircuitRest(true)
		
		complexWorkout.moveExercizeAt(number: 0, to: 5)
		
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[0]!))
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[5]!))
		XCTAssertFalse(complexWorkout[0]!.hasCircuitRest)
		XCTAssertFalse(complexWorkout[5]!.hasCircuitRest)
	}
	
	func testMoveExercizeNotUnmakeCircuitMid() {
		complexWorkout[3]!.enableCircuitRest(true)
		complexWorkout[4]!.enableCircuitRest(true)
		complexWorkout[5]!.enableCircuitRest(true)
		
		complexWorkout.moveExercizeAt(number: 4, to: 0)
		
		XCTAssertFalse(complexWorkout.isCircuit(complexWorkout[0]!))
		XCTAssertTrue(complexWorkout.isCircuit(complexWorkout[4]!))
		XCTAssertTrue(complexWorkout.isCircuit(complexWorkout[5]!))
		XCTAssertFalse(complexWorkout[0]!.hasCircuitRest)
		XCTAssertTrue(complexWorkout[4]!.hasCircuitRest)
		XCTAssertTrue(complexWorkout[5]!.hasCircuitRest)
	}
    
}
