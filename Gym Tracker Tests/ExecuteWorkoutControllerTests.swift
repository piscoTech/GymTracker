//
//  ExecuteWorkoutControllerTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 17/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class ExecuteWorkoutControllerTests: XCTestCase {
	
	private enum DelegateCalls: Equatable {
		case setWorkoutTitle(String)
		case setBPM(String)
		case setCurrentExercizeViewHidden(Bool)
		case setRestViewHidden(Bool)
		case setWorkoutDoneViewHidden(Bool)
		case setNextUpTextHidden(Bool)
		case workoutHasStarted
		case askForChoices([GTChoice])
		case disableGlobalActions
		case exitWorkoutTracking
		case endNotifyEndRest
		case startTimer(Date)
		case setExercizeName(String)
		case setCurrentSetViewHidden(Bool)
		case setCurrentSetText(String)
		case setSetDoneButtonHidden(Bool)
		case setOtherSetsViewHidden(Bool)
		case setOtherSetsText(String)
		case stopRestTimer
		case notifyExercizeChange(Bool)
		case setNextUpText(String)
		case askUpdateSecondaryInfo(UpdateSecondaryInfoData)
		case startRestTimer(Date)
		case setRestEndButtonHidden(Bool)
		case notifyEndRest
		case setWorkoutDoneText(String)
		case setWorkoutDoneButtonEnabled(Bool)
		case stopTimer
	}
	
	private let source = RunningWorkoutSource.phone
	private var calls: [DelegateCalls]!
	private var expectations = [XCTestExpectation]()
	private var w: GTWorkout!
	private var e1, e2, e3, e4: GTSimpleSetsExercize!
	private var r: GTRest!
	
	override func setUp() {
		super.setUp()
		
		calls = []
		
		w = dataManager.newWorkout()
		w.set(name: "Wrkt Tests")
		
		var e = dataManager.newExercize()
		w.add(parts: e)
		e.set(name: "Exercize 1")
		var s = dataManager.newSet(for: e)
		s.set(mainInfo: 10)
		s.set(secondaryInfo: 0)
		s.set(rest: 0)
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 5)
		s.set(secondaryInfo: 8)
		s.set(rest: 90)
		e1 = e
		
		e = dataManager.newExercize()
		w.add(parts: e)
		e.set(name: "Exercize 2")
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 12)
		s.set(secondaryInfo: 4)
		s.set(rest: 30)
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 10)
		s.set(secondaryInfo: 6)
		s.set(rest: 60)
		e2 = e
		
		r = dataManager.newRest()
		w.add(parts: r)
		r.set(rest: 60)
		
		e = dataManager.newExercize()
		w.add(parts: e)
		e.set(name: "Exercize 3")
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 15)
		s.set(secondaryInfo: 0)
		s.set(rest: 60)
		e3 = e
		
		e = dataManager.newExercize()
		w.add(parts: e)
		e.set(name: "Exercize 4")
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 10)
		s.set(secondaryInfo: 5)
		s.set(rest: 60)
		e4 = e
	}
	
	private func choicify() {
		let ch2 = dataManager.newChoice()
		w.add(parts: ch2)
		ch2.add(parts: w[3] as! GTSimpleSetsExercize, w[4] as! GTSimpleSetsExercize)
		
		let ch1 = dataManager.newChoice()
		w.add(parts: ch1)
		ch1.add(parts: w[0] as! GTSimpleSetsExercize, w[1] as! GTSimpleSetsExercize)
		
		w.movePart(at: ch1.order, to: 0)
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.setRunningWorkout(nil, fromSource: source)
		dataManager.preferences.runningWorkoutSource = nil
		dataManager.discardAllChanges()
		
		super.tearDown()
	}
	
	func testSimpleStart() {
		let data = ExecuteWorkoutData(workout: w, resume: false, choices: [])
		_ = ExecuteWorkoutController(data: data, viewController: self, source: source, dataManager: dataManager)
		
		assertCall { c in
			if case DelegateCalls.setWorkoutTitle(let n) = c {
				XCTAssertEqual(n, w.name)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setBPM(let h) = c {
				XCTAssertFalse(h.isDigit)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setRestViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setNextUpTextHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { $0 == .workoutHasStarted }
		XCTAssertEqual(dataManager.preferences.runningWorkout, w.recordID)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices")
	}
	
	func testChoiceStart() {
		choicify()
		
		let data = ExecuteWorkoutData(workout: w, resume: false, choices: [])
		let ctrl = ExecuteWorkoutController(data: data, viewController: self, source: source, dataManager: dataManager)
		
		assertCall { c in
			if case DelegateCalls.setWorkoutTitle(let n) = c {
				XCTAssertEqual(n, w.name)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setBPM(let h) = c {
				XCTAssertFalse(h.isDigit)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setRestViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		assertCall { c in
			if case DelegateCalls.setNextUpTextHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { c in
			if case DelegateCalls.askForChoices(let ch) = c {
				XCTAssertEqual(ch.count, 2)
				ctrl.reportChoices([ch[0]: 2])
				
				return true
			}
			
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { c in
			if case DelegateCalls.askForChoices(let ch) = c {
				XCTAssertEqual(ch.count, 2)
				ctrl.reportChoices([ch[0]: 1])
				
				return true
			}
			
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { c in
			if case DelegateCalls.askForChoices(let ch) = c {
				XCTAssertEqual(ch.count, 1)
				ctrl.reportChoices([ch[0]: 0])
				
				return true
			}
			
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { $0 == .workoutHasStarted }
		XCTAssertEqual(dataManager.preferences.runningWorkout, w.recordID)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices")
	}
	
	func testStartSurplusChoices() {
		choicify()
		
		let data = ExecuteWorkoutData(workout: w, resume: false, choices: [4,7,8,10])
		let ctrl = ExecuteWorkoutController(data: data, viewController: self, source: source, dataManager: dataManager)
		
		XCTAssertFalse(calls.isEmpty)
		XCTAssertFalse(calls.contains { c in
			if case DelegateCalls.askForChoices(_) = c {
				return true
			} else {
				return false
			}
		})
		calls = []
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { c in
			if case DelegateCalls.askForChoices(let ch) = c {
				XCTAssertEqual(ch.count, 2)
				ctrl.reportChoices([ch[0]: 0, ch[1]: 0])
				
				return true
			}
			
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { $0 == .workoutHasStarted }
		XCTAssertTrue(calls.isEmpty)
		
		XCTAssertEqual(dataManager.preferences.runningWorkout, w.recordID)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are empty")
	}
	
	func testCancelStart() {
		choicify()
		
		let data = ExecuteWorkoutData(workout: w, resume: false, choices: [])
		let ctrl = ExecuteWorkoutController(data: data, viewController: self, source: source, dataManager: dataManager)
		
		XCTAssertFalse(calls.isEmpty)
		XCTAssertFalse(calls.contains { c in
			if case DelegateCalls.askForChoices(_) = c {
				return true
			} else {
				return false
			}
		})
		calls = []
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 1), timeout: 1)
		
		assertCall { c in
			if case DelegateCalls.askForChoices(let ch) = c {
				XCTAssertFalse(ch.isEmpty)
				return true
			}
			
			return false
		}
		
		ctrl.cancelWorkout()
		XCTAssertTrue(calls.isEmpty)
		ctrl.cancelStartup()
		
		assertCall { $0 == .disableGlobalActions }
		assertCall { $0 == .exitWorkoutTracking }
		assertCall { $0 == .endNotifyEndRest }
		XCTAssertTrue(calls.isEmpty)
		
		XCTAssertNil(dataManager.preferences.runningWorkout)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are nil")
	}
	
	func testExecution() {
		choicify()
		let data = ExecuteWorkoutData(workout: w, resume: false, choices: [1, 0])
		let ctrl = ExecuteWorkoutController(data: data, viewController: self, source: source, dataManager: dataManager)
		
		XCTAssertFalse(calls.isEmpty)
		XCTAssertFalse(calls.contains { c in
			if case DelegateCalls.askForChoices(_) = c {
				return true
			} else {
				return false
			}
		})
		calls = []
		
		do { // First set
			wait(for: waitCalls(n: 14), timeout: 1)
			
			assertCall { $0 == .workoutHasStarted }
			assertCall { c in
				if case DelegateCalls.startTimer(let d) = c {
					let now = Date()
					XCTAssertEqual(d.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 2)
					
					return true
				}
				
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpTextHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setExercizeName(let n) = c {
					XCTAssertEqual(n, e2.name)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetText(let str) = c {
					let s = e2[0]!
					assert(string: str, containsInOrder: [s.mainInfo.description, timesSign, s.secondaryInfo.toString(), s.secondaryInfoLabel.string])
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setSetDoneButtonHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setOtherSetsViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setOtherSetsText(let str) = c {
					let s = e2[1]!
					assert(string: str, containsInOrder: ["1", s.secondaryInfo.toString(), s.secondaryInfoLabel.string])
					return true
				}
				return false
			}
			assertCall { $0 == .stopRestTimer }
			assertCall { c in
				if case DelegateCalls.setRestViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.notifyExercizeChange(let r) = c {
					XCTAssertFalse(r)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpText(let str) = c {
					assert(string: str, containsInOrder: [r.rest.getDuration(hideHours: true)])
					return true
				}
				return false
			}
			
			XCTAssertTrue(calls.isEmpty)
		}
		
		let e2Change = 1.0
		func checkE2Rest() {
			assertCall { c in
				if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setExercizeName(let n) = c {
					XCTAssertEqual(n, e2.name)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setSetDoneButtonHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setOtherSetsViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setOtherSetsText(let str) = c {
					let s = e2[1]!
					assert(string: str, containsInOrder: ["1", s.secondaryInfo.toString(), s.secondaryInfoLabel.string])
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.startRestTimer(let d) = c {
					let s = e2[0]!
					XCTAssertEqual(d.timeIntervalSince1970, Date().timeIntervalSince1970 + s.rest, accuracy: 2)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setRestViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setRestEndButtonHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpText(let str) = c {
					assert(string: str, containsInOrder: [r.rest.getDuration(hideHours: true)])
					return true
				}
				return false
			}
		}
		
		do { // First set rest start
			ctrl.endSet()
			
			assertCall { c in
				if case DelegateCalls.askUpdateSecondaryInfo(let d) = c {
					XCTAssertEqual(d.set, e2[0])
					XCTAssertEqual(d.workoutController, ctrl)
					return true
				}
				return false
			}
			checkE2Rest()
			assertCall { c in
				if case DelegateCalls.notifyExercizeChange(let r) = c {
					XCTAssertTrue(r)
					return true
				}
				return false
			}
			
			XCTAssertTrue(calls.isEmpty)
		}
		
		do { // First set update
			ctrl.setSecondaryInfoChange(e2Change, for: e2[0]!)
			
			XCTAssertEqual(ctrl.secondaryInfoChange(for: e2[0]!), e2Change)
			XCTAssertEqual(e2[0]!.secondaryInfo, 5)
			checkE2Rest()
			XCTAssertTrue(calls.isEmpty)
		}
		
		do { // First set rest end
			wait(for: waitCalls(n: 2), timeout: e2[0]!.rest + 5)
			
			assertCall { $0 == .stopRestTimer }
			assertCall { $0 == .notifyEndRest }
			XCTAssertTrue(calls.isEmpty)
		}
		
		do { // Second set
			ctrl.endRest()
			
			assertCall { c in
				if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setExercizeName(let n) = c {
					XCTAssertEqual(n, e2.name)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetText(let str) = c {
					let s = e2[1]!
					assert(string: str, containsInOrder: [s.mainInfo.description, timesSign, s.secondaryInfo.toString(), plusSign, e2Change.toString(), s.secondaryInfoLabel.string])
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setSetDoneButtonHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setOtherSetsViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall(count: 2) { $0 == .stopRestTimer }
			assertCall { c in
				if case DelegateCalls.setRestViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.notifyExercizeChange(let r) = c {
					XCTAssertFalse(r)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpText(let str) = c {
					assert(string: str, containsInOrder: [r.rest.getDuration(hideHours: true)])
					return true
				}
				return false
			}
			assertCall { $0 == .endNotifyEndRest }
			
			XCTAssertTrue(calls.isEmpty)
		}
		
		do { // Rest period start
			let restStart = Date().addingTimeInterval(-45)
			ctrl.endSet(endTime: restStart, secondaryInfoChange: e2Change * 2)
			
			XCTAssertEqual(ctrl.secondaryInfoChange(for: e2[1]!), e2Change * 2)
			XCTAssertEqual(e2[1]!.secondaryInfo, 8)
			
			assertCall { c in
				if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.startRestTimer(let d) = c {
					XCTAssertEqual(d.timeIntervalSince1970, restStart.timeIntervalSince1970 + r.rest, accuracy: 5)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setRestViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setRestEndButtonHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.notifyExercizeChange(let r) = c {
					XCTAssertTrue(r)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpText(let str) = c {
					assert(string: str, containsInOrder: [e3.name], thenNotContains: e3[0]!.secondaryInfoLabel.string)
					return true
				}
				return false
			}
		}
		
		do { // Rest period end
			wait(for: waitCalls(n: 2), timeout: 20)
			
			assertCall { $0 == .stopRestTimer }
			assertCall { $0 == .notifyEndRest }
			XCTAssertTrue(calls.isEmpty)
		}
		
		do { // Last set
			ctrl.endRest()
			
			assertCall { $0 == .endNotifyEndRest }
			assertCall { c in
				if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setExercizeName(let n) = c {
					XCTAssertEqual(n, e3.name)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetText(let str) = c {
					let s = e3[0]!
					assert(string: str, containsInOrder: [s.mainInfo.description], thenNotContains: timesSign)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setSetDoneButtonHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setOtherSetsViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall(count: 2) { $0 == .stopRestTimer }
			assertCall { c in
				if case DelegateCalls.setRestViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.notifyExercizeChange(let r) = c {
					XCTAssertFalse(r)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpText(_) = c {
					return true
				}
				return false
			}
			
			XCTAssertTrue(calls.isEmpty)
		}
		
		do { // End workout
			ctrl.endSet()
			
			assertCall { c in
				if case DelegateCalls.askUpdateSecondaryInfo(let d) = c {
					XCTAssertEqual(d.set, e3[0])
					XCTAssertEqual(d.workoutController, ctrl)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setRestViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpTextHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setWorkoutDoneButtonEnabled(let e) = c {
					XCTAssertFalse(e)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setWorkoutDoneText(_) = c {
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setWorkoutDoneViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { $0 == .stopTimer }
			assertCall { $0 == .disableGlobalActions }
			assertCall { $0 == .endNotifyEndRest }
			
			XCTAssertTrue(calls.isEmpty)
			wait(for: waitCalls(n: 3), timeout: 2)
			
			assertCall { c in
				if case DelegateCalls.setWorkoutDoneButtonEnabled(let e) = c {
					XCTAssertTrue(e)
					return true
				}
				return false
			}
			assertCall(count: 2) { c in
				if case DelegateCalls.setWorkoutDoneText(_) = c {
					return true
				}
				return false
			}
			
			XCTAssertTrue(calls.isEmpty)
			XCTAssertNil(dataManager.preferences.runningWorkout)
			XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
			#warning("Also check persisted choices are nil")
			
			XCTAssertEqual((w[0] as! GTChoice).lastChosen, 1)
			XCTAssertEqual((w[2] as! GTChoice).lastChosen, 0)
		}
		
	}
	
	func testUpdateSecondary() {
		let ctrl = ExecuteWorkoutController(data: ExecuteWorkoutData(workout: w, resume: false, choices: []), viewController: self, source: source, dataManager: dataManager)
		wait(for: waitCalls(n: 14), timeout: 1)
		calls = []
		ctrl.endSet()
		
		func testSet2Update() {
			assertCall { c in
				if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setExercizeName(let n) = c {
					XCTAssertEqual(n, e1.name)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetViewHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setCurrentSetText(let str) = c {
					let s = e1[1]!
					assert(string: str, containsInOrder: [s.mainInfo.description, timesSign, s.secondaryInfo.toString(), s.secondaryInfoLabel.string])
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setSetDoneButtonHidden(let h) = c {
					XCTAssertFalse(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setOtherSetsViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { $0 == .stopRestTimer }
			assertCall { c in
				if case DelegateCalls.setRestViewHidden(let h) = c {
					XCTAssertTrue(h)
					return true
				}
				return false
			}
			assertCall { c in
				if case DelegateCalls.setNextUpText(let str) = c {
					assert(string: str, containsInOrder: [e2.name, e2[0]!.secondaryInfo.toString(), e2[0]!.secondaryInfoLabel.string])
					return true
				}
				return false
			}
		}
		
		testSet2Update()
		assertCall { c in
			if case DelegateCalls.askUpdateSecondaryInfo(let d) = c {
				XCTAssertEqual(d.set, e1[0])
				XCTAssertEqual(d.workoutController, ctrl)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.notifyExercizeChange(let r) = c {
				XCTAssertFalse(r)
				return true
			}
			return false
		}
		XCTAssertTrue(calls.isEmpty)
		
		ctrl.setSecondaryInfoChange(0, for: e1[0]!)
		testSet2Update()
		XCTAssertTrue(calls.isEmpty)
		
		XCTAssertEqual(e1[0]?.secondaryInfo, 0)
		XCTAssertEqual(ctrl.secondaryInfoChange(for: e1[0]!), 0)
		
		ctrl.endSet() // End E1 S2
		ctrl.endSet() // End E2 S1
		
		calls = []
		ctrl.setSecondaryInfoChange(2, for: e2[0]!)
		XCTAssertEqual(e2[0]?.secondaryInfo, 6)
		XCTAssertEqual(ctrl.secondaryInfoChange(for: e2[0]!), 2)
		
		assertCall { c in
			if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
				XCTAssertFalse(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setExercizeName(let n) = c {
				XCTAssertEqual(n, e2.name)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setCurrentSetViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setSetDoneButtonHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setOtherSetsViewHidden(let h) = c {
				XCTAssertFalse(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setOtherSetsText(let str) = c {
				let s = e2[1]!
				assert(string: str, containsInOrder: ["1", s.secondaryInfo.toString(), plusSign, "2", s.secondaryInfoLabel.string])
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.startRestTimer(let d) = c {
				let s = e2[0]!
				XCTAssertEqual(d.timeIntervalSince1970, Date().timeIntervalSince1970 + s.rest, accuracy: 2)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setRestViewHidden(let h) = c {
				XCTAssertFalse(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setRestEndButtonHidden(let h) = c {
				XCTAssertFalse(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setNextUpText(let str) = c {
				assert(string: str, containsInOrder: [r.rest.getDuration(hideHours: true)])
				return true
			}
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		ctrl.endRest()
		
		assertCall { c in
			if case DelegateCalls.setCurrentSetText(let str) = c {
				let s = e2[1]!
				assert(string: str, containsInOrder: [s.mainInfo.description, timesSign, s.secondaryInfo.toString(), plusSign, "2", s.secondaryInfoLabel.string])
				return true
			}
			return false
		}
		
		XCTAssertFalse(calls.isEmpty)
	}
	
	func testNotificationInfo() {
		choicify()
		let ctrl = ExecuteWorkoutController(data: ExecuteWorkoutData(workout: w, resume: false, choices: [1,0]), viewController: self, source: source, dataManager: dataManager)
		wait(for: waitCalls(n: 14), timeout: 1)
		
		XCTAssertNil(ctrl.currentRestTime)
		XCTAssertFalse(ctrl.currentIsRestPeriod)
		XCTAssertFalse(ctrl.isRestMode)
		if let (eName, info, oth) = ctrl.currentSetInfo {
			XCTAssertEqual(eName, e2.name)
			let s1 = e2[0]!
			let s2 = e2[1]!
			assert(string: info, containsInOrder: [s1.mainInfo.description, timesSign, s1.secondaryInfo.toString(), s1.secondaryInfoLabel.string])
			if let o = oth {
				assert(string: o, containsInOrder: ["1", s2.secondaryInfo.toString(), s2.secondaryInfoLabel.string])
			} else {
				XCTFail("Unexpected nil")
			}
		} else {
			XCTFail("Unexpected nil")
		}
		XCTAssertFalse(ctrl.isLastPart)
		
		ctrl.endSet()
		
		if let (tot, end) = ctrl.currentRestTime {
			XCTAssertEqual(tot, e2[0]!.rest)
			XCTAssertEqual(end.timeIntervalSince1970, Date().timeIntervalSince1970 + e2[0]!.rest, accuracy: 2)
		} else {
			XCTFail("Unexpected nil")
		}
		XCTAssertFalse(ctrl.currentIsRestPeriod)
		XCTAssertTrue(ctrl.isRestMode)
		XCTAssertNotNil(ctrl.currentSetInfo)
		XCTAssertFalse(ctrl.isLastPart)
		
		ctrl.endRest()
		
		XCTAssertNil(ctrl.currentRestTime)
		XCTAssertFalse(ctrl.currentIsRestPeriod)
		XCTAssertFalse(ctrl.isRestMode)
		XCTAssertNotNil(ctrl.currentSetInfo)
		XCTAssertFalse(ctrl.isLastPart)
		
		ctrl.endSet()
		
		XCTAssertNotNil(ctrl.currentRestTime)
		XCTAssertTrue(ctrl.currentIsRestPeriod)
		XCTAssertTrue(ctrl.isRestMode)
		XCTAssertNil(ctrl.currentSetInfo)
		XCTAssertFalse(ctrl.isLastPart)
		
		ctrl.endRest()
		
		XCTAssertNil(ctrl.currentRestTime)
		XCTAssertFalse(ctrl.currentIsRestPeriod)
		XCTAssertFalse(ctrl.isRestMode)
		XCTAssertNotNil(ctrl.currentSetInfo)
		XCTAssertTrue(ctrl.isLastPart)
	}
	
	func testCancelWorkout() {
		choicify()
		let ctrl = ExecuteWorkoutController(data: ExecuteWorkoutData(workout: w, resume: false, choices: [1,1]), viewController: self, source: source, dataManager: dataManager)
		wait(for: waitCalls(n: 14), timeout: 1)
		XCTAssertEqual(calls.count, 6 + 14)
		calls = []
		
		XCTAssertEqual(dataManager.preferences.runningWorkout, w.recordID)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are empty")
		
		ctrl.cancelStartup()
		XCTAssertTrue(calls.isEmpty)
		ctrl.cancelWorkout()
		
		assertCall { c in
			if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setRestViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setNextUpTextHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		
		assertCall { $0 == .stopTimer }
		assertCall { $0 == .disableGlobalActions }
		assertCall { $0 == .endNotifyEndRest }
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneButtonEnabled(let e) = c {
				XCTAssertFalse(e)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneText(_) = c {
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneViewHidden(let h) = c {
				XCTAssertFalse(h)
				return true
			}
			return false
		}
		assertCall { $0 == .exitWorkoutTracking }
		XCTAssertTrue(calls.isEmpty)
		
		XCTAssertNil(dataManager.preferences.runningWorkout)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are nil")
		XCTAssertLessThan((w[0] as! GTChoice).lastChosen, 0)
		XCTAssertLessThan((w[2] as! GTChoice).lastChosen, 0)
	}
	
	func testEarlyEndSimple() {
		let ctrl = ExecuteWorkoutController(data: ExecuteWorkoutData(workout: w, resume: false, choices: []), viewController: self, source: source, dataManager: dataManager)
		wait(for: waitCalls(n: 14), timeout: 1)
		XCTAssertEqual(calls.count, 6 + 14)
		calls = []
		
		XCTAssertEqual(dataManager.preferences.runningWorkout, w.recordID)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are empty")
		
		ctrl.endWorkout()
		
		assertCall { c in
			if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setRestViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setNextUpTextHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneButtonEnabled(let e) = c {
				XCTAssertFalse(e)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneText(_) = c {
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneViewHidden(let h) = c {
				XCTAssertFalse(h)
				return true
			}
			return false
		}
		assertCall { $0 == .stopTimer }
		assertCall { $0 == .disableGlobalActions }
		assertCall { $0 == .endNotifyEndRest }
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 2), timeout: 2)
		
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneButtonEnabled(let e) = c {
				XCTAssertTrue(e)
				return true
			}
			return false
		}
		assertCall(count: 2) { c in
			if case DelegateCalls.setWorkoutDoneText(_) = c {
				return true
			}
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		XCTAssertNil(dataManager.preferences.runningWorkout)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are nil")
	}
	
	func testEarlyEndChoice() {
		choicify()
		let ctrl = ExecuteWorkoutController(data: ExecuteWorkoutData(workout: w, resume: false, choices: [0, 1]), viewController: self, source: source, dataManager: dataManager)
		wait(for: waitCalls(n: 14), timeout: 1)
		XCTAssertEqual(calls.count, 6 + 14)
		calls = []
		
		XCTAssertEqual(dataManager.preferences.runningWorkout, w.recordID)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are empty")
		
		ctrl.endWorkout()
		
		assertCall { c in
			if case DelegateCalls.setCurrentExercizeViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setRestViewHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setNextUpTextHidden(let h) = c {
				XCTAssertTrue(h)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneButtonEnabled(let e) = c {
				XCTAssertFalse(e)
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneText(_) = c {
				return true
			}
			return false
		}
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneViewHidden(let h) = c {
				XCTAssertFalse(h)
				return true
			}
			return false
		}
		assertCall { $0 == .stopTimer }
		assertCall { $0 == .disableGlobalActions }
		assertCall { $0 == .endNotifyEndRest }
		
		XCTAssertTrue(calls.isEmpty)
		wait(for: waitCalls(n: 2), timeout: 2)
		
		assertCall { c in
			if case DelegateCalls.setWorkoutDoneButtonEnabled(let e) = c {
				XCTAssertTrue(e)
				return true
			}
			return false
		}
		assertCall(count: 2) { c in
			if case DelegateCalls.setWorkoutDoneText(_) = c {
				return true
			}
			return false
		}
		
		XCTAssertTrue(calls.isEmpty)
		XCTAssertNil(dataManager.preferences.runningWorkout)
		XCTAssertEqual(dataManager.preferences.runningWorkoutSource, source)
		#warning("Also check persisted choices are nil")
		
		XCTAssertEqual((w[0] as! GTChoice).lastChosen, 0)
		XCTAssertEqual((w[2] as! GTChoice).lastChosen, 1)
	}
	
	private func assertCall(count: Int = 1, file: StaticString = #file, line: UInt = #line, _ where: (DelegateCalls) -> Bool) {
		let n = calls.count
		calls.removeAll { `where`($0) }
		let diff = n - calls.count
		if diff != count {
			XCTFail("\(diff) of \(count) expected call(s) found", file: file, line: line)
		}
	}
	
	private func waitCalls(n: Int) -> [XCTestExpectation] {
		let e = (0 ..< n).map { _ in XCTestExpectation() }
		expectations = e
		return e
	}
	
}

extension ExecuteWorkoutControllerTests: ExecuteWorkoutControllerDelegate {
	
	func setWorkoutTitle(_ text: String) {
		self.calls.append(.setWorkoutTitle(text))
		expectations.popLast()?.fulfill()
	}
	
	func askForChoices(_ choices: [GTChoice]) {
		self.calls.append(.askForChoices(choices))
		expectations.popLast()?.fulfill()
	}
	
	func setBPM(_ text: String) {
		self.calls.append(.setBPM(text))
		expectations.popLast()?.fulfill()
	}
	
	func startTimer(at date: Date) {
		self.calls.append(.startTimer(date))
		expectations.popLast()?.fulfill()
	}
	
	func stopTimer() {
		self.calls.append(.stopTimer)
		expectations.popLast()?.fulfill()
	}
	
	func setCurrentExercizeViewHidden(_ hidden: Bool) {
		self.calls.append(.setCurrentExercizeViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setExercizeName(_ name: String) {
		self.calls.append(.setExercizeName(name))
		expectations.popLast()?.fulfill()
	}
	
	func setCurrentSetViewHidden(_ hidden: Bool) {
		self.calls.append(.setCurrentSetViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setCurrentSetText(_ text: NSAttributedString) {
		self.calls.append(.setCurrentSetText(text.string))
		expectations.popLast()?.fulfill()
	}
	
	func setOtherSetsViewHidden(_ hidden: Bool) {
		self.calls.append(.setOtherSetsViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setOtherSetsText(_ text: NSAttributedString) {
		self.calls.append(.setOtherSetsText(text.string))
		expectations.popLast()?.fulfill()
	}
	
	func setSetDoneButtonHidden(_ hidden: Bool) {
		self.calls.append(.setSetDoneButtonHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func startRestTimer(to date: Date) {
		self.calls.append(.startRestTimer(date))
		expectations.popLast()?.fulfill()
	}
	
	func stopRestTimer() {
		self.calls.append(.stopRestTimer)
		expectations.popLast()?.fulfill()
	}
	
	func setRestViewHidden(_ hidden: Bool) {
		self.calls.append(.setRestViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setRestEndButtonHidden(_ hidden: Bool) {
		self.calls.append(.setRestEndButtonHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setWorkoutDoneViewHidden(_ hidden: Bool) {
		self.calls.append(.setWorkoutDoneViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setWorkoutDoneText(_ text: String) {
		self.calls.append(.setWorkoutDoneText(text))
		expectations.popLast()?.fulfill()
	}
	
	func setWorkoutDoneButtonEnabled(_ enabled: Bool) {
		self.calls.append(.setWorkoutDoneButtonEnabled(enabled))
		expectations.popLast()?.fulfill()
	}
	
	func disableGlobalActions() {
		self.calls.append(.disableGlobalActions)
		expectations.popLast()?.fulfill()
	}
	
	func setNextUpTextHidden(_ hidden: Bool) {
		self.calls.append(.setNextUpTextHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setNextUpText(_ text: NSAttributedString) {
		self.calls.append(.setNextUpText(text.string))
		expectations.popLast()?.fulfill()
	}
	
	func notifyEndRest() {
		self.calls.append(.notifyEndRest)
		expectations.popLast()?.fulfill()
	}
	
	func endNotifyEndRest() {
		self.calls.append(.endNotifyEndRest)
		expectations.popLast()?.fulfill()
	}
	
	func notifyExercizeChange(isRest: Bool) {
		self.calls.append(.notifyExercizeChange(isRest))
		expectations.popLast()?.fulfill()
	}
	
	func askUpdateSecondaryInfo(with data: UpdateSecondaryInfoData) {
		self.calls.append(.askUpdateSecondaryInfo(data))
		expectations.popLast()?.fulfill()
	}
	
	func workoutHasStarted() {
		self.calls.append(.workoutHasStarted)
		expectations.popLast()?.fulfill()
	}
	
	func exitWorkoutTracking() {
		self.calls.append(.exitWorkoutTracking)
		expectations.popLast()?.fulfill()
	}
	
}
