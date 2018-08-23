//
//  GTRepsSetExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTRepsSet {
	
	static let setTag = "set"
	static let repsTag = "reps"
	static let weightTag = "weight"
	static let restTag = "rest"
	
	override func export() -> String {
		var res = "<\(GTRepsSet.setTag)>"
		res += "<\(GTRepsSet.repsTag)>\(self.mainInfo)</\(GTRepsSet.repsTag)>"
		res += "<\(GTRepsSet.weightTag)>\(self.secondaryInfo)</\(GTRepsSet.weightTag)>"
		res += "<\(GTRepsSet.restTag)>\(Int(self.rest))</\(GTRepsSet.restTag)>"
		res += "</\(GTRepsSet.setTag)>"
		
		return res
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTRepsSet {
		guard xml.name == GTRepsSet.setTag,
			let repsData = xml.children.first(where: { $0.name == GTRepsSet.repsTag })?.content, let reps = Int(repsData),
			let weightData = xml.children.first(where: { $0.name == GTRepsSet.weightTag })?.content, let weight = Double(weightData),
			let restData = xml.children.first(where: { $0.name == GTRepsSet.restTag })?.content, let rest = TimeInterval(restData) else {
			throw GTError.importFailure([])
		}
		
		let s = dataManager.newSet()
		s.set(rest: rest)
		s.set(mainInfo: reps)
		s.set(secondaryInfo: weight)
		
		if s.isSubtreeValid {
			return s
		} else {
			throw GTError.importFailure(s.subtreeNodes)
		}
	}
	
}
