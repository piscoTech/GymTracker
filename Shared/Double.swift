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
		guard self > 0 || change > 0 else {
			return nil
		}
		
		return self.weightDescriptionEvenForZero(withChange: change)
	}
	
	func weightDescriptionEvenForZero(withChange change: Double) -> NSAttributedString {
		let w = max(0, self)
		let res = NSMutableAttributedString(string: w.toString())
		let actCh = change > 0 ? change : max(change, -w)
		if actCh != 0 {
			let ch = NSMutableAttributedString(string: "\(actCh > 0 ? plusSign : minusSign)\(abs(actCh).toString())")
			ch.addAttribute(.foregroundColor, value: actCh > 0 ? greenTint : redTint, range: NSRange(location: 0, length: ch.length))
			res.append(ch)
		}
		
		return res
	}
	
}
