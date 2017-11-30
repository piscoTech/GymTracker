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
		e7.makeCircuit(true)
		
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
	
	func testCircuitStatus() {
		var (isCirc, n, tot) = workout.circuitStatus(for: workout[0]!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout[1]!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout[4]!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout[6]!)
		XCTAssertTrue(isCirc)
		XCTAssertNotNil(n)
		XCTAssertNotNil(tot)
		XCTAssertEqual(n, 1)
		XCTAssertEqual(tot, 3)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout[7]!)
		XCTAssertTrue(isCirc)
		XCTAssertNotNil(n)
		XCTAssertNotNil(tot)
		XCTAssertEqual(n, 2)
		XCTAssertEqual(tot, 3)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout[8]!)
		XCTAssertTrue(isCirc)
		XCTAssertNotNil(n)
		XCTAssertNotNil(tot)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(tot, 3)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout[14]!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
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
		var (s4, _, _) = workout.circuitStatus(for: e4)
		XCTAssertTrue(s4)
		
		let e6 = workout[6]!
		let e7 = workout[7]!
		let e8 = workout[8]!
		workout.makeCircuit(exercize: e8, isCircuit: false)
		workout.makeCircuit(exercize: e7, isCircuit: false)
		
		XCTAssertFalse(workout[5]!.isCircuit)
		XCTAssertFalse(e6.isCircuit)
		XCTAssertFalse(workout.circuitStatus(for: workout[6]!).isInCircuit)
		XCTAssertFalse(e7.isCircuit)
		XCTAssertFalse(e8.isCircuit)
		let (s8, _, _) = workout.circuitStatus(for: e8)
		XCTAssertFalse(s8)
		
		workout.makeCircuit(exercize: e3, isCircuit: false)
		
		XCTAssertFalse(workout[1]!.isCircuit)
		XCTAssertFalse(e2.isCircuit)
		XCTAssertFalse(e3.isCircuit)
		XCTAssertFalse(e4.isCircuit)
		(s4, _, _) = workout.circuitStatus(for: e4)
		XCTAssertFalse(s4)
		
		XCTAssertTrue(complexWorkout[0]!.isCircuit)
		XCTAssertFalse(complexWorkout[1]!.isCircuit)
		var (s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[1]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 2)
		XCTAssertEqual(t, 2)
		
		XCTAssertFalse(complexWorkout[2]!.isCircuit)
		(s, _, _) = complexWorkout.circuitStatus(for: complexWorkout[2]!)
		XCTAssertFalse(s)
		
		XCTAssertTrue(complexWorkout[3]!.isCircuit)
		XCTAssertTrue(complexWorkout[4]!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[5]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 3)
		
		complexWorkout.makeCircuit(exercize: complexWorkout[2]!, isCircuit: true) // Whole workout is a circuit
		XCTAssertTrue(complexWorkout[2]!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 6)
		
		complexWorkout.makeCircuit(exercize: complexWorkout[2]!, isCircuit: false) // Back to 0,1 and 3,4,5
		XCTAssertTrue(complexWorkout[0]!.isCircuit)
		XCTAssertFalse(complexWorkout[1]!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[1]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 2)
		XCTAssertEqual(t, 2)
		
		XCTAssertFalse(complexWorkout[2]!.isCircuit)
		(s, _, _) = complexWorkout.circuitStatus(for: complexWorkout[2]!)
		XCTAssertFalse(s)
		
		XCTAssertTrue(complexWorkout[3]!.isCircuit)
		XCTAssertTrue(complexWorkout[4]!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[5]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 3)
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
		var (s, _, _) = workout.circuitStatus(for: workout[2]!)
		XCTAssertTrue(s)
		
		XCTAssertTrue(complexWorkout.canChainCircuit(for: complexWorkout[2]!))
		(s, _, _) = complexWorkout.circuitStatus(for: complexWorkout[2]!)
		XCTAssertTrue(s)
	}
	
	func testChainCircuit() {
		complexWorkout.chainCircuit(for: complexWorkout[1]!, chain: true)
		var (s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 3)
		
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[3]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 1)
		XCTAssertEqual(t, 3)
		
		complexWorkout.chainCircuit(for: complexWorkout[2]!, chain: true)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[2]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 6)
		
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout[3]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 4)
		XCTAssertEqual(t, 6)
		
		workout.chainCircuit(for: workout[7]!, chain: false)
		(s, _, _) = workout.circuitStatus(for: workout[8]!)
		XCTAssertFalse(s)
		(s, n, t) = workout.circuitStatus(for: workout[7]!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 2)
		XCTAssertEqual(t, 2)
		
		workout.chainCircuit(for: workout[6]!, chain: false)
		XCTAssertFalse(workout.circuitStatus(for: workout[6]!).isInCircuit)
		XCTAssertFalse(workout.circuitStatus(for: workout[7]!).isInCircuit)
	}
	
	func testEnableRestPeriod() {
		XCTFail()
	}
    
}
