//
//  GTChoiceTests.swift
//  Gym Tracker Tests
//
//  Created by Marco Boschi on 16/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import XCTest
@testable import MBLibrary
@testable import GymTrackerCore

class GTChoiceTests: XCTestCase {

	private var ch: GTChoice!
	
    override func setUp() {
		super.setUp()
		
        ch = dataManager.newChoice()
    }
	
	private func newValidExercize() -> GTSimpleSetsExercize {
		let e = dataManager.newExercize()
		e.set(name: "Exercize")
		_ = dataManager.newSet(for: e)
		
		return e
	}

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }

	func testIsValidParent() {
		XCTAssertFalse(ch.isSubtreeValid)
		XCTAssertFalse(ch.isValid)
		
		ch.add(parts: newValidExercize())
		XCTAssertFalse(ch.isSubtreeValid)
		XCTAssertFalse(ch.isValid)

		let w = dataManager.newWorkout()
		w.add(parts: ch, dataManager.newExercize())
		XCTAssertFalse(ch.isSubtreeValid)
		XCTAssertFalse(ch.isValid)
		ch.add(parts: newValidExercize())
		XCTAssertTrue(ch.isSubtreeValid)
		XCTAssertTrue(ch.isValid)
		XCTAssertEqual(ch.parentLevel as? GTWorkout, w)

		let c = dataManager.newCircuit()
		c.add(parts: ch, dataManager.newExercize())
		XCTAssertNotEqual(w[0], ch)
		XCTAssertEqual(w[0]?.order, 0)
		XCTAssertEqual(w.parts.count, 1)
		
		XCTAssertTrue(ch.isSubtreeValid)
		XCTAssertTrue(ch.isValid)
		XCTAssertEqual(ch.parentLevel as? GTCircuit, c)
		
		w.add(parts: ch)
		XCTAssertNotEqual(c[0], ch)
		XCTAssertEqual(c[0]?.order, 0)
		XCTAssertEqual(c.exercizes.count, 1)
	}
	
	func testPurgeSetting() {
		let e = newValidExercize()
		ch.add(parts: e)

		XCTAssertFalse(ch.hasCircuitRest)
		XCTAssertFalse(e.hasCircuitRest)
		ch.forceEnableCircuitRest(true)
		e.forceEnableCircuitRest(true)
		XCTAssertFalse(ch.hasCircuitRest)
		XCTAssertTrue(e.hasCircuitRest)
		ch.purgeInvalidSettings()
		XCTAssertFalse(ch.hasCircuitRest)
		XCTAssertFalse(e.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: ch)
		XCTAssertFalse(ch.hasCircuitRest)
		XCTAssertFalse(e.hasCircuitRest)
		ch.forceEnableCircuitRest(true)
		e.forceEnableCircuitRest(true)
		XCTAssertFalse(ch.hasCircuitRest)
		XCTAssertTrue(e.hasCircuitRest)
		ch.purgeInvalidSettings()
		XCTAssertFalse(ch.hasCircuitRest)
		XCTAssertTrue(e.hasCircuitRest)
	}
	
	func testInCircuitError() {
		XCTAssertNil(ch.inCircuitExercizesError)
		
		let c = dataManager.newCircuit()
		c.add(parts: ch)
		
		XCTAssertEqual(ch.inCircuitExercizesError, [])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e1, e2)
		
		XCTAssertTrue(ch.isValid)
		XCTAssertEqual(ch.inCircuitExercizesError, [])
		
		_ = dataManager.newSet(for: e1)
		
		XCTAssertFalse(ch.isValid)
		XCTAssertEqual(ch.inCircuitExercizesError, [1])
		
		let e3 = newValidExercize()
		ch.add(parts: e3)
		
		XCTAssertFalse(ch.isValid)
		XCTAssertEqual(ch.inCircuitExercizesError, [0])
	}
	
	func testInCircuit() {
		XCTAssertFalse(ch.isInCircuit)
		XCTAssertNil(ch.circuitStatus)
		
		let c = dataManager.newCircuit()
		c.add(parts: ch, dataManager.newExercize())
		
		XCTAssertTrue(ch.isInCircuit)
		if let (n, t) = ch.circuitStatus {
			XCTAssertEqual(n, 1)
			XCTAssertEqual(t, 2)
		} else {
			XCTFail("Exercize not in circuit")
		}
	}
	
	func testCircuitRest() {
		XCTAssertFalse(ch.hasCircuitRest)
		ch.enableCircuitRest(true)
		XCTAssertFalse(ch.hasCircuitRest)
		
		let c = dataManager.newCircuit()
		c.add(parts: ch)
		ch.enableCircuitRest(true)
		XCTAssertFalse(ch.hasCircuitRest)
	}
	
	func testSetCount() {
		XCTAssertNil(ch.setsCount)
		
		let e2 = newValidExercize()
		ch.add(parts: newValidExercize(), e2)
		
		XCTAssertEqual(ch.setsCount, 1)
		
		_ = dataManager.newSet(for: e2)
		
		XCTAssertNil(ch.setsCount)
	}
	
	func testExList() {
		XCTAssertEqual(ch.exercizeList, [])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)
		
		XCTAssertEqual(ch.exercizeList, [e2, e1])
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)

		ch.add(parts: e2)
		XCTAssertEqual(ch.exercizeList, [e1, e2])
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
	}
	
	func testMove() {
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
		
		ch.movePartAt(number: 0, to: 1)
		
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
		
		ch.movePartAt(number: 1, to: 0)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
	}
	
	func testSetSubscript() {
		XCTAssertNil(ch[-1])
		XCTAssertNil(ch[0])
		XCTAssertNil(ch[1])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)

		XCTAssertNil(ch[-1])
		XCTAssertEqual(ch[0], e2)
		XCTAssertEqual(ch[1], e1)
		XCTAssertNil(ch[2])
	}
	
	func testRemovePart() {
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)
		
		XCTAssertEqual(ch.exercizes.count, 2)
		
		ch.remove(part: e2)
		XCTAssertEqual(ch.exercizes.count, 1)
		XCTAssertEqual(ch[0], e1)
	}
	
	func testSubtree() {
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		ch.add(parts: e2, e1)
		
		XCTAssertEqual(ch.subtreeNodeList, Set(arrayLiteral: ch, e1, e2).union(e1.sets.union(e2.sets)))
	}
	
	func testExport() {
		ch.add(parts: newValidExercize())
		ch.add(parts: newValidExercize())
		let xml = ch.export()
		
		assert(string: xml, containsInOrder: [GTChoice.choiceTag, GTChoice.exercizesTag, GTSimpleSetsExercize.exercizeTag, "</", GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.exercizeTag, "</", GTSimpleSetsExercize.exercizeTag, "</", GTChoice.exercizesTag, "</", GTChoice.choiceTag])
	}
	
	static let validXml: XMLNode = {
		let xml = XMLNode(name: GTChoice.choiceTag)
		let exs = XMLNode(name: GTChoice.exercizesTag)
		xml.add(child: exs)
		exs.add(child: GTSimpleSetsExercizeTests.validXml)
		exs.add(child: GTSimpleSetsExercizeTests.validXML(name: 2))
		exs.add(child: GTSimpleSetsExercizeTests.validXML(name: 3))
		
		return xml
	}()
	
	func testImport() {
		do {
			_ = try GTChoice.import(fromXML: XMLNode(name: ""), withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertEqual(o, [])
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTChoice.choiceTag)
			let exs = XMLNode(name: GTChoice.exercizesTag)
			xml.add(child: exs)
			
			_ = try GTChoice.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertEqual(o.count, 1)
			XCTAssertTrue(o.first is GTChoice)
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTChoice.choiceTag)
			let exs = XMLNode(name: GTChoice.exercizesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExercizeTests.validXml)
			
			_ = try GTChoice.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTChoice) && !($0 is GTSimpleSetsExercize) && !($0 is GTRepsSet) })
		} catch _ {
			XCTFail()
		}
		
		do {
			let e = try GTChoice.import(fromXML: GTChoiceTests.validXml, withDataManager: dataManager)
			XCTAssertTrue(e.isSubtreeValid)
			
			XCTAssertFalse(e.hasCircuitRest)
			XCTAssertEqual(e.exercizes.count, 3)
			XCTAssertEqual(e[0]?.name, "Ex 1")
			XCTAssertFalse(e[0]!.hasCircuitRest)
			XCTAssertEqual(e[1]?.name, "Ex 2")
			XCTAssertFalse(e[1]!.hasCircuitRest)
			XCTAssertEqual(e[2]?.name, "Ex 3")
			XCTAssertFalse(e[2]!.hasCircuitRest)
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = GTChoiceTests.validXml
			let cr = XMLNode(name: GTSimpleSetsExercize.hasCircuitRestTag)
			cr.set(content: "true")
			xml.children[0].children[1].add(child: cr)
			let e = try GTChoice.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertTrue(e.isSubtreeValid)
			let c = dataManager.newCircuit()
			c.add(parts: e)
			
			XCTAssertFalse(e.hasCircuitRest)
			XCTAssertEqual(e.exercizes.count, 3)
			XCTAssertEqual(e[0]?.name, "Ex 1")
			XCTAssertFalse(e[0]!.hasCircuitRest)
			XCTAssertEqual(e[1]?.name, "Ex 2")
			XCTAssertTrue(e[1]!.hasCircuitRest)
			XCTAssertEqual(e[2]?.name, "Ex 3")
			XCTAssertFalse(e[2]!.hasCircuitRest)
		} catch _ {
			XCTFail()
		}
		
		do {
			let o = try GTDataObject.import(fromXML: GTChoiceTests.validXml, withDataManager: dataManager)
			XCTAssertTrue(o is GTChoice)
		} catch _ {
			XCTFail()
		}
	}

}
