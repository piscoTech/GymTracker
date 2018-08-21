//
//  GTSimpleSetsExercizeTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import MBLibrary
@testable import GymTrackerCore

class GTSimpleSetsExercizeTests: XCTestCase {
	
	private var e: GTSimpleSetsExercize!

    override func setUp() {
		super.setUp()
		
        e = dataManager.newExercize()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }

    func testIsValidParent() {
		XCTAssertFalse(e.isSubtreeValid)
		XCTAssertFalse(e.isValid)
		
		e.set(name: "E")
		XCTAssertFalse(e.isSubtreeValid)
		XCTAssertFalse(e.isValid)
		
		_ = dataManager.newSet(for: e)
		XCTAssertTrue(e.isSubtreeValid)
		XCTAssertFalse(e.isValid)
		
		let w = dataManager.newWorkout()
		w.add(parts: e, dataManager.newExercize())
		XCTAssertTrue(e.isSubtreeValid)
		XCTAssertTrue(e.isValid)
		XCTAssertEqual(e.parentLevel as? GTWorkout, w)
		
		let c = dataManager.newCircuit()
		c.add(parts: e, dataManager.newExercize())
		XCTAssertNotEqual(w[0], e)
		XCTAssertEqual(w[0]?.order, 0)
		XCTAssertEqual(w.parts.count, 1)
		
		XCTAssertTrue(e.isSubtreeValid)
		XCTAssertTrue(e.isValid)
		XCTAssertEqual(e.parentLevel as? GTCircuit, c)
		
		let ch = dataManager.newChoice()
		ch.add(parts: e, dataManager.newExercize())
		XCTAssertNotEqual(c[0], e)
		XCTAssertEqual(c[0]?.order, 0)
		XCTAssertEqual(c.exercizes.count, 1)
		
		XCTAssertTrue(e.isSubtreeValid)
		XCTAssertTrue(e.isValid)
		XCTAssertEqual(e.parentLevel as? GTChoice, ch)
		
		w.add(parts: e)
		XCTAssertNotEqual(ch[0], e)
		XCTAssertEqual(ch[0]?.order, 0)
		XCTAssertEqual(ch.exercizes.count, 1)
    }
	
	func testPurgeSetting() {
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		XCTAssertTrue(e.purge().isEmpty)
		XCTAssertFalse(e.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		XCTAssertTrue(e.purge().isEmpty)
		XCTAssertTrue(e.hasCircuitRest)
	}
	
	func testSetList() {
		XCTAssertEqual(e.setList, [])
		
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.setList, [s1, s2])
	}
	
	func testSetSubscript() {
		XCTAssertNil(e[-1])
		XCTAssertNil(e[0])
		XCTAssertNil(e[1])
		
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertNil(e[-1])
		XCTAssertEqual(e[0], s1)
		XCTAssertEqual(e[1], s2)
		XCTAssertNil(e[2])
	}
	
