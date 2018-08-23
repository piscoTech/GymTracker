//
//  WorkoutLevel.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation

public protocol WorkoutLevel {
	
	var parentLevel: CompositeWorkoutLevel? { get }
	
}

extension WorkoutLevel {
	
	var parentHierarchy: [CompositeWorkoutLevel] {
		var res: [CompositeWorkoutLevel] = []
		var top = self.parentLevel
		while let t = top {
			res.append(t)
			top = t.parentLevel
		}
		
		return res
	}
	
}

public protocol CompositeWorkoutLevel: WorkoutLevel {}

public protocol ExercizeCollection: CompositeWorkoutLevel {
	
	associatedtype Exercize: GTPart
	
	var collectionType: String { get }
	
	var exercizes: Set<Exercize> { get }
	var exercizeList: [Exercize] { get }
	
	func add(parts: Exercize...)
	func remove(part: Exercize)
	
}

extension ExercizeCollection {
	
	public subscript (n: Int32) -> Exercize? {
		return exercizes.first { $0.order == n }
	}
	
	/// Move the part at the specified index to `to` index, the old exercize at `to` index will have index `dest+1` if the part is being moved towards the start of the collection, `dest-1` otherwise.
	public func movePart(at from: Int32, to dest: Int32) {
		guard let e = self[from], dest < exercizes.count else {
			return
		}
		
		let newIndex = dest > from ? dest + 1 : dest
		_ = exercizes.map {
			if Int($0.order) >= newIndex {
				$0.order += 1
			}
		}
		
		e.order = newIndex
		recalculatePartsOrder()
	}
	
	func recalculatePartsOrder() {
		var i: Int32 = 0
		for s in exercizeList {
			s.order = i
			i += 1
		}
	}
	
}

public protocol NamedExercizeCollection: ExercizeCollection {
	
	var name: String { get }
	func set(name: String)
	
}
