//
//  WorkoutIteratorTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
import MBLibrary
@testable import Gym_Tracker

class WorkoutIteratorTests: XCTestCase {
	
	private var workout: OrganizedWorkout!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		let w = dataManager.newWorkout()
		let ow = OrganizedWorkout(w)
		ow.name = "Workout"
		
		var e = dataManager.newExercize(for: w)
		e.set(name: "Exercize 1")
		var s = dataManager.newSet(for: e)
		s.set(reps: 10)
		s.set(weight: 0)
		s.set(rest: 0)
		s = dataManager.newSet(for: e)
		s.set(reps: 5)
		s.set(weight: 8)
		s.set(rest: 90)
		
		e = dataManager.newExercize(for: w)
		e.set(name: "Exercize 2")
		s = dataManager.newSet(for: e)
		s.set(reps: 12)
		s.set(weight: 4)
		s.set(rest: 60)
		s = dataManager.newSet(for: e)
		s.set(reps: 10)
		s.set(weight: 6)
		s.set(rest: 60)
		
		e = dataManager.newExercize(for: w)
		let rest = 4 * 60.0
		e.set(rest: rest)
		
		e = dataManager.newExercize(for: w)
		e.set(name: "Exercize 3")
		s = dataManager.newSet(for: e)
		s.set(reps: 15)
		s.set(weight: 0)
		s.set(rest: 60)
		
