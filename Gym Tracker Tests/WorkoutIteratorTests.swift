//
//  WorkoutIteratorTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import Gym_Tracker

class WorkoutIteratorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
	
    func testSimpleWorkout() {
        XCTFail()
    }
	
	func testCircuitWorkout() {
		XCTFail()
	}
	
	func testContinueFromSaved() {
		XCTFail()
	}
	
	func testUpdateFromReceivedStatus() {
		XCTFail()
	}
    
}
