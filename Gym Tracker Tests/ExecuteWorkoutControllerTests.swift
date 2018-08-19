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
	}
	
	private let source = RunningWorkoutSource.phone
	private var calls: [DelegateCalls]!
	private var expectations = [XCTestExpectation]()
	private var w: GTWorkout!

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
		
		e = dataManager.newExercize()
		w.add(parts: e)
		e.set(name: "Exercize 2")
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 12)
		s.set(secondaryInfo: 4)
		s.set(rest: 60)
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 10)
		s.set(secondaryInfo: 6)
		s.set(rest: 60)
		
		let r = dataManager.newRest()
		w.add(parts: r)
		let rest = 4 * 60.0
		r.set(rest: rest)
		
		e = dataManager.newExercize()
		w.add(parts: e)
		e.set(name: "Exercize 3")
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 15)
		s.set(secondaryInfo: 0)
		s.set(rest: 60)
		
		e = dataManager.newExercize()
		w.add(parts: e)
		e.set(name: "Exercize 4")
		s = dataManager.newSet(for: e)
		s.set(mainInfo: 10)
		s.set(secondaryInfo: 5)
		s.set(rest: 60)
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
	}
	
	private func assertCall(file: StaticString = #file, line: UInt = #line, _ where: (DelegateCalls) -> Bool) {
		let n = calls.count
		calls.removeAll { `where`($0) }
		if calls.count != n - 1{
			XCTFail("Call not found", file: file, line: line)
		}
	}
	
	private func waitCalls(n: Int) -> [XCTestExpectation] {
		let e = [()-> XCTestExpectation](repeating: { return XCTestExpectation() }, count: n).map { $0() }
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
		#warning("Record called")
	}
	
	func stopTimer() {
		#warning("Record called")
	}
	
	func setCurrentExercizeViewHidden(_ hidden: Bool) {
		self.calls.append(.setCurrentExercizeViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setExercizeName(_ name: String) {
		#warning("Record called")
	}
	
	func setCurrentSetViewHidden(_ hidden: Bool) {
		#warning("Record called")
	}
	
	func setCurrentSetText(_ text: NSAttributedString) {
		#warning("Record called")
	}
	
	func setOtherSetsViewHidden(_ hidden: Bool) {
		#warning("Record called")
	}
	
	func setOtherSetsText(_ text: NSAttributedString) {
		#warning("Record called")
	}
	
	func setSetDoneButtonHidden(_ hidden: Bool) {
		#warning("Record called")
	}
	
	func startRestTimer(to date: Date) {
		#warning("Record called")
	}
	
	func stopRestTimer() {
		#warning("Record called")
	}
	
	func setRestViewHidden(_ hidden: Bool) {
		self.calls.append(.setRestViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setRestEndButtonHidden(_ hidden: Bool) {
		#warning("Record called")
	}
	
	func setWorkoutDoneViewHidden(_ hidden: Bool) {
		self.calls.append(.setWorkoutDoneViewHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setWorkoutDoneText(_ text: String) {
		#warning("Record called")
	}
	
	func setWorkoutDoneButtonEnabled(_ enabled: Bool) {
		#warning("Record called")
	}
	
	func disableGlobalActions() {
		#warning("Record called")
	}
	
	func setNextUpTextHidden(_ hidden: Bool) {
		self.calls.append(.setNextUpTextHidden(hidden))
		expectations.popLast()?.fulfill()
	}
	
	func setNextUpText(_ text: NSAttributedString) {
		#warning("Record called")
	}
	
	func notifyEndRest() {
		#warning("Record called")
	}
	
	func endNotifyEndRest() {
		#warning("Record called")
	}
	
	func notifyExercizeChange(isRest: Bool) {
		#warning("Record called")
	}
	
	func askUpdateWeight(with data: UpdateSecondaryInfoData) {
		#warning("Record called")
	}
	
	func workoutHasStarted() {
		self.calls.append(.workoutHasStarted)
		expectations.popLast()?.fulfill()
	}
	
	func exitWorkoutTracking() {
		#warning("Record called")
	}
	
}
