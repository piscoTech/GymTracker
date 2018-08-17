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
	
	private func newValidExercize() -> GTSimpleSetsExercize {
		let e = dataManager.newExercize()
		e.set(name: "Exercize")
		_ = dataManager.newSet(for: e)
		
		return e
	}
    
    override func setUp() {
        super.setUp()
		
		workout = dataManager.newWorkout()
		e1 = dataManager.newExercize()
		workout.add(parts: e1)
		e1.set(name: "Exercize")
		
		r = dataManager.newRest()
		workout.add(parts: r)
		r.set(rest: 30)
		
		e2 = dataManager.newExercize()
		workout.add(parts: e2)
		e2.set(name: "Exercize")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }
	
	func testIsValid() {
		XCTAssertFalse(workout.isSubtreeValid)
		XCTAssertFalse(workout.isValid)
		
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		
		XCTAssertFalse(workout.isSubtreeValid)
		XCTAssertFalse(workout.isValid)
		workout.set(name: "Workt")
		
		XCTAssertTrue(workout.isSubtreeValid)
		XCTAssertTrue(workout.isValid)
	}
	
	func testPurgeSetting() {
		let e = workout[2] as! GTSimpleSetsExercize
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		workout.purgeInvalidSettings()
		XCTAssertFalse(e.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		workout.add(parts: c)
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		workout.purgeInvalidSettings()
		XCTAssertTrue(e.hasCircuitRest)
	}
	
	func testParent() {
		XCTAssertNil(workout.parentLevel)
		
		let w = dataManager.newWorkout()
		XCTAssertNil(w.parentLevel)
	}
	
	func testSetName() {
		let n = "Workout"
		workout.set(name: n)
		XCTAssertEqual(workout.name, n)
	}
    
    func testSubScript() {
		XCTAssertEqual(workout.exercizes.count, 3, "Not the expected number of exercizes")
		
		let first = workout[0]
		XCTAssertNotNil(first, "Missing exercize")
		XCTAssertEqual(first, e1)
		
		let r = workout[1]
		XCTAssertNotNil(r, "Missing rest period")
		XCTAssertEqual(r, r)
		
		let last = workout[2]
		XCTAssertNotNil(last, "Missing exercize")
		XCTAssertEqual(last, e2)
    }
	
	func testReorderBefore() {
		workout.movePartAt(number: 2, to: 1)
		XCTAssertEqual(workout.exercizes.count, 3, "Some exercizes disappeared")
		XCTAssertEqual(workout[0], e1)
		XCTAssertEqual(workout[1], e2)
		XCTAssertEqual(workout[2], r)
	}
	
	func testReorderAfter() {
		workout.movePartAt(number: 0, to: 1)
		XCTAssertEqual(workout.exercizes.count, 3, "Some exercizes disappeared")
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
		XCTAssertEqual(workout.exercizes.count, 2)
	}
	
	func testCompactSimpleStart() {
		workout.movePartAt(number: 0, to: 1)
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(e.isEmpty)
		XCTAssertTrue(m.isEmpty)
		XCTAssertEqual(s.count, 1, "Rest not removed")
		XCTAssertEqual(s.first, r, "Removed part is not the rest period")
		XCTAssertEqual(workout.exercizes.count, 2)
	}
	
	func testCompactSimpleMiddle() {
		let r2 = dataManager.newRest()
		workout.add(parts: r2)
		r2.set(rest: 30)
		workout.movePartAt(number: 3, to: 1)
		
		let (s, e, m) = workout.compactExercizes()
		XCTAssertTrue(s.isEmpty)
		XCTAssertTrue(e.isEmpty)
		XCTAssertEqual(m.count, 1, "Rest not removed")
		
		XCTAssertEqual(workout.exercizes.count, 3)
		let (removed, order) = m.first!
		XCTAssertEqual(removed, r)
		XCTAssertEqual(order, 2)
	}
	
	func testPartList() {
		XCTAssertEqual(workout.exercizeList, [e1, r, e2])
		
		let w = dataManager.newWorkout()
		XCTAssertEqual(w.exercizeList, [])
		
		let e3 = newValidExercize()
		let e4 = newValidExercize()
		w.add(parts: e4, e3)
		
		XCTAssertEqual(w.exercizeList, [e4, e3])
		XCTAssertEqual(e3.order, 1)
		XCTAssertEqual(e4.order, 0)
		
		w.add(parts: e4)
		XCTAssertEqual(w.exercizeList, [e3, e4])
		XCTAssertEqual(e3.order, 0)
		XCTAssertEqual(e4.order, 1)
	}
	
	func testChoices() {
		XCTAssertEqual(workout.choices, [])
		
		let w = dataManager.newWorkout()
		XCTAssertEqual(w.choices, [])
		
		let e3 = newValidExercize()
		let e4 = newValidExercize()
		w.add(parts: e4, e3)
		
		XCTAssertEqual(w.choices, [])
		let ch1 = dataManager.newChoice()
		let ch2 = dataManager.newChoice()
		let c = dataManager.newCircuit()
		w.add(parts: ch1, c)
		c.add(parts: ch2)
		
		XCTAssertEqual(w.choices, [ch1, ch2])
		w.movePartAt(number: c.order, to: 0)
		XCTAssertEqual(w.choices, [ch2, ch1])
	}
	
	func testRemovePart() {
		XCTAssertEqual(workout.parts.count, 3)
		
		workout.remove(part: e2)
		XCTAssertEqual(workout.exercizes.count, 2)
		XCTAssertEqual(workout[0], e1)
		XCTAssertEqual(workout[1], r)
	}
	
	func testSubtree() {
		var sets = [e1,e2].flatMap { $0!.sets }
		XCTAssertEqual(workout.subtreeNodeList, Set(arrayLiteral: workout, r, e1, e2).union(sets))
		
		let ch1 = dataManager.newChoice()
		let ch2 = dataManager.newChoice()
		let c = dataManager.newCircuit()
		workout.add(parts: ch1, c)
		c.add(parts: ch2, e2)
		
		workout.movePartAt(number: ch1.order, to: 0)
		ch1.add(parts: e1)
		let e3 = newValidExercize()
		ch1.add(parts: e3)
		
		let e4 = newValidExercize()
		let e5 = newValidExercize()
		ch2.add(parts: e4, e5)
		
		sets = [e1,e2,e3,e4,e5].flatMap { $0!.sets }
		XCTAssertEqual(workout.subtreeNodeList, Set(arrayLiteral: workout, r, e1, e2, e3, e4, e5, ch1, ch2, c).union(sets))
	}
    
}
