//
//  GTChoiceExport.swift
//  Gym Tracker Core iOS
//
//  Created by Marco Boschi on 17/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTChoice {
	
	static let choiceTag = "choice"
	static let exercizesTag = "exercizes"
	
	override func export() -> String {
		var res = "<\(GTChoice.choiceTag)>"
		res += "<\(GTChoice.exercizesTag)>\(self.exercizeList.map { $0.export() }.reduce("") { $0 + $1 })</\(GTChoice.exercizesTag)>"
		res += "</\(GTChoice.choiceTag)>"
		
		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTChoice {
		guard xml.name == GTChoice.choiceTag,
			let ex = xml.children.first(where: { $0.name == GTChoice.exercizesTag })?.children else {
				throw GTDataImportError.failure([])
		}
		
		let ch = dataManager.newChoice()
		for e in ex {
			do {
				let o = try GTDataObject.import(fromXML: e, withDataManager: dataManager)
				guard let exercize = o as? GTSimpleSetsExercize else {
					throw GTDataImportError.failure(ch.subtreeNodes.union([o]))
				}
				
				ch.add(parts: exercize)
			} catch GTDataImportError.failure(let obj) {
				throw GTDataImportError.failure(ch.subtreeNodes.union(obj))
			}
		}
		
		if ch.isSubtreeValid {
			return ch
		} else {
			throw GTDataImportError.failure(ch.subtreeNodes)
		}
	}
}
