//
//  WorkoutExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

extension Workout {
	
	func export() -> String {
		var res = "<workout>"
		res += "<name>\(self.name.toXML())</name>"
		res += "<archived>\(self.archived)</archived>"
		res += "<exercizes>\(self.exercizeList.map { $0.export() }.reduce("") { $0 + $1 })</exercizes>"
		res += "</workout>"
		
		return res
	}
	
	static func `import`(fromXML xml: XMLNode) -> Workout? {
		// TODO: Check that the exercize list in XML does not contain rest period at the start or end, nor two or more consecutive rest periods
		
		// TODO: Ask DataManager for a new workout
		
		// TODO: Persist data
		
		return nil
	}
	
}
