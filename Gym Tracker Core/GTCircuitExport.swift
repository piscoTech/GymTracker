//
//  GTCircuitExport.swift
//  Gym Tracker Core iOS
//
//  Created by Marco Boschi on 18/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTCircuit {
	
	static let circuitTag = "circuit"
	static let exercizesTag = "exercizes"
	
	override func export() -> String {
		var res = "<\(GTCircuit.circuitTag)>"
		res += "<\(GTCircuit.exercizesTag)>\(self.exercizeList.map { $0.export() }.reduce("") { $0 + $1 })</\(GTCircuit.exercizesTag)>"
		res += "</\(GTCircuit.circuitTag)>"
		
		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTCircuit {
		guard xml.name == GTCircuit.circuitTag,
			let ex = xml.children.first(where: { $0.name == GTCircuit.exercizesTag })?.children else {
				throw GTDataImportError.failure([])
		}

		let c = dataManager.newCircuit()
		for e in ex {
			do {
				let o = try GTDataObject.import(fromXML: e, withDataManager: dataManager)
				guard let exercize = o as? GTSetsExercize else {
					throw GTDataImportError.failure(c.subtreeNodeList.union([o]))
				}

				c.add(parts: exercize)
			} catch GTDataImportError.failure(let obj) {
				throw GTDataImportError.failure(c.subtreeNodeList.union(obj))
			}
		}

		if c.isSubtreeValid {
			return c
		} else {
			throw GTDataImportError.failure(c.subtreeNodeList)
		}
	}
}
