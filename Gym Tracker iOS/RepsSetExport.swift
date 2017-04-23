//
//  RepsSetExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension RepsSet {
	
	func export() -> String {
		var res = "<\(importExportManager.setTag)>"
		res += "<\(importExportManager.setRepsTag)>\(self.reps)</\(importExportManager.setRepsTag)>"
		res += "<\(importExportManager.setWeightTag)>\(self.weight)</\(importExportManager.setWeightTag)>"
		res += "<\(importExportManager.setRestTag)>\(Int(self.rest))</\(importExportManager.setRestTag)>"
		res += "</\(importExportManager.setTag)>"
		
		return res
	}
	
	///Read XML data and create the corresponding `RepsSet`, this method assumes that data is valid according to `workout.xsd`.
	///- returns: Whether the import was success or not, in case of failure the returned `RepsSet`, if any, must be deleted.
	static func `import`(fromXML xml: XMLNode, for e: Exercize) -> (set: RepsSet?, success: Bool) {
		guard !e.isRest else {
			return (nil, false)
		}
		
		guard let repsData = xml.children.first(where: { $0.name == importExportManager.setRepsTag })?.content, let reps = Int32(repsData),
			let weightData = xml.children.first(where: { $0.name == importExportManager.setWeightTag })?.content, let weight = Double(weightData),
			let restData = xml.children.first(where: { $0.name == importExportManager.setRestTag })?.content, let rest = TimeInterval(restData) else {
			return (nil, false)
		}
		
		let s = dataManager.newSet(for: e)
		s.set(rest: rest)
		s.set(reps: reps)
		s.set(weight: weight)
		
		return (s, s.isValid)
	}
	
}
