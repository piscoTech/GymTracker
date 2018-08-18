//
//  ImportExportTest.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 10/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import GymTrackerCore

class ImportExportTest: XCTestCase {
	
	private var importExpectation: XCTestExpectation!
	
	override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		importExpectation = XCTestExpectation(description: "Workout imported")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
        super.tearDown()
    }
	
	func testImportVersion_1_1_1() {
		let f = Bundle(for: type(of: self)).url(forResource: "oldVersion_1.1.1", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertTrue(valid)
			XCTAssertEqual(count, 9)
			XCTAssertNotNil(doPerform)
			doPerform?()
		}) { wrkt in
			XCTAssertEqual(wrkt?.count, 9)
			self.importExpectation.fulfill()
		}

		wait(for: [importExpectation], timeout: 5)
	}
	
	func testImportVersion_2_0() {
		let f = Bundle(for: type(of: self)).url(forResource: "oldVersion_2.0", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertTrue(valid)
			XCTAssertEqual(count, 8)
			XCTAssertNotNil(doPerform)
			doPerform?()
		}) { wrkt in
			XCTAssertEqual(wrkt?.count, 8)
			
			let w = wrkt![6]
			XCTAssertEqual(w.parts.count, 12)
			XCTAssertEqual(w.parts.filter { $0 is GTCircuit }.count, 2)
			
			for p in [w[8], w[11]] {
				if let c = p as? GTCircuit {
					XCTAssertEqual(c.exercizes.count, 2)
				} else {
					XCTFail("Circuit expected")
				}
			}
			
			self.importExpectation.fulfill()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
	func testImportVersion_3_0() {
		#warning("With a choice")
		XCTFail("Add me")
	}
	
	func testXsdInvalidSet() {
		let f = Bundle(for: type(of: self)).url(forResource: "invalidSet", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertFalse(valid)
			XCTAssertNil(count)
			XCTAssertNil(doPerform)
			
			self.importExpectation.fulfill()
		}) { _ in
			XCTFail()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
	func testXsdInvalidRest() {
		let f = Bundle(for: type(of: self)).url(forResource: "invalidRest", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertFalse(valid)
			XCTAssertNil(count)
			XCTAssertNil(doPerform)
			
			self.importExpectation.fulfill()
		}) { _ in
			XCTFail()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
	func testXsdInvalidExercize() {
		let f = Bundle(for: type(of: self)).url(forResource: "invalidExercize", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertFalse(valid)
			XCTAssertNil(count)
			XCTAssertNil(doPerform)
			
			self.importExpectation.fulfill()
		}) { _ in
			XCTFail()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
	func testXsdInvalidChoice() {
		let f = Bundle(for: type(of: self)).url(forResource: "invalidChoice", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertFalse(valid)
			XCTAssertNil(count)
			XCTAssertNil(doPerform)
			
			self.importExpectation.fulfill()
		}) { _ in
			XCTFail()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
	func testXsdInvalidCircuit() {
		let f = Bundle(for: type(of: self)).url(forResource: "invalidCircuit", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertFalse(valid)
			XCTAssertNil(count)
			XCTAssertNil(doPerform)
			
			self.importExpectation.fulfill()
		}) { _ in
			XCTFail()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
	func testXsdInvalidWorkout() {
		let f = Bundle(for: type(of: self)).url(forResource: "xsdInvalidWorkout", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertFalse(valid)
			XCTAssertNil(count)
			XCTAssertNil(doPerform)
			
			self.importExpectation.fulfill()
		}) { _ in
			XCTFail()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
	func testInvalidWorkout() {
		let f = Bundle(for: type(of: self)).url(forResource: "invalidWorkout", withExtension: "xml")!
		dataManager.importExportManager.import(f, isRestoring: false, performCallback: { (valid, count, doPerform) in
			XCTAssertTrue(valid)
			XCTAssertEqual(count, 1)
			XCTAssertNotNil(doPerform)
			
			doPerform?()
		}) { wrkt in
			XCTAssertEqual(wrkt?.count, 0)
			self.importExpectation.fulfill()
		}
		
		wait(for: [importExpectation], timeout: 5)
	}
	
}
