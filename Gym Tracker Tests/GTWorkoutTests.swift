//
//  GTWorkoutTests.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class WorkoutTests: XCTestCase {
	
	private var workout: GTWorkout!
	private var e1, e2: GTSimpleSetsExercize!
	private var r: GTRest!
    
    override func setUp() {
        super.setUp()
		
		workout = dataManager.newWorkout()
		e1 = dataManager.newExercize(for: workout)
		e1.set(name: "Exercize")
		
		r = dataManager.newRest(for: workout)
		r.set(rest: 30)
		
		e2 = dataManager.newExercize(for: workout)
		e2.set(name: "Exercize")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
        super.tearDown()
    }
    
    func testCreation() {
		XCTAssertEqual(workout.parts.count, 3, "Not the expected number of exercizes")
		
		let first = workout[0]
		XCTAssertNotNil(first, "Missing exercize")
		XCTAssertEqual(first, e1)
		
		let r = workout[1]
		XCTAssertNotNil(r, "Missing rest period")
		XCTAssertEqual(r, self.r)
		
		let last = workout[2]
		XCTAssertNotNil(last, "Missing exercize")
		XCTAssertEqual(last, e2)
    }
	
	func testReorderBefore() {
		workout.movePartAt(number: 2, to: 1)
		XCTAssertEqual(workout.parts.count, 3, "Some exercizes disappeared")
		XCTAssertEqual(workout[0], e1)
		XCTAssertEqual(workout[1], e2)
		XCTAssertEqual(workout[2], r)
	}
	
	func testReorderAfter() {
		workout.movePartAt(number: 0, to: 1)
		XCTAssertEqual(workout.parts.count, 3, "Some exercizes disappeared")
		XCTAssertEqual(workout[1], e1)
		XCTAssertEqual(workout[2], e2)
		XCTAssertEqual(workout[0], r)
	}
	
	func testCompactSimpleEnd() {
		workout.movePartAt(number: 2, to: 1)
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(s.isEmpty)
		XCTAssertTrue(m.isEmpty)
		XCTAssertEqual(e.count, 1, "Rest not removed")
		XCTAssertEqual(e.first, r, "Removed part is not the rest period")
		XCTAssertEqual(workout.parts.count, 2)
	}
	
	func testCompactSimpleStart() {
		workout.movePartAt(number: 0, to: 1)
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(e.isEmpty)
		XCTAssertTrue(m.isEmpty)
		XCTAssertEqual(s.count, 1, "Rest not removed")
		XCTAssertEqual(s.first, r, "Removed part is not the rest period")
		XCTAssertEqual(workout.parts.count, 2)
	}
	
	func testCompactSimpleMiddle() {
		let r2 = dataManager.newRest(for: workout)
		r2.set(rest: 30)
		workout.movePartAt(number: 3, to: 1)
		
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(s.isEmpty)
		XCTAssertTrue(e.isEmpty)
		XCTAssertEqual(m.count, 1, "Rest not removed")
		
		XCTAssertEqual(workout.parts.count, 3)
		let (removed, order) = m.first!
		XCTAssertEqual(removed, r)
		XCTAssertEqual(order, 2)
	}
    
}
