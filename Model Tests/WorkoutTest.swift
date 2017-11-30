//
//  WorkoutTest.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
import Foundation

class WorkoutTest: XCTestCase {
	
	var workout: Workout!
	var e1, e2, r: Exercize!
    
    override func setUp() {
        super.setUp()
		
		workout = dataManager.newWorkout()
		e1 = dataManager.newExercize(for: workout)
		e1.set(name: "Exercize")
		
		r = dataManager.newExercize(for: workout)
		r.set(rest: 30)
		
		e2 = dataManager.newExercize(for: workout)
		e2.set(name: "Exercize")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreation() {
		XCTAssertEqual(workout.exercizes.count, 3, "Not the expected number of exercizes")
		
		let first = workout.exercize(n: 0)
		XCTAssertNotNil(first, "Missing exercize")
		XCTAssertEqual(first, e1)
		XCTAssertFalse(e1.isRest, "This should be an exercize")
		
		let r = workout.exercize(n: 1)
		XCTAssertNotNil(r, "Missing rest period")
		XCTAssertEqual(r, self.r)
		XCTAssertTrue(r!.isRest, "This should be a rest period")
		
		let last = workout.exercize(n: 2)
		XCTAssertNotNil(last, "Missing exercize")
		XCTAssertEqual(last, e2)
		XCTAssertFalse(e2.isRest, "This should be an exercize")
    }
	
	func testReorderBefore() {
		workout.moveExercizeAt(number: 2, to: 1)
		XCTAssertEqual(workout.exercizes.count, 3, "Some exercizes disappeared")
		XCTAssertEqual(workout.exercize(n: 0), e1)
		XCTAssertEqual(workout.exercize(n: 1), e2)
		XCTAssertEqual(workout.exercize(n: 2), r)
	}
	
	func testReorderAfter() {
		workout.moveExercizeAt(number: 0, to: 1)
		XCTAssertEqual(workout.exercizes.count, 3, "Some exercizes disappeared")
		XCTAssertEqual(workout.exercize(n: 1), e1)
		XCTAssertEqual(workout.exercize(n: 2), e2)
		XCTAssertEqual(workout.exercize(n: 0), r)
	}
	
	func testCompactSimpleEnd() {
		workout.moveExercizeAt(number: 2, to: 1)
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(s.isEmpty)
		XCTAssertTrue(m.isEmpty)
		XCTAssertFalse(e.isEmpty, "Rest not removed")
		
		XCTAssertEqual(workout.exercizes.count, 2)
		XCTAssertEqual(e.first, r)
	}
	
	func testCompactSimpleStart() {
		workout.moveExercizeAt(number: 0, to: 1)
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(e.isEmpty)
		XCTAssertTrue(m.isEmpty)
		XCTAssertFalse(s.isEmpty, "Rest not removed")
		
		XCTAssertEqual(workout.exercizes.count, 2)
		XCTAssertEqual(s.first, r)
	}
	
	func testCompactSimpleMiddle() {
		let r2 = dataManager.newExercize(for: workout)
		r2.set(rest: 30)
		workout.moveExercizeAt(number: 3, to: 1)
		
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(s.isEmpty)
		XCTAssertTrue(e.isEmpty)
		XCTAssertFalse(m.isEmpty, "Rest not removed")
		
		XCTAssertEqual(workout.exercizes.count, 3)
		let (removed, order) = m.first!
		XCTAssertEqual(removed, r)
		XCTAssertEqual(order, 2)
	}
    
}
