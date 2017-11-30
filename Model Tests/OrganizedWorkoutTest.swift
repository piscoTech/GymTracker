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
		_ = newExercize()
		_ = newExercize() // 1
		_ = newExercize()
		_ = newExercize() // 3
		_ = newExercize()
		_ = newExercize() // 5
		complexWorkout = OrganizedWorkout(raw)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testCircuitStatus() {
		var (isCirc, n, tot) = workout.circuitStatus(for: workout.exercize(n: 0)!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout.exercize(n: 1)!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout.exercize(n: 4)!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout.exercize(n: 6)!)
		XCTAssertTrue(isCirc)
		XCTAssertNotNil(n)
		XCTAssertNotNil(tot)
		XCTAssertEqual(n, 1)
		XCTAssertEqual(tot, 3)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout.exercize(n: 7)!)
		XCTAssertTrue(isCirc)
		XCTAssertNotNil(n)
		XCTAssertNotNil(tot)
		XCTAssertEqual(n, 2)
		XCTAssertEqual(tot, 3)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout.exercize(n: 8)!)
		XCTAssertTrue(isCirc)
		XCTAssertNotNil(n)
		XCTAssertNotNil(tot)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(tot, 3)
		
		(isCirc, n, tot) = workout.circuitStatus(for: workout.exercize(n: 14)!)
		XCTAssertFalse(isCirc)
		XCTAssertNil(n)
		XCTAssertNil(tot)
	}
    
    func testCanBecomeCircuit() {
		// No exercize after and no circuit before
        XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 0)!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 10)!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 14)!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 4)!))
		
		// Exercize after
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout.exercize(n: 2)!))
		
		// Already in circuit
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout.exercize(n: 6)!))
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout.exercize(n: 7)!))
		
		// Is rest
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 1)!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 5)!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 9)!))
		XCTAssertFalse(workout.canBecomeCircuit(exercize: workout.exercize(n: 11)!))
		
		// No exercize after but circuit before
		XCTAssertTrue(workout.canBecomeCircuit(exercize: workout.exercize(n: 8)!))
    }
	
	func testMakeCircuit() {
		let e2 = workout.exercize(n: 2)!
		let e3 = workout.exercize(n: 3)!
		let e4 = workout.exercize(n: 4)!
		workout.makeCircuit(exercize: e3, isCircuit: true)
		workout.makeCircuit(exercize: e2, isCircuit: true)
		
		XCTAssertTrue(e2.isCircuit)
		XCTAssertTrue(e3.isCircuit)
		XCTAssertFalse(e4.isCircuit)
		var (s4, _, _) = workout.circuitStatus(for: e4)
		XCTAssertTrue(s4)
		
		let e6 = workout.exercize(n: 6)!
		let e7 = workout.exercize(n: 7)!
		let e8 = workout.exercize(n: 8)!
		workout.makeCircuit(exercize: e8, isCircuit: false)
		workout.makeCircuit(exercize: e7, isCircuit: false)
		
		XCTAssertFalse(workout.exercize(n: 5)!.isCircuit)
		XCTAssertFalse(e6.isCircuit)
		XCTAssertFalse(e7.isCircuit)
		XCTAssertFalse(e8.isCircuit)
		let (s8, _, _) = workout.circuitStatus(for: e8)
		XCTAssertFalse(s8)
		
		workout.makeCircuit(exercize: e3, isCircuit: false)
		
		XCTAssertFalse(workout.exercize(n: 1)!.isCircuit)
		XCTAssertFalse(e2.isCircuit)
		XCTAssertFalse(e3.isCircuit)
		XCTAssertFalse(e4.isCircuit)
		(s4, _, _) = workout.circuitStatus(for: e4)
		XCTAssertFalse(s4)
		
		complexWorkout.makeCircuit(exercize: complexWorkout.exercize(n: 0)!, isCircuit: true) // 0,1 is now a circuit
		complexWorkout.makeCircuit(exercize: complexWorkout.exercize(n: 4)!, isCircuit: true) // 4,5 is now a circuit
		complexWorkout.makeCircuit(exercize: complexWorkout.exercize(n: 3)!, isCircuit: true) // 3,4,5 is now a circuit
		
		XCTAssertTrue(complexWorkout.exercize(n: 0)!.isCircuit)
		XCTAssertFalse(complexWorkout.exercize(n: 1)!.isCircuit)
		var (s, n, t) = complexWorkout.circuitStatus(for: complexWorkout.exercize(n: 1)!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 2)
		XCTAssertEqual(t, 2)
		
		XCTAssertFalse(complexWorkout.exercize(n: 2)!.isCircuit)
		(s, _, _) = complexWorkout.circuitStatus(for: complexWorkout.exercize(n: 2)!)
		XCTAssertFalse(s)
		
		XCTAssertTrue(complexWorkout.exercize(n: 3)!.isCircuit)
		XCTAssertTrue(complexWorkout.exercize(n: 4)!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout.exercize(n: 5)!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 3)
		
		complexWorkout.makeCircuit(exercize: complexWorkout.exercize(n: 2)!, isCircuit: true) // Whole workout is a circuit
		XCTAssertTrue(complexWorkout.exercize(n: 2)!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout.exercize(n: 2)!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 6)
		
		complexWorkout.makeCircuit(exercize: complexWorkout.exercize(n: 2)!, isCircuit: false) // Back to 0,1 and 3,4,5
		XCTAssertTrue(complexWorkout.exercize(n: 0)!.isCircuit)
		XCTAssertFalse(complexWorkout.exercize(n: 1)!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout.exercize(n: 1)!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 2)
		XCTAssertEqual(t, 2)
		
		XCTAssertFalse(complexWorkout.exercize(n: 2)!.isCircuit)
		(s, _, _) = complexWorkout.circuitStatus(for: complexWorkout.exercize(n: 2)!)
		XCTAssertFalse(s)
		
		XCTAssertTrue(complexWorkout.exercize(n: 3)!.isCircuit)
		XCTAssertTrue(complexWorkout.exercize(n: 4)!.isCircuit)
		(s, n, t) = complexWorkout.circuitStatus(for: complexWorkout.exercize(n: 5)!)
		XCTAssertTrue(s)
		XCTAssertEqual(n, 3)
		XCTAssertEqual(t, 3)
	}
	
	func testCanChainCircuit() {
		XCTFail()
	}
	
	func testChainCircuit() {
		XCTFail()
	}
	
	func testEnableRestPeriod() {
		XCTFail()
	}
    
}
