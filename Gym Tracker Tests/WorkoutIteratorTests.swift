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
	
    func testSimpleWorkout() {
		let iter = WorkoutIterator(workout)
		do { // First exercize
			let e = workout[0]!
			let s1 = e[0]!
			let s2 = e[1]!
			
			if let step1 = iter.next() {
				XCTAssertEqual(step1.exercizeName, e.name)
				if let curRep = step1.currentReps?.string {
					XCTAssertNotNil(curRep.range(of: s1.reps.description))
					XCTAssertNil(curRep.range(of: timesSign))
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step1.otherPartsInfo?.string {
					if let countPos = othSets.range(of: "1") {
						XCTAssertNotNil(othSets[countPos.upperBound...].range(of: s2.weight.toString()))
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step1.rest)
				
				if let next = step1.nextUpInfo?.string {
					if let namePos = next.range(of: e.next!.name!) {
						XCTAssertNotNil(next[namePos.upperBound...].range(of: e.next![0]!.weight.toString()))
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step1.isRest)
				XCTAssertEqual(step1.set, s1)
				
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
					if let curRepPos = curRep.range(of: s2.reps.description) {
						let partial = curRep[curRepPos.upperBound...]
						if let timesPos = partial.range(of: timesSign) {
							XCTAssertNotNil(partial[timesPos.upperBound...].range(of: s2.weight.toString()))
						} else {
							XCTFail("Unexpected nil")
						}
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step2.otherPartsInfo)
				XCTAssertNil(step2.rest)
				
				if let next = step2.nextUpInfo?.string {
					if let namePos = next.range(of: e.next!.name!) {
						XCTAssertNotNil(next[namePos.upperBound...].range(of: e.next![0]!.weight.toString()))
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step2.isRest)
				XCTAssertEqual(step2.set, s2)
				
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
					if let curRepPos = curRep.range(of: s1.reps.description) {
						let partial = curRep[curRepPos.upperBound...]
						if let timesPos = partial.range(of: timesSign) {
							XCTAssertNotNil(partial[timesPos.upperBound...].range(of: s1.weight.toString()))
						} else {
							XCTFail("Unexpected nil")
						}
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				if let othSets = step3.otherPartsInfo?.string {
					if let countPos = othSets.range(of: "1") {
						XCTAssertNotNil(othSets[countPos.upperBound...].range(of: s2.weight.toString()))
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertEqual(s1.rest, step3.rest)
				
				if let next = step3.nextUpInfo?.string {
					XCTAssertNotNil(next.range(of: e.next!.rest.getDuration(hideHours: true)))
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step3.isRest)
				XCTAssertEqual(step3.set, s1)
				
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
					if let curRepPos = curRep.range(of: s2.reps.description) {
						let partial = curRep[curRepPos.upperBound...]
						if let timesPos = partial.range(of: timesSign) {
							XCTAssertNotNil(partial[timesPos.upperBound...].range(of: s2.weight.toString()))
						} else {
							XCTFail("Unexpected nil")
						}
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step4.otherPartsInfo)
				XCTAssertNil(step4.rest)
				
				if let next = step4.nextUpInfo?.string {
					XCTAssertNotNil(next.range(of: e.next!.rest.getDuration(hideHours: true)))
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertFalse(step4.isRest)
				XCTAssertEqual(step4.set, s2)
				
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
					if let namePos = next.range(of: e.next!.name!) {
						XCTAssertNil(next[namePos.upperBound...].range(of: e.next![0]!.weight.toString()))
					} else {
						XCTFail("Unexpected nil")
					}
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertTrue(step5.isRest)
				XCTAssertNil(step5.set)
				
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
					XCTAssertNotNil(curRep.range(of: s1.reps.description))
					XCTAssertNil(curRep.range(of: timesSign))
				} else {
					XCTFail("Unexpected nil")
				}
				
				XCTAssertNil(step6.otherPartsInfo)
				XCTAssertNil(step6.rest)
				XCTAssertNil(step6.nextUpInfo)
				
				XCTAssertFalse(step6.isRest)
				XCTAssertEqual(step6.set, s1)
				
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
//		ow.makeCircuit(exercize: ow[0]!, isCircuit: true)
//		ow.enableCircuitRestPeriods(for: ow[0]!, enable: true)
		
		// TODO: Test for nil rest instead of 0
		
		XCTFail()
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
//		ow.makeCircuit(exercize: ow[0]!, isCircuit: true)
//		ow.enableCircuitRestPeriods(for: ow[0]!, enable: true)
		
		// TODO: save state at the last set of circuit, restore then check values in preferences and run test for first step from other test case
		XCTFail()
	}
    
}