	func testSetCount() {
		XCTAssertEqual(e.setsCount, 0)
		
		_ = dataManager.newSet(for: e)
		_ = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.setsCount, 2)
	}
	
	func testSetName() {
		let n = "Ex"
		e.set(name: n)
		XCTAssertEqual(e.name, n)
	}
	
	func testChoice() {
		XCTAssertFalse(e.isInChoice)
		XCTAssertNil(e.choiceStatus)
	
		let c = dataManager.newChoice()
		c.add(parts: e, dataManager.newExercize())
		
		XCTAssertTrue(e.isInChoice)
		if let (n, t) = e.choiceStatus {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in choice")
		}
	}
	
	func testInCircuit() {
		XCTAssertFalse(e.isInCircuit)
		XCTAssertNil(e.circuitStatus)
		
		let c = dataManager.newCircuit()
		c.add(parts: e, dataManager.newExercize())
		
		XCTAssertTrue(e.isInCircuit)
		if let (n, t) = e.circuitStatus {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in circuit")
		}
		
		let ch = dataManager.newChoice()
		ch.add(parts: e)
		XCTAssertFalse(e.isInCircuit)
		XCTAssertNil(e.circuitStatus)
		
		c.add(parts: ch)
		if let (n, t) = e.circuitStatus {
			XCTAssertEqual(n, 2)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in circuit")
		}
	}
	
	func testCircuitRest() {
		XCTAssertFalse(e.hasCircuitRest)
		e.enableCircuitRest(true)
		XCTAssertFalse(e.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		e.enableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		
		let ch = dataManager.newChoice()
		ch.add(parts: e)
		XCTAssertFalse(e.hasCircuitRest)
		c.add(parts: ch)
		e.enableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
	}

	func testRestStatus() {
		var (g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		(g, l) = e.restStatus
		XCTAssertFalse(g)
		XCTAssertFalse(l)
		e.enableCircuitRest(true)
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		let e2 = dataManager.newExercize()
		c.add(parts: e2)
		e2.enableCircuitRest(true)
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertTrue(l)
		(g, l) = e2.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		
		let ch = dataManager.newChoice()
		ch.add(parts: e)
		c.add(parts: ch)
		(g, l) = e.restStatus
		XCTAssertFalse(g)
		XCTAssertFalse(l)
		e.enableCircuitRest(true)
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		ch.add(parts: dataManager.newExercize())
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertFalse(l)
		c.add(parts: dataManager.newExercize())
		(g, l) = e.restStatus
		XCTAssertTrue(g)
		XCTAssertTrue(l)
	}
	
	func testRemoveSet() {
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.setsCount, 2)
		e.removeSet(s1)
		XCTAssertEqual(e.setsCount, 1)
		XCTAssertEqual(e[0], s2)
	}
	
	func testCompactSets() {
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertTrue(e.purge().isEmpty)
		XCTAssertEqual(e.setsCount, 2)
		XCTAssertEqual(e[0], s1)
		XCTAssertEqual(e[1], s2)
		
		s1.set(mainInfo: 0)
		XCTAssertEqual(e.purge(), [s1])
		XCTAssertEqual(e.setsCount, 1)
		XCTAssertEqual(e[0], s2)
	}
	
	func testSubtree() {
		let s1 = dataManager.newSet(for: e)
		let s2 = dataManager.newSet(for: e)
		
		XCTAssertEqual(e.subtreeNodes, [e, s1, s2])
	}
	
	func testExport() {
		e.set(name: "E")
		let s = dataManager.newSet(for: e)
		s.set(mainInfo: 5)
		s.set(secondaryInfo: 7.5)
		s.set(rest: 30)
		
		var xml = e.export()
		assert(string: xml, containsInOrder: [GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.nameTag, e.name.description, "</", GTSimpleSetsExercize.nameTag, GTSimpleSetsExercize.setsTag, GTRepsSet.weightTag, GTRepsSet.restTag, GTRepsSet.restTag, "</", GTSimpleSetsExercize.setsTag, "</", GTSimpleSetsExercize.exercizeTag], thenNotContains: GTSimpleSetsExercize.hasCircuitRestTag)
		XCTAssertNil(xml.range(of: GTSimpleSetsExercize.isCircuitTag))
		
		let c = dataManager.newCircuit()
		c.add(parts: e)
		xml = e.export()
		assert(string: xml, containsInOrder: [GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.nameTag, e.name.description, "</", GTSimpleSetsExercize.nameTag, GTSimpleSetsExercize.hasCircuitRestTag, "false", "</", GTSimpleSetsExercize.hasCircuitRestTag, GTSimpleSetsExercize.setsTag, GTRepsSet.weightTag, GTRepsSet.restTag, GTRepsSet.restTag, "</", GTSimpleSetsExercize.setsTag, "</", GTSimpleSetsExercize.exercizeTag])
		XCTAssertNil(xml.range(of: GTSimpleSetsExercize.isCircuitTag))
		
		e.enableCircuitRest(true)
		xml = e.export()
		assert(string: xml, containsInOrder: [GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.nameTag, e.name.description, "</", GTSimpleSetsExercize.nameTag, GTSimpleSetsExercize.hasCircuitRestTag, "true", "</", GTSimpleSetsExercize.hasCircuitRestTag, GTSimpleSetsExercize.setsTag, GTRepsSet.weightTag, GTRepsSet.restTag, GTRepsSet.restTag, "</", GTSimpleSetsExercize.setsTag, "</", GTSimpleSetsExercize.exercizeTag])
		XCTAssertNil(xml.range(of: GTSimpleSetsExercize.isCircuitTag))
	}
	
	static func validXml(name n: Int = 1) -> XMLNode {
		let xml = XMLNode(name: GTSimpleSetsExercize.exercizeTag)
		let name = XMLNode(name: GTSimpleSetsExercize.nameTag)
		name.set(content: "Ex \(n)")
		let sets = XMLNode(name: GTSimpleSetsExercize.setsTag)
		xml.add(child: name)
		xml.add(child: sets)
		sets.add(child: GTRepsSetTests.validXml())
		sets.add(child: GTRepsSetTests.validXml(reps: 10))
		
		return xml
	}
	
	func testImport() {
		do {
			_ = try GTSimpleSetsExercize.import(fromXML: XMLNode(name: ""), withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertEqual(o, [])
		} catch _ {
			XCTFail()
		}

		do {
			let xml = XMLNode(name: GTSimpleSetsExercize.exercizeTag)
			let name = XMLNode(name: GTSimpleSetsExercize.nameTag)
			name.set(content: "")
			let sets = XMLNode(name: GTSimpleSetsExercize.setsTag)
			xml.add(child: name)
			xml.add(child: sets)
			sets.add(child: GTRepsSetTests.validXml())
			sets.add(child: GTRepsSetTests.validXml(reps: 10))
			
			_ = try GTSimpleSetsExercize.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTSimpleSetsExercize) && !($0 is GTRepsSet) })
		} catch _ {
			XCTFail()
		}

		do {
			let e = try GTSimpleSetsExercize.import(fromXML: GTSimpleSetsExercizeTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(e.isSubtreeValid)

			XCTAssertEqual(e.name, "Ex 1")
			XCTAssertFalse(e.hasCircuitRest)
			XCTAssertEqual(e.setsCount, 2)
			XCTAssertEqual(e[0]?.mainInfo, 5)
			XCTAssertEqual(e[1]?.mainInfo, 10)
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = GTSimpleSetsExercizeTests.validXml()
			let cr = XMLNode(name: GTSimpleSetsExercize.hasCircuitRestTag)
			cr.set(content: "true")
			xml.add(child: cr)
			let e = try GTSimpleSetsExercize.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertTrue(e.isSubtreeValid)
			XCTAssertTrue(e.hasCircuitRest)
			let c = dataManager.newCircuit()
			c.add(parts: e)
			
			XCTAssertEqual(e.name, "Ex 1")
			XCTAssertTrue(e.hasCircuitRest)
			XCTAssertEqual(e.setsCount, 2)
			XCTAssertEqual(e[0]?.mainInfo, 5)
			XCTAssertEqual(e[1]?.mainInfo, 10)
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = GTSimpleSetsExercizeTests.validXml()
			let cr = XMLNode(name: GTSimpleSetsExercize.hasCircuitRestTag)
			cr.set(content: "true")
			xml.add(child: cr)
			let e = try GTSimpleSetsExercize.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertTrue(e.isSubtreeValid)
			XCTAssertTrue(e.hasCircuitRest)
			let c = dataManager.newCircuit()
			c.add(parts: e)
			
			XCTAssertEqual(e.name, "Ex 1")
			XCTAssertTrue(e.hasCircuitRest)
			XCTAssertEqual(e.setsCount, 2)
			XCTAssertEqual(e[0]?.mainInfo, 5)
			XCTAssertEqual(e[1]?.mainInfo, 10)
		} catch _ {
			XCTFail()
		}
		
		do {
			let o = try GTDataObject.import(fromXML: GTSimpleSetsExercizeTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(o is GTSimpleSetsExercize)
		} catch _ {
			XCTFail()
		}
	}

}
