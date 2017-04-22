//
//  RepsSetExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

extension RepsSet {
	
	func export() -> String {
		var res = "<set>"
		res += "<reps>\(self.reps)</reps>"
		res += "<weight>\(self.weight)</weight>"
		res += "<rest>\(Int(self.rest))</rest>"
		res += "</set>"
		
		return res
	}
	
}
