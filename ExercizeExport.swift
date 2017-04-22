//
//  ExercizeExport.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 22/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

extension Exercize {
	
	func export() -> String {
		if isRest {
			return "<rest>\(Int(rest))</rest>"
		} else {
			var res = "<exercize>"
			res += "<name>\(self.name?.toXML() ?? "")</name>"
			res += "<sets>\(self.setList.map { $0.export() }.reduce("") { $0 + $1 })</sets>"
			res += "</exercize>"
			
			return res
		}
	}
	
}
