//
//  GTCircuitTests.swift
//  Model Tests
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import XCTest
@testable import MBLibrary
@testable import GymTrackerCore

class GTCircuitTests: XCTestCase {
	
	private var circuit, choice: GTCircuit!
	
	private func newValidExercize() -> GTSimpleSetsExercize {
		let e = dataManager.newExercize()
		e.set(name: "Exercize")
		_ = dataManager.newSet(for: e)
		
		return e
	}
	
    override func setUp() {
        super.setUp()
		
		let nE = { () -> GTSimpleSetsExercize in
			let e = dataManager.newExercize()
			e.set(name: "Exercize")
			return e
		}
		
		circuit = dataManager.newCircuit()
		do {
			let e6 = nE()
			let e7 = nE()
			let e8 = nE()
			
			circuit.add(parts: e6, e7, e8)
			e6.enableCircuitRest(true)
			e7.enableCircuitRest(true)
			e8.enableCircuitRest(true)
		}
		
		choice = dataManager.newCircuit()
		do {
			let e1 = nE()
			let e2 = nE()
			let e3 = nE()
			let e4 = nE()
			let ch = dataManager.newChoice()
			
			choice.add(parts: e1, e2, ch)
			ch.add(parts: e3, e4)
			e1.enableCircuitRest(true)
			e4.enableCircuitRest(true)
		}
	}
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		dataManager.discardAllChanges()
		
