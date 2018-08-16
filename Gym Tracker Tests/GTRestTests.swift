//
//  GTRestTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class GTRestTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
	}
	
	func testIsValidParent() {
		let r = dataManager.newRest()
		XCTAssertFalse(r.isValid)
		
		let w = dataManager.newWorkout()
		w.add(parts: r)
		XCTAssertTrue(r.isValid)
	}
	
	func testSetRest() {
		let r = dataManager.newRest()
		
		r.set(rest: 0)
		XCTAssertEqual(r.rest, GTRest.minRest)
		
		r.set(rest: 40)
		XCTAssertEqual(r.rest, 30)
		
		r.set(rest: 50)
		XCTAssertEqual(r.rest, 60)
		
		r.set(rest: 120)
		XCTAssertEqual(r.rest, 120)
		
		r.set(rest: -70)
		XCTAssertEqual(r.rest, GTRest.minRest)
	}
	
	func testSubtree() {
		let r = dataManager.newRest()
		XCTAssertEqual(r.subtreeNodeList, [r])
	}
	
}
