//
//  GTRepsSetTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import MBLibrary
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
		XCTAssertTrue(s.isSubtreeValid)
		XCTAssertTrue(s.isValid)
		
        s.set(mainInfo: 0)
		s.set(secondaryInfo: 0)
		XCTAssertFalse(s.isSubtreeValid)
		XCTAssertFalse(s.isValid)
		
		s.set(mainInfo: 10)
		XCTAssertTrue(s.isSubtreeValid)
		XCTAssertTrue(s.isValid)
		
		let set = dataManager.newSet()
		XCTAssertTrue(set.isSubtreeValid)
		XCTAssertFalse(set.isValid)
		
		e.add(set: set)
		XCTAssertTrue(set.isSubtreeValid)
		XCTAssertTrue(set.isValid)
    }

	func testPurgeSetting() {
		s.purgeInvalidSettings()
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
	
	func testExport() {
		s.set(mainInfo: 5)
		s.set(secondaryInfo: 7.5)
		s.set(rest: 30)
		
		let xml = s.export()
		assert(string: xml, containsInOrder: [GTRepsSet.setTag, GTRepsSet.repsTag, s.mainInfo.description, "</", GTRepsSet.repsTag, GTRepsSet.weightTag, s.secondaryInfo.description ,"</", GTRepsSet.weightTag, GTRepsSet.restTag, Int(s.rest).description, "</", GTRepsSet.restTag, "</", GTRepsSet.setTag])
	}
	
	static func validXml(reps r: Int = 5) -> XMLNode {
		let xml = XMLNode(name: GTRepsSet.setTag)
		let reps = XMLNode(name: GTRepsSet.repsTag)
		reps.set(content: r.description)
		let w = XMLNode(name: GTRepsSet.weightTag)
		w.set(content: "10")
		let rest = XMLNode(name: GTRepsSet.restTag)
		rest.set(content: "30")
		xml.add(child: reps)
		xml.add(child: w)
		xml.add(child: rest)
		
		return xml
	}
	
	func testImport() {
		do {
			_ = try GTRepsSet.import(fromXML: XMLNode(name: ""), withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertEqual(o, [])
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTRepsSet.setTag)
			let reps = XMLNode(name: GTRepsSet.repsTag)
			reps.set(content: "0")
			let w = XMLNode(name: GTRepsSet.weightTag)
			w.set(content: "10")
			let rest = XMLNode(name: GTRepsSet.restTag)
			rest.set(content: "30")
			xml.add(child: reps)
			xml.add(child: w)
			xml.add(child: rest)
			_ = try GTRepsSet.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertEqual(o.count, 1)
			XCTAssertTrue(o.first is GTRepsSet)
		} catch _ {
			XCTFail()
		}
		
		do {
			let s = try GTRepsSet.import(fromXML: GTRepsSetTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(s.isSubtreeValid)
			
			XCTAssertEqual(s.mainInfo, 5)
			XCTAssertEqual(s.secondaryInfo, 10)
			XCTAssertEqual(s.rest, 30)
		} catch _ {
			XCTFail()
		}
		
		do {
			let o = try GTDataObject.import(fromXML: GTRepsSetTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(o is GTRepsSet)
		} catch _ {
			XCTFail()
		}
	}

}
