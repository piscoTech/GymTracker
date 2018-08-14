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
	
	var parts: Set<GTPart> { get }
	var partList: [GTPart] { get }
	
	func canHandle(part: GTPart.Type) -> Bool
	func add(parts: GTPart...)
	func remove(part: GTPart)
	
}

extension ExercizeCollection {
	
	subscript (n: Int32) -> GTPart? {
		return parts.first { $0.order == n }
	}
	
	/// Move the step at the specified index to `to` index, the old exercize at `to` index will have index `dest+1` if the exercize is being moved towards the start of the workout, `dest-1` otherwise.
	func moveStepAt(number from: Int32, to dest: Int32) {
		guard let e = self[from], dest < parts.count else {
			return
		}
		
		let newIndex = dest > from ? dest + 1 : dest
		_ = parts.map {
			if Int($0.order) >= newIndex {
				$0.order += 1
			}
		}
		
		e.order = newIndex
		recalculatePartsOrder()
	}
	
	func recalculatePartsOrder() {
		var i: Int32 = 0
		for s in partList {
			s.order = i
			i += 1
		}
	}
	
}