		self.workout = ow
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
        super.tearDown()
    }
	
	func testInvalidWorkout() {
		let iter = WorkoutIterator(OrganizedWorkout(dataManager.newWorkout()))
		XCTAssertNil(iter.next())
	}
	
	func testStepCount() {
		var count = 0
		let iter = WorkoutIterator(workout)
		while let _ = iter.next() {
			count += 1
		}
		
		XCTAssertEqual(count, 6)
	}
	
	func testOtherSetsNoWeightIsLastFlag() {
		let w = dataManager.newWorkout()
		let ow = OrganizedWorkout(w)
		ow.name = "Workout"
		
		let e = dataManager.newExercize(for: w)
		e.set(name: "E")
		var s = dataManager.newSet(for: e)
		s.set(reps: 10)
		s.set(weight: 0)
		s.set(rest: 30)
		s = dataManager.newSet(for: e)
		s.set(reps: 10)
		s.set(weight: 0)
		s.set(rest: 30)
		s = dataManager.newSet(for: e)
		s.set(reps: 10)
		s.set(weight: 0)
		s.set(rest: 30)
		
		let iter = WorkoutIterator(ow)
		if let s1 = iter.next() {
			if let othSets = s1.otherPartsInfo?.string {
				assert(string: othSets, containsInOrder: ["2", "0", "0"])
			} else {
				XCTFail("Unexpected nil")
			}
			XCTAssertFalse(s1.isLast)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let s2 = iter.next() {
			if let othSets = s2.otherPartsInfo?.string {
				assert(string: othSets, containsInOrder: ["1", "0"])
			} else {
				XCTFail("Unexpected nil")
			}
			XCTAssertFalse(s2.isLast)
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let s3 = iter.next() {
			XCTAssertNil(s3.otherPartsInfo)
			XCTAssertTrue(s3.isLast)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
    func testSimpleWorkout() {
		let iter = WorkoutIterator(workout)
		do { // First exercize
			let e = workout[0]!
			let s1 = e[0]!
			let s2 = e[1]!
			
			if let step1 = iter.next() {
				XCTAssertEqual(step1.exercizeName, e.name)
				if let curRep = step1.currentReps?.string {
					assert(string: curRep, containsInOrder: [s1.reps.description], thenNotContains: timesSign)
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step1.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["1", s2.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step1.rest)
				
				if let next = step1.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e.next!.name!, e.next![0]!.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step1.isRest)
				XCTAssertEqual(step1.set, s1)
				XCTAssertFalse(step1.isLast)
				
				if let details1 = step1 as? WorkoutExercizeStep {
					XCTAssertEqual(details1.reps.reps, Int(s1.reps))
					XCTAssertEqual(details1.reps.weight, s1.weight)
					XCTAssertEqual(details1.reps.change, 0)
					
					XCTAssertEqual(details1.otherWeights, [s2.weight])
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next1 = step1.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next1.exercizeName, e.next!.name!)
					XCTAssertEqual(next1.weight, e.next![0]!.weight)
					XCTAssertEqual(next1.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step2 = iter.next() {
				XCTAssertEqual(step2.exercizeName, e.name)
				if let curRep = step2.currentReps?.string {
					assert(string: curRep, containsInOrder: [s2.reps.description, timesSign, s2.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step2.otherPartsInfo)
				XCTAssertNil(step2.rest)
				
				if let next = step2.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e.next!.name!, e.next![0]!.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step2.isRest)
				XCTAssertEqual(step2.set, s2)
				XCTAssertFalse(step2.isLast)
				
				if let details2 = step2 as? WorkoutExercizeStep {
					XCTAssertEqual(details2.reps.reps, Int(s2.reps))
					XCTAssertEqual(details2.reps.weight, s2.weight)
					XCTAssertEqual(details2.reps.change, 0)
					
					XCTAssertEqual(details2.otherWeights, [])
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next2 = step2.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next2.exercizeName, e.next!.name!)
					XCTAssertEqual(next2.weight, e.next![0]!.weight)
					XCTAssertEqual(next2.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
		}
		
		do { // Second exercize
			let e = workout[1]!
			let s1 = e[0]!
			let s2 = e[1]!
			
			if let step3 = iter.next() {
				XCTAssertEqual(step3.exercizeName, e.name)
				if let curRep = step3.currentReps?.string {
					assert(string: curRep, containsInOrder: [s1.reps.description, timesSign, s1.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step3.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["1", s2.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertEqual(s1.rest, step3.rest)
				
				if let next = step3.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e.next!.rest.getDuration(hideHours: true)])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step3.isRest)
				XCTAssertEqual(step3.set, s1)
				XCTAssertFalse(step3.isLast)
				
				if let details3 = step3 as? WorkoutExercizeStep {
					XCTAssertEqual(details3.reps.reps, Int(s1.reps))
					XCTAssertEqual(details3.reps.weight, s1.weight)
					XCTAssertEqual(details3.reps.change, 0)
					
					XCTAssertEqual(details3.otherWeights, [s2.weight])
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next3 = step3.nextUp as? WorkoutStepNextRest {
					XCTAssertEqual(next3.rest, e.next!.rest)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step4 = iter.next() {
				XCTAssertEqual(step4.exercizeName, e.name)
				if let curRep = step4.currentReps?.string {
					assert(string: curRep, containsInOrder: [s2.reps.description, timesSign, s2.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step4.otherPartsInfo)
				XCTAssertNil(step4.rest)
				
				if let next = step4.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e.next!.rest.getDuration(hideHours: true)])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step4.isRest)
				XCTAssertEqual(step4.set, s2)
				XCTAssertFalse(step4.isLast)
				
				if let details4 = step4 as? WorkoutExercizeStep {
					XCTAssertEqual(details4.reps.reps, Int(s2.reps))
					XCTAssertEqual(details4.reps.weight, s2.weight)
					XCTAssertEqual(details4.reps.change, 0)
					
					XCTAssertEqual(details4.otherWeights, [])
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next4 = step4.nextUp as? WorkoutStepNextRest {
					XCTAssertEqual(next4.rest, e.next!.rest)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
		}
		
		do { // Rest
			let e = workout[2]!
			
			if let step5 = iter.next() {
				XCTAssertNil(step5.exercizeName)
				XCTAssertNil(step5.currentReps)
				XCTAssertNil(step5.otherPartsInfo)
				
				XCTAssertEqual(step5.rest, e.rest)
				
				if let next = step5.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e.next!.name!], thenNotContains: e.next![0]!.weight.toString())
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertTrue(step5.isRest)
				XCTAssertNil(step5.set)
				XCTAssertFalse(step5.isLast)
				
				XCTAssertTrue(step5 is WorkoutRestStep)
				if let next5 = step5.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next5.exercizeName, e.next!.name!)
					XCTAssertEqual(next5.weight, e.next![0]!.weight)
					XCTAssertEqual(next5.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
		}
		
		do { // Third exercize
			let e = workout[3]!
			let s1 = e[0]!
			
			if let step6 = iter.next() {
				XCTAssertEqual(step6.exercizeName, e.name)
				if let curRep = step6.currentReps?.string {
					assert(string: curRep, containsInOrder: [s1.reps.description], thenNotContains: timesSign)
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step6.otherPartsInfo)
				XCTAssertNil(step6.rest)
				XCTAssertNil(step6.nextUpInfo)
				
				XCTAssertFalse(step6.isRest)
				XCTAssertEqual(step6.set, s1)
				XCTAssertTrue(step6.isLast)
				
				if let details6 = step6 as? WorkoutExercizeStep {
					XCTAssertEqual(details6.reps.reps, Int(s1.reps))
					XCTAssertEqual(details6.reps.weight, s1.weight)
					XCTAssertEqual(details6.reps.change, 0)
					
					XCTAssertEqual(details6.otherWeights, [])
				} else {
					XCTFail("Invalid class found")
				}
				
				XCTAssertNil(step6.nextUp)
			} else {
				XCTFail("Unexpected nil")
			}
		}
		
		XCTAssertNil(iter.next())
    }
	
	func testCircuitWorkout() {
		let e1 = workout[0]!
		let e2 = workout[1]!
		
		let s5 = dataManager.newSet(for: e1)
		s5.set(reps: 8)
		s5.set(weight: 8)
		s5.set(rest: 90)
		
		let s6 = dataManager.newSet(for: e2)
		s6.set(reps: 10)
		s6.set(weight: 11)
		s6.set(rest: 60)
		
		workout.makeCircuit(exercize: e1, isCircuit: true)
		workout.enableCircuitRestPeriods(for: e1, enable: true)
		
		let iter = WorkoutIterator(workout)
		do { // Circuit
			let s1 = e1[0]!
			let s2 = e2[0]!
			let s3 = e1[1]!
			let s4 = e2[1]!
			
			if let step1 = iter.next() {
				XCTAssertEqual(step1.exercizeName, e1.name)
				if let curRep = step1.currentReps?.string {
					assert(string: curRep, containsInOrder: [s1.reps.description], thenNotContains: timesSign)
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step1.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["1", "2", "1", "3"])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step1.rest)
				
				if let next = step1.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e2.name!, s2.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step1.isRest)
				XCTAssertEqual(step1.set, s1)
				XCTAssertFalse(step1.isLast)
				
				if let details1 = step1 as? WorkoutCircuitStep {
					XCTAssertEqual(details1.reps.reps, Int(s1.reps))
					XCTAssertEqual(details1.reps.weight, s1.weight)
					XCTAssertEqual(details1.reps.change, 0)
					
					XCTAssertEqual(details1.circuitCompletion.exercize, 1)
					XCTAssertEqual(details1.circuitCompletion.totalExercizes, 2)
					XCTAssertEqual(details1.circuitCompletion.round, 1)
					XCTAssertEqual(details1.circuitCompletion.totalRounds, 3)
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next1 = step1.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next1.exercizeName, e2.name!)
					XCTAssertEqual(next1.weight, s2.weight)
					XCTAssertEqual(next1.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step2 = iter.next() {
				XCTAssertEqual(step2.exercizeName, e2.name)
				if let curRep = step2.currentReps?.string {
					assert(string: curRep, containsInOrder: [s2.reps.description, timesSign, s2.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step2.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["2", "2", "1", "3"])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step2.rest)
				
				if let next = step2.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e1.name!, s3.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step2.isRest)
				XCTAssertEqual(step2.set, s2)
				XCTAssertFalse(step2.isLast)
				
				if let details2 = step2 as? WorkoutCircuitStep {
					XCTAssertEqual(details2.reps.reps, Int(s2.reps))
					XCTAssertEqual(details2.reps.weight, s2.weight)
					XCTAssertEqual(details2.reps.change, 0)
					
					XCTAssertEqual(details2.circuitCompletion.exercize, 2)
					XCTAssertEqual(details2.circuitCompletion.totalExercizes, 2)
					XCTAssertEqual(details2.circuitCompletion.round, 1)
					XCTAssertEqual(details2.circuitCompletion.totalRounds, 3)
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next2 = step2.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next2.exercizeName, e1.name!)
					XCTAssertEqual(next2.weight, s3.weight)
					XCTAssertEqual(next2.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step3 = iter.next() {
				XCTAssertEqual(step3.exercizeName, e1.name)
				if let curRep = step3.currentReps?.string {
					assert(string: curRep, containsInOrder: [s3.reps.description, timesSign, s3.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step3.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["1", "2", "2", "3"])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertEqual(s3.rest, step3.rest)
				
				if let next = step3.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e2.name!, s4.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step3.isRest)
				XCTAssertEqual(step3.set, s3)
				XCTAssertFalse(step3.isLast)
				
				if let details3 = step3 as? WorkoutCircuitStep {
					XCTAssertEqual(details3.reps.reps, Int(s3.reps))
					XCTAssertEqual(details3.reps.weight, s3.weight)
					XCTAssertEqual(details3.reps.change, 0)
					
					XCTAssertEqual(details3.circuitCompletion.exercize, 1)
					XCTAssertEqual(details3.circuitCompletion.totalExercizes, 2)
					XCTAssertEqual(details3.circuitCompletion.round, 2)
					XCTAssertEqual(details3.circuitCompletion.totalRounds, 3)
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next3 = step3.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next3.exercizeName, e2.name!)
					XCTAssertEqual(next3.weight, s4.weight)
					XCTAssertEqual(next3.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step4 = iter.next() {
				XCTAssertEqual(step4.exercizeName, e2.name)
				if let curRep = step4.currentReps?.string {
					assert(string: curRep, containsInOrder: [s4.reps.description, timesSign, s4.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step4.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["2", "2", "2", "3"])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step4.rest)
				
				if let next = step4.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e1.name!, s5.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step4.isRest)
				XCTAssertEqual(step4.set, s4)
				XCTAssertFalse(step4.isLast)
				
				if let details4 = step4 as? WorkoutCircuitStep {
					XCTAssertEqual(details4.reps.reps, Int(s4.reps))
					XCTAssertEqual(details4.reps.weight, s4.weight)
					XCTAssertEqual(details4.reps.change, 0)
					
					XCTAssertEqual(details4.circuitCompletion.exercize, 2)
					XCTAssertEqual(details4.circuitCompletion.totalExercizes, 2)
					XCTAssertEqual(details4.circuitCompletion.round, 2)
					XCTAssertEqual(details4.circuitCompletion.totalRounds, 3)
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next4 = step4.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next4.exercizeName, e1.name!)
					XCTAssertEqual(next4.weight, s5.weight)
					XCTAssertEqual(next4.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step5 = iter.next() {
				XCTAssertEqual(step5.exercizeName, e1.name)
				if let curRep = step5.currentReps?.string {
					assert(string: curRep, containsInOrder: [s5.reps.description, timesSign, s5.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step5.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["1", "2", "3", "3"])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertEqual(s5.rest, step5.rest)
				
				if let next = step5.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e2.name!, s6.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step5.isRest)
				XCTAssertEqual(step5.set, s5)
				XCTAssertFalse(step5.isLast)
				
				if let details5 = step5 as? WorkoutCircuitStep {
					XCTAssertEqual(details5.reps.reps, Int(s5.reps))
					XCTAssertEqual(details5.reps.weight, s5.weight)
					XCTAssertEqual(details5.reps.change, 0)
					
					XCTAssertEqual(details5.circuitCompletion.exercize, 1)
					XCTAssertEqual(details5.circuitCompletion.totalExercizes, 2)
					XCTAssertEqual(details5.circuitCompletion.round, 3)
					XCTAssertEqual(details5.circuitCompletion.totalRounds, 3)
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next5 = step5.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next5.exercizeName, e2.name!)
					XCTAssertEqual(next5.weight, s6.weight)
					XCTAssertEqual(next5.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step6 = iter.next() {
				XCTAssertEqual(step6.exercizeName, e2.name)
				if let curRep = step6.currentReps?.string {
					assert(string: curRep, containsInOrder: [s6.reps.description, timesSign, s6.weight.toString()])
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step6.otherPartsInfo?.string {
					assert(string: othSets, containsInOrder: ["2", "2", "3", "3"])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step6.rest)
				
				if let next = step6.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e2.next!.rest.getDuration(hideHours: true)])
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step6.isRest)
				XCTAssertEqual(step6.set, s6)
				XCTAssertFalse(step6.isLast)
				
				if let details6 = step6 as? WorkoutCircuitStep {
					XCTAssertEqual(details6.reps.reps, Int(s6.reps))
					XCTAssertEqual(details6.reps.weight, s6.weight)
					XCTAssertEqual(details6.reps.change, 0)
					
					XCTAssertEqual(details6.circuitCompletion.exercize, 2)
					XCTAssertEqual(details6.circuitCompletion.totalExercizes, 2)
					XCTAssertEqual(details6.circuitCompletion.round, 3)
					XCTAssertEqual(details6.circuitCompletion.totalRounds, 3)
				} else {
					XCTFail("Invalid class found")
				}
				
				if let next6 = step6.nextUp as? WorkoutStepNextRest {
					XCTAssertEqual(next6.rest, e2.next!.rest)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
		}
		
		do { // Rest
			let e = workout[2]!
			
			if let step5 = iter.next() {
				XCTAssertNil(step5.exercizeName)
				XCTAssertNil(step5.currentReps)
				XCTAssertNil(step5.otherPartsInfo)
				
				XCTAssertEqual(step5.rest, e.rest)
				
				if let next = step5.nextUpInfo?.string {
					assert(string: next, containsInOrder: [e.next!.name!], thenNotContains: e.next![0]!.weight.toString())
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertTrue(step5.isRest)
				XCTAssertNil(step5.set)
				XCTAssertFalse(step5.isLast)
				
				XCTAssertTrue(step5 is WorkoutRestStep)
				if let next5 = step5.nextUp as? WorkoutStepNextSet {
					XCTAssertEqual(next5.exercizeName, e.next!.name!)
					XCTAssertEqual(next5.weight, e.next![0]!.weight)
					XCTAssertEqual(next5.change, 0)
				} else {
					XCTFail("Invalid class found")
				}
			} else {
				XCTFail("Unexpected nil")
			}
		}
		
		do { // Exercize
			let e = workout[3]!
			let s1 = e[0]!
			
			if let step6 = iter.next() {
				XCTAssertEqual(step6.exercizeName, e.name)
				if let curRep = step6.currentReps?.string {
					assert(string: curRep, containsInOrder: [s1.reps.description], thenNotContains: timesSign)
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step6.otherPartsInfo)
				XCTAssertNil(step6.rest)
				XCTAssertNil(step6.nextUpInfo)
				
				XCTAssertFalse(step6.isRest)
				XCTAssertEqual(step6.set, s1)
				XCTAssertTrue(step6.isLast)
				
				if let details6 = step6 as? WorkoutExercizeStep {
					XCTAssertEqual(details6.reps.reps, Int(s1.reps))
					XCTAssertEqual(details6.reps.weight, s1.weight)
					XCTAssertEqual(details6.reps.change, 0)
					
					XCTAssertEqual(details6.otherWeights, [])
				} else {
					XCTFail("Invalid class found")
				}
				
				XCTAssertNil(step6.nextUp)
			} else {
				XCTFail("Unexpected nil")
			}
		}
		
		XCTAssertNil(iter.next())
	}
	
	func testCircuitWorkoutDifferentRestPattern() {
		let e1 = workout[0]!
		let e2 = workout[1]!
		
		let s5 = dataManager.newSet(for: e1)
		s5.set(reps: 8)
		s5.set(weight: 8)
		s5.set(rest: 90)
		
		let s6 = dataManager.newSet(for: e2)
		s6.set(reps: 10)
		s6.set(weight: 11)
		s6.set(rest: 60)
		
		workout.makeCircuit(exercize: e1, isCircuit: true)
		workout.enableCircuitRestPeriods(for: e2, enable: true)
		
		let iter = WorkoutIterator(workout)
		do { // Circuit
			let s1 = e1[0]!
			let s2 = e2[0]!
			let s3 = e1[1]!
			let s4 = e2[1]!
			
			if let step1 = iter.next() {
				XCTAssertNil(step1.rest)
				XCTAssertFalse(step1.isRest)
				XCTAssertEqual(step1.set, s1)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step2 = iter.next() {
				XCTAssertEqual(step2.rest, s2.rest)
				XCTAssertFalse(step2.isRest)
				XCTAssertEqual(step2.set, s2)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step3 = iter.next() {
				XCTAssertNil(step3.rest)
				XCTAssertFalse(step3.isRest)
				XCTAssertEqual(step3.set, s3)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step4 = iter.next() {
				XCTAssertEqual(step4.rest, s4.rest)
				XCTAssertFalse(step4.isRest)
				XCTAssertEqual(step4.set, s4)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step5 = iter.next() {
				XCTAssertNil(step5.rest)
				XCTAssertFalse(step5.isRest)
				XCTAssertEqual(step5.set, s5)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let step6 = iter.next() {
				XCTAssertNil(step6.rest)
				XCTAssertFalse(step6.isRest)
				XCTAssertEqual(step6.set, s6)
			} else {
				XCTFail("Unexpected nil")
			}
		}
	}
	
	func testLoadInvalidState() {
		let iter = WorkoutIterator(workout, using: dataManager.preferences)
		_ = iter.next()
		
		dataManager.preferences.currentExercize = -1
		dataManager.preferences.currentPart = -1
		iter.loadPersistedState()
		if let step = iter.next() {
			XCTAssertEqual(step.set, workout[0]![0]!)
		} else {
			XCTFail("Unexpected nil")
		}
		
		dataManager.preferences.currentExercize = 0
		dataManager.preferences.currentPart = 100
		iter.loadPersistedState()
		if let step = iter.next() {
			XCTAssertEqual(step.set, workout[1]![0]!)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testResumeOnRest() {
		var iter = WorkoutIterator(workout, using: dataManager.preferences)
		_ = iter.next()
		_ = iter.next() // First exercize is done
		_ = iter.next()
		_ = iter.next() // Second exercize is done
		_ = iter.next() // Rest
		iter.persistState()
		
		XCTAssertEqual(dataManager.preferences.currentExercize, 2)
		XCTAssertEqual(dataManager.preferences.currentPart, 0)
		
		iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.loadPersistedState()
		if let rest = iter.next() {
			XCTAssertTrue(rest.isRest)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testSimpleWorkoutSaveLoadState() {
		var iter = WorkoutIterator(workout, using: dataManager.preferences)
		_ = iter.next()
		_ = iter.next()
		iter.persistState()

		XCTAssertEqual(dataManager.preferences.currentExercize, 0)
		XCTAssertEqual(dataManager.preferences.currentPart, 1)
		
		iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.loadPersistedState()
		if let step2 = iter.next() {
			let e = workout[0]!
			let s2 = e[1]!
			XCTAssertEqual(step2.exercizeName, e.name)
			XCTAssertNil(step2.rest)
			XCTAssertFalse(step2.isRest)
			XCTAssertEqual(step2.set, s2)
			
			if let details2 = step2 as? WorkoutExercizeStep {
				XCTAssertEqual(details2.reps.reps, Int(s2.reps))
				XCTAssertEqual(details2.reps.weight, s2.weight)
				
				XCTAssertEqual(details2.otherWeights, [])
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
		_ = iter.next()
		iter.persistState()
		
		XCTAssertEqual(dataManager.preferences.currentExercize, 1)
		XCTAssertEqual(dataManager.preferences.currentPart, 0)
		
		iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.loadPersistedState()
		if let step3 = iter.next() {
			let e = workout[1]!
			let s1 = e[0]!
			XCTAssertEqual(step3.exercizeName, e.name)
			XCTAssertEqual(s1.rest, step3.rest)
			XCTAssertFalse(step3.isRest)
			XCTAssertEqual(step3.set, s1)
			
			if let details3 = step3 as? WorkoutExercizeStep {
				XCTAssertEqual(details3.reps.reps, Int(s1.reps))
				XCTAssertEqual(details3.reps.weight, s1.weight)
				
				XCTAssertEqual(details3.otherWeights.count, 1)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testCircuitWorkoutSaveLoadState() {
		workout.makeCircuit(exercize: workout[0]!, isCircuit: true)
		workout.enableCircuitRestPeriods(for: workout[0]!, enable: true)
		var iter = WorkoutIterator(workout, using: dataManager.preferences)
		_ = iter.next()
		_ = iter.next()
		_ = iter.next()
		_ = iter.next()
		iter.persistState()
		
		XCTAssertEqual(dataManager.preferences.currentExercize, 0)
		XCTAssertEqual(dataManager.preferences.currentPart, 3)
		
		iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.loadPersistedState()
		if let step4 = iter.next() {
			let e = workout[1]!
			let s = e[1]!
			XCTAssertEqual(step4.exercizeName, e.name)
			XCTAssertNil(step4.rest)
			XCTAssertFalse(step4.isRest)
			XCTAssertEqual(step4.set, s)
			
			if let details4 = step4 as? WorkoutCircuitStep {
				XCTAssertEqual(details4.reps.reps, Int(s.reps))
				XCTAssertEqual(details4.reps.weight, s.weight)
				
				XCTAssertEqual(details4.circuitCompletion.exercize, 2)
				XCTAssertEqual(details4.circuitCompletion.totalExercizes, 2)
				XCTAssertEqual(details4.circuitCompletion.round, 2)
				XCTAssertEqual(details4.circuitCompletion.totalRounds, 2)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
		
		_ = iter.next()
		iter.persistState()
		
		XCTAssertEqual(dataManager.preferences.currentExercize, 1)
		XCTAssertEqual(dataManager.preferences.currentPart, 0)
		
		iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.loadPersistedState()
		if let step4 = iter.next() {
			let e = workout[2]!
			XCTAssertNil(step4.exercizeName)
			XCTAssertEqual(e.rest, step4.rest)
			XCTAssertTrue(step4.isRest)
			XCTAssertNil(step4.set)
			
			XCTAssertTrue(step4 is WorkoutRestStep)
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testWeightChange() {
		let e = workout[1]!
		let w = 35.3
		var iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.setWeightChange(w, for: e)
		XCTAssertEqual(w.rounded(to: 0.5), iter.weightChange(for: e))
		iter.persistState()
		
		iter = WorkoutIterator(workout, using: dataManager.preferences)
		XCTAssertEqual(0, iter.weightChange(for: e))
		iter.loadPersistedState()
		XCTAssertEqual(w.rounded(to: 0.5), iter.weightChange(for: e))
	}
	
	func testDestroyPersistedState() {
		let e = workout[1]!
		var iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.setWeightChange(99, for: e)
		iter.persistState()
		
		iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.destroyPersistedState()
		iter.loadPersistedState()
		XCTAssertEqual(iter.weightChange(for: e), 0)
	}
	
	func testWeightDescriptionLimits() {
		XCTAssertNil(0.0.weightDescription(withChange: 0))
		XCTAssertNil(0.0.weightDescription(withChange: -1))
		if let desc = 0.0.weightDescription(withChange: 3)?.string {
			assert(string: desc, containsInOrder: ["0", plusSign, "3"])
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let desc = 10.0.weightDescription(withChange: -10)?.string {
			assert(string: desc, containsInOrder: ["10", minusSign, "10"])
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let desc = 10.0.weightDescription(withChange: -20)?.string {
			assert(string: desc, containsInOrder: ["10", minusSign, "10"])
		} else {
			XCTFail("Unexpected nil")
		}
		
		XCTAssertEqual("0", 0.0.weightDescriptionEvenForZero(withChange: 0).string)
		XCTAssertEqual("0", 0.0.weightDescriptionEvenForZero(withChange: -1).string)
	}
	
	func testWeightChangeSimpleWorkout() {
		let e1 = workout[0]!
		let e2 = workout[1]!
		let w1 = 7.5
		let w2 = -6.0
		let iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.setWeightChange(w1, for: e1)
		iter.setWeightChange(w2, for: e2)
		
		let s1 = e1[0]!
		let s2 = e1[1]!
		if let step1 = iter.next() {
			if let curRep = step1.currentReps?.string {
				assert(string: curRep, containsInOrder: [s1.reps.description, timesSign, s1.weight.toString(), plusSign, w1.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let othSets = step1.otherPartsInfo?.string {
				assert(string: othSets, containsInOrder: ["1", s2.weight.toString(), plusSign, w1.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let next = step1.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e2.name!, e2[0]!.weight.toString(), minusSign, min(abs(w2), e2[0]!.weight).toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let details1 = step1 as? WorkoutExercizeStep {
				XCTAssertEqual(details1.reps.weight, s1.weight)
				XCTAssertEqual(details1.reps.change, w1)
				
				XCTAssertEqual(details1.otherWeights, [s2.weight])
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next1 = step1.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next1.weight, e2[0]!.weight)
				XCTAssertEqual(next1.change, w2)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
		
		iter.setWeightChange(0, for: e1)
		if let step2 = iter.next() {
			if let curRep = step2.currentReps?.string {
				assert(string: curRep, containsInOrder: [s2.reps.description, timesSign, s2.weight.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			XCTAssertNil(step2.otherPartsInfo)
			
			if let next = step2.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e2.name!, e2[0]!.weight.toString(), minusSign, min(abs(w2), e2[0]!.weight).toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			XCTAssertFalse(step2.isRest)
			XCTAssertEqual(step2.set, s2)
			
			if let details2 = step2 as? WorkoutExercizeStep {
				XCTAssertEqual(details2.reps.weight, s2.weight)
				XCTAssertEqual(details2.reps.change, 0)
				
				XCTAssertEqual(details2.otherWeights, [])
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next2 = step2.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next2.weight, e2[0]!.weight)
				XCTAssertEqual(next2.change, w2)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let step3 = iter.next() {
			let s1 = e2[0]!
			let s2 = e2[1]!
			if let curRep = step3.currentReps?.string {
				assert(string: curRep, containsInOrder: [s1.reps.description, timesSign, s1.weight.toString(), minusSign, min(abs(w2), s1.weight).toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let othSets = step3.otherPartsInfo?.string {
				assert(string: othSets, containsInOrder: ["1", s2.weight.toString(), minusSign, min(abs(w2), s2.weight).toString()])
			} else {
				XCTFail("Unexpected nil")
			}
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testWeightChangeCircuitWorkout() {
		let e1 = workout[0]!
		let e2 = workout[1]!
		workout.makeCircuit(exercize: e1, isCircuit: true)
		workout.enableCircuitRestPeriods(for: e1, enable: true)
		let w1 = 7.5
		let w2 = -2.0
		let iter = WorkoutIterator(workout, using: dataManager.preferences)
		iter.setWeightChange(w1, for: e1)
		iter.setWeightChange(w2, for: e2)
		
		let s1 = e1[0]!
		let s2 = e2[0]!
		let s3 = e1[1]!
		
		if let step1 = iter.next() {
			if let curRep = step1.currentReps?.string {
				assert(string: curRep, containsInOrder: [s1.reps.description, timesSign, s1.weight.toString(), plusSign, w1.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let next = step1.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e2.name!, s2.weight.toString(), minusSign, abs(w2).toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			XCTAssertFalse(step1.isRest)
			XCTAssertEqual(step1.set, s1)
			
			if let details1 = step1 as? WorkoutCircuitStep {
				XCTAssertEqual(details1.reps.weight, s1.weight)
				XCTAssertEqual(details1.reps.change, w1)
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next1 = step1.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next1.weight, s2.weight)
				XCTAssertEqual(next1.change, w2)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
		
		if let step2 = iter.next() {
			if let curRep = step2.currentReps?.string {
				assert(string: curRep, containsInOrder: [s2.reps.description, timesSign, s2.weight.toString(), minusSign, abs(w2).toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let next = step2.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e1.name!, s3.weight.toString(), plusSign, w1.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			XCTAssertFalse(step2.isRest)
			XCTAssertEqual(step2.set, s2)
			
			if let details2 = step2 as? WorkoutCircuitStep {
				XCTAssertEqual(details2.reps.weight, s2.weight)
				XCTAssertEqual(details2.reps.change, w2)
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next2 = step2.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next2.weight, s3.weight)
				XCTAssertEqual(next2.change, w1)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
		
		iter.setWeightChange(0, for: e1)
		if let step3 = iter.next() {
			if let curRep = step3.currentReps?.string {
				assert(string: curRep, containsInOrder: [s3.reps.description, timesSign, s3.weight.toString()], thenNotContains: plusSign)
			} else {
				XCTFail("Unexpected nil")
			}
			
			XCTAssertFalse(step3.isRest)
			XCTAssertEqual(step3.set, s3)
			
			if let details3 = step3 as? WorkoutCircuitStep {
				XCTAssertEqual(details3.reps.weight, s3.weight)
				XCTAssertEqual(details3.reps.change, 0)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testWeightChangeUpdateSimpleWorkout() {
		let iter = WorkoutIterator(workout, using: dataManager.preferences)
		
		let e1 = workout[0]!
		let e2 = workout[1]!
		let s1 = e1[0]!
		let s2 = e1[1]!
		if let step = iter.next() {
			if let curRep = step.currentReps?.string {
				assert(string: curRep, containsInOrder: [s1.reps.description], thenNotContains: timesSign)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let othSets = step.otherPartsInfo?.string {
				assert(string: othSets, containsInOrder: ["1", s2.weight.toString()], thenNotContains: minusSign)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let next = step.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e2.name!, e2[0]!.weight.toString()], thenNotContains: plusSign)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let details1 = step as? WorkoutExercizeStep {
				XCTAssertEqual(details1.reps.weight, s1.weight)
				XCTAssertEqual(details1.reps.change, 0)
				
				XCTAssertEqual(details1.otherWeights, [s2.weight])
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next1 = step.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next1.weight, e2[0]!.weight)
				XCTAssertEqual(next1.change, 0)
			} else {
				XCTFail("Invalid class found")
			}
			
			let w1 = -5.5
			let w2 = 4.0
			iter.setWeightChange(w1, for: e1)
			iter.setWeightChange(w2, for: e2)
			step.updateWeightChange()
			
			if let curRep = step.currentReps?.string {
				assert(string: curRep, containsInOrder: [s1.reps.description], thenNotContains: timesSign)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let othSets = step.otherPartsInfo?.string {
				assert(string: othSets, containsInOrder: ["1", s2.weight.toString(), minusSign, abs(w1).toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let next = step.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e2.name!, e2[0]!.weight.toString(), plusSign, w2.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let details1 = step as? WorkoutExercizeStep {
				XCTAssertEqual(details1.reps.weight, s1.weight)
				XCTAssertEqual(details1.reps.change, w1)
				
				XCTAssertEqual(details1.otherWeights, [s2.weight])
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next1 = step.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next1.weight, e2[0]!.weight)
				XCTAssertEqual(next1.change, w2)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	func testWeightChangeUpdateCircuitWorkout() {
		// Make first 2 ex a circuit, get first step, update weight for 2nd ex, check changes (current + next, not other set)
		
		let e1 = workout[0]!
		let e2 = workout[1]!
		workout.makeCircuit(exercize: e1, isCircuit: true)
		workout.enableCircuitRestPeriods(for: e1, enable: true)
		let w1 = 3.0
		let w2 = 4.5
		let iter = WorkoutIterator(workout, using: dataManager.preferences)
		
		let s1 = e1[0]!
		let s2 = e2[0]!
		
		if let step = iter.next() {
			if let curRep = step.currentReps?.string {
				assert(string: curRep, containsInOrder: [s1.reps.description], thenNotContains: timesSign)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let next = step.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e2.name!, s2.weight.toString()], thenNotContains: plusSign)
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let details1 = step as? WorkoutCircuitStep {
				XCTAssertEqual(details1.reps.weight, s1.weight)
				XCTAssertEqual(details1.reps.change, 0)
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next1 = step.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next1.weight, s2.weight)
				XCTAssertEqual(next1.change, 0)
			} else {
				XCTFail("Invalid class found")
			}
			
			iter.setWeightChange(w1, for: e1)
			iter.setWeightChange(w2, for: e2)
			step.updateWeightChange()
			
			if let curRep = step.currentReps?.string {
				assert(string: curRep, containsInOrder: [s1.reps.description, timesSign, s1.weight.toString(), plusSign, w1.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let next = step.nextUpInfo?.string {
				assert(string: next, containsInOrder: [e2.name!, s2.weight.toString(), plusSign, w2.toString()])
			} else {
				XCTFail("Unexpected nil")
			}
			
			if let details1 = step as? WorkoutCircuitStep {
				XCTAssertEqual(details1.reps.weight, s1.weight)
				XCTAssertEqual(details1.reps.change, w1)
			} else {
				XCTFail("Invalid class found")
			}
			
			if let next1 = step.nextUp as? WorkoutStepNextSet {
				XCTAssertEqual(next1.weight, s2.weight)
				XCTAssertEqual(next1.change, w2)
			} else {
				XCTFail("Invalid class found")
			}
		} else {
			XCTFail("Unexpected nil")
		}
	}
	
	private func assert(string: String, containsInOrder others: [String], thenNotContains notContains: String? = nil, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
		var partial: String = string
		var i = 0
		for s in others {
			if let range = partial.range(of: s) {
				partial = String(partial[range.upperBound...])
			} else {
				XCTFail("\"\(string)\" does not contain other strings in specified order, \(i) string found out of \(others.count) - \(message())", file: file, line: line)
				return
			}
			
			i += 1
		}
		
		if let exclude = notContains {
			XCTAssertNil(partial.range(of: exclude), "\"\(string)\" contains other strings in specified order but excluded string found - \(message())", file: file, line: line)
		}
	}
    
}