		super.tearDown()
    }
	
	func testIsValidParent() {
		XCTAssertFalse(circuit.isValid)
		XCTAssertFalse(circuit.isSubtreeValid)
		
		let e6 = circuit[0] as! GTSimpleSetsExercize
		let e7 = circuit[1] as! GTSimpleSetsExercize
		let e8 = circuit[2] as! GTSimpleSetsExercize
		
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e8)
		_ = dataManager.newSet(for: e8)
		
		XCTAssertFalse(circuit.isSubtreeValid)
		XCTAssertFalse(circuit.isValid)
		XCTAssertEqual(circuit.exercizesError, [1])
		
		_ = dataManager.newSet(for: e7)
		
		XCTAssertTrue(circuit.isSubtreeValid)
		XCTAssertFalse(circuit.isValid)
		XCTAssertEqual(circuit.exercizesError, [])
		
		let w = dataManager.newWorkout()
		w.add(parts: circuit)
		XCTAssertTrue(circuit.isSubtreeValid)
		XCTAssertTrue(circuit.isValid)
		XCTAssertEqual(circuit.exercizesError, [])
		XCTAssertEqual(circuit.parentLevel as? GTWorkout, w)

		let e1 = choice[0] as! GTSimpleSetsExercize
		let e2 = choice[1] as! GTSimpleSetsExercize
		let ch = choice[2] as! GTChoice
		let e3 = ch[0]!
		let e4 = ch[1]!
		
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		_ = dataManager.newSet(for: e3)
		_ = dataManager.newSet(for: e4)
		_ = dataManager.newSet(for: e4)
		
		XCTAssertFalse(choice.isSubtreeValid)
		XCTAssertFalse(choice.isValid)
		XCTAssertEqual(choice.exercizesError, [2])
		
		w.add(parts: choice)
		_ = dataManager.newSet(for: e1)
		_ = dataManager.newSet(for: e2)
		_ = dataManager.newSet(for: e3)
		
		XCTAssertTrue(circuit.isSubtreeValid)
		XCTAssertTrue(choice.isValid)
		XCTAssertEqual(choice.exercizesError, [])
	}
	
	func testReorderParent() {
		let w = dataManager.newWorkout()
		w.add(parts: circuit, dataManager.newExercize())
		
		let w2 = dataManager.newWorkout()
		w2.add(parts: circuit)
		
		XCTAssertNotEqual(w[0], circuit)
		XCTAssertEqual(w[0]?.order, 0)
		XCTAssertEqual(w.exercizes.count, 1)
	}
	
	func testPurgeSetting() {
		let e = dataManager.newExercize()
		XCTAssertFalse(e.hasCircuitRest)
		e.forceEnableCircuitRest(true)
		XCTAssertTrue(e.hasCircuitRest)
		circuit.purgeInvalidSettings()
		XCTAssertTrue(e.hasCircuitRest)
		
		circuit.add(parts: e)
		XCTAssertTrue(e.hasCircuitRest)
		circuit.purgeInvalidSettings()
		XCTAssertTrue(e.hasCircuitRest)
	}
	
	func testExList() {
		let c = dataManager.newCircuit()
		XCTAssertEqual(c.exercizeList, [])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(c.exercizeList, [e2, e1])
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
		
		c.add(parts: e2)
		XCTAssertEqual(c.exercizeList, [e1, e2])
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
	}
	
	func testSetSubscript() {
		let c = dataManager.newCircuit()
		XCTAssertNil(c[-1])
		XCTAssertNil(c[0])
		XCTAssertNil(c[1])
		
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertNil(c[-1])
		XCTAssertEqual(c[0], e2)
		XCTAssertEqual(c[1], e1)
		XCTAssertNil(c[2])
	}
	
	func testMove() {
		let c = dataManager.newCircuit()
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
		
		c.movePartAt(number: 0, to: 1)
		
		XCTAssertEqual(e1.order, 0)
		XCTAssertEqual(e2.order, 1)
		
		c.movePartAt(number: 1, to: 0)
		
		XCTAssertEqual(e1.order, 1)
		XCTAssertEqual(e2.order, 0)
	}
	
	func testRemovePart() {
		let c = dataManager.newCircuit()
		let e1 = newValidExercize()
		let e2 = newValidExercize()
		c.add(parts: e2, e1)
		
		XCTAssertEqual(c.exercizes.count, 2)
		
		c.remove(part: e2)
		XCTAssertEqual(c.exercizes.count, 1)
		XCTAssertEqual(c[0], e1)
	}

	func testSubtree() {
		let e1 = choice[0] as! GTSimpleSetsExercize
		let e2 = choice[1] as! GTSimpleSetsExercize
		let ch = choice[2] as! GTChoice
		let e3 = ch[0]!
		let e4 = ch[1]!
		
		let sets = Set(arrayLiteral: dataManager.newSet(for: e1), dataManager.newSet(for: e2), dataManager.newSet(for: e3), dataManager.newSet(for: e4), dataManager.newSet(for: e4), dataManager.newSet(for: e1), dataManager.newSet(for: e2), dataManager.newSet(for: e3))
		
		XCTAssertEqual(choice.subtreeNodeList, Set(arrayLiteral: ch, e1, e2, e3, e4, choice).union(sets))
	}
	
	func testExport() {
		let e6 = circuit[0] as! GTSimpleSetsExercize
		let e7 = circuit[1] as! GTSimpleSetsExercize
		let e8 = circuit[2] as! GTSimpleSetsExercize
		
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e6)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e7)
		_ = dataManager.newSet(for: e8)
		_ = dataManager.newSet(for: e8)
		
		let xml = circuit.export()
		assert(string: xml, containsInOrder: [GTCircuit.circuitTag, GTCircuit.exercizesTag, GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.hasCircuitRestTag, "</", GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.hasCircuitRestTag, "</", GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.exercizeTag, GTSimpleSetsExercize.hasCircuitRestTag, "</", GTSimpleSetsExercize.exercizeTag, "</", GTCircuit.exercizesTag, "</", GTCircuit.circuitTag])
	}
	
	static func validXml() -> XMLNode {
		let xml = XMLNode(name: GTCircuit.circuitTag)
		let exs = XMLNode(name: GTCircuit.exercizesTag)
		xml.add(child: exs)
		exs.add(child: GTSimpleSetsExercizeTests.validXml())
		exs.add(child: GTSimpleSetsExercizeTests.validXml(name: 2))
		exs.add(child: GTChoiceTests.validXml())
		
		return xml
	}
	
	func testImport() {
		do {
			_ = try GTCircuit.import(fromXML: XMLNode(name: ""), withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertEqual(o, [])
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercizesTag)
			xml.add(child: exs)
			
			_ = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertEqual(o.count, 1)
			XCTAssertTrue(o.first is GTCircuit)
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercizesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExercizeTests.validXml())
			
			_ = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTCircuit) && !($0 is GTSimpleSetsExercize) && !($0 is GTRepsSet) })
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercizesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExercizeTests.validXml())
			exs.add(child: GTSimpleSetsExercizeTests.validXml(name: 2))
			exs.add(child: GTSimpleSetsExercizeTests.validXml(name: 3))
			
			let c = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTAssertTrue(c.isSubtreeValid)
			
			XCTAssertEqual(c.exercizes.count, 3)
			XCTAssertEqual((c[0] as? GTSimpleSetsExercize)?.name, "Ex 1")
			XCTAssertEqual((c[1] as? GTSimpleSetsExercize)?.name, "Ex 2")
			XCTAssertEqual((c[2] as? GTSimpleSetsExercize)?.name, "Ex 3")
		} catch _ {
			XCTFail()
		}
		
		do {
			let xml = XMLNode(name: GTCircuit.circuitTag)
			let exs = XMLNode(name: GTCircuit.exercizesTag)
			xml.add(child: exs)
			exs.add(child: GTSimpleSetsExercizeTests.validXml())
			exs.add(child: GTSimpleSetsExercizeTests.validXml(name: 2))
			let chXml = GTChoiceTests.validXml()
			exs.add(child: chXml)
			chXml.children[0].children[1].children[1].add(child: GTRepsSetTests.validXml())
			
			_ = try GTCircuit.import(fromXML: xml, withDataManager: dataManager)
			XCTFail()
		} catch GTDataImportError.failure(let o) {
			XCTAssertFalse(o.isEmpty)
			XCTAssertNil(o.first { !($0 is GTCircuit) && !($0 is GTSimpleSetsExercize) && !($0 is GTRepsSet) && !($0 is GTChoice)})
		} catch _ {
			XCTFail()
		}
		
		do {
			let c = try GTCircuit.import(fromXML: GTCircuitTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(c.isSubtreeValid)
			
			XCTAssertEqual(c.exercizes.count, 3)
			XCTAssertEqual((c[0] as? GTSimpleSetsExercize)?.name, "Ex 1")
			XCTAssertEqual((c[1] as? GTSimpleSetsExercize)?.name, "Ex 2")
			XCTAssertTrue(c[2] is GTChoice)
		} catch _ {
			XCTFail()
		}
		
		do {
			let o = try GTDataObject.import(fromXML: GTCircuitTests.validXml(), withDataManager: dataManager)
			XCTAssertTrue(o is GTCircuit)
		} catch _ {
			XCTFail()
		}
	}
    
}
