//
//  GTRepsSetTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class GTRepsSetTests: XCTestCase {
	
	private var e: GTSimpleSetsExercize!
	private var s: GTRepsSet!

    override func setUp() {
		super.setUp()
		
        e = dataManager.newExercize()
		s = dataManager.newSet(for: e)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }

    func testIsValid() {
		XCTAssertTrue(s.isValid)
		
        s.set(mainInfo: 0)
		s.set(secondaryInfo: 0)
		XCTAssertFalse(s.isValid)
		
		s.set(mainInfo: 10)
		XCTAssertTrue(s.isValid)
    }
	
	func testSetReps() {
		s.set(mainInfo: 0)
		XCTAssertEqual(s.mainInfo, 0)
		
		s.set(mainInfo: -1)
		XCTAssertEqual(s.mainInfo, 0)
		
		s.set(mainInfo: 5)
		XCTAssertEqual(s.mainInfo, 5)
	}
	
	func testSetWeight() {
		s.set(secondaryInfo: 0)
		XCTAssertEqual(s.secondaryInfo, 0)
		
		s.set(secondaryInfo: -10)
		XCTAssertEqual(s.secondaryInfo, 0)
		
		s.set(secondaryInfo: 5)
		XCTAssertEqual(s.secondaryInfo, 5)
		
		s.set(secondaryInfo: 5.1)
		XCTAssertEqual(s.secondaryInfo, 5)
		
		s.set(secondaryInfo: 5.3)
		XCTAssertEqual(s.secondaryInfo, 5.5)
	}
	
	func testSetRest() {
		s.set(rest: 0)
		XCTAssertEqual(s.rest, 0)
		
		s.set(rest: 10)
		XCTAssertEqual(s.rest, 0)
		
		s.set(rest: 30)
		XCTAssertEqual(s.rest, 30)
		
		s.set(rest: 40)
		XCTAssertEqual(s.rest, 30)
		
		s.set(rest: -90)
		XCTAssertEqual(s.rest, 0)
	}

	func testSubtree() {
		XCTAssertEqual(s.subtreeNodeList, [s])
	}

}
