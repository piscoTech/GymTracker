//
//  GTExercise.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTExercise)
public class GTExercise: GTPart {
	
	public var title: String {
		fatalError("Abstract property not implemented")
	}
	
	public var summary: String {
		fatalError("Abstract property not implemented")
	}
	
	public func summaryWithSecondaryInfoChange(from ctrl: ExecuteWorkoutController) -> NSAttributedString {
		return NSAttributedString(string: summary)
	}
	
}
