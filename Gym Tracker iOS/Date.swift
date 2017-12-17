//
//  Date.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 26/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation

extension Date {
	
	private static let workoutF: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyyMMddHHmmss"
		
		return formatter
	}()
	
	func getWorkoutExportName() -> String {
		return Date.workoutF.string(from: self)
	}
	
}
