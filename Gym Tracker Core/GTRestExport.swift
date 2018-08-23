//
//  GTRestExport.swift
//  Gym Tracker Core iOS
//
//  Created by Marco Boschi on 17/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension GTRest {
	
	static let restTag = "rest"
	
	override func export() -> String {
		return "<\(GTRest.restTag)>\(Int(rest))</\(GTRest.restTag)>"
	}
	
	override class func `import`(fromXML xml: XMLNode, withDataManager dataManager: DataManager) throws -> GTRest {
		guard xml.name == GTRest.restTag,
			let restData = xml.content, let restTime = TimeInterval(restData) else {
			throw GTError.importFailure([])
		}
			
		let r = dataManager.newRest()
		r.set(rest: restTime)
			
		if r.isSubtreeValid {
			return r
		} else {
			throw GTError.importFailure(r.subtreeNodes)
		}
	}
}
