//
//  WorkoutLevel.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation

protocol WorkoutLevel {
	
	var parentCollection: ExercizeCollection? { get }
	
}

extension WorkoutLevel {
	
	var parentHierarchy: [ExercizeCollection] {
		var res: [ExercizeCollection] = []
		var top = self.parentCollection
		while let t = top {
			res.append(t)
			top = t.parentCollection
		}
		
		return res
	}
	
}

protocol ExercizeCollection: WorkoutLevel {
	
	subscript (n: Int32) -> GTPart? { get }
	func part(after part: GTPart) -> GTPart?
	func part(before part: GTPart) -> GTPart?
	
}
