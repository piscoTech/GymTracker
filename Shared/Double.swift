//
//  Double.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 17/12/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

extension Double {
	
	func weightDescription(withChange change: Double) -> NSAttributedString? {
		let weight = self + change
		guard weight > 0 else {
			return nil
		}
		
		let res = NSMutableAttributedString(string: weight.toString())
		if change != 0 {
			res.addAttribute(.foregroundColor, value: change > 0 ? greenTint : redTint, range: NSRange(location: 0, length: res.length))
		}
		
		return res
	}
	
}
