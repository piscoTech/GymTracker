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

public protocol CompositeWorkoutLevel: WorkoutLevel {
	
	var childrenList: [GTPart] { get }
	
}

public protocol ExerciseCollection: CompositeWorkoutLevel {
	
	associatedtype Exercise: GTPart
	
	static var collectionType: String { get }
	
	var exercises: Set<Exercise> { get }
	var exerciseList: [Exercise] { get }
	
	func add(parts: Exercise...)
	func remove(part: Exercise)
	
}

extension ExerciseCollection {
	
	public var childrenList: [GTPart] {
		return exerciseList
	}
	
	public subscript (n: Int32) -> Exercise? {
		return exercises.first { $0.order == n }
	}
	
	/// Move the part at the specified index to `to` index, the old exercise at `to` index will have index `dest+1` if the part is being moved towards the start of the collection, `dest-1` otherwise.
	public func movePart(at from: Int32, to dest: Int32) {
		guard let e = self[from], dest < exercises.count else {
			return
		}
		
		let newIndex = dest > from ? dest + 1 : dest
		_ = exercises.map {
			if Int($0.order) >= newIndex {
				$0.order += 1
			}
		}
		
		e.order = newIndex
		recalculatePartsOrder()
	}
	
	func recalculatePartsOrder() {
		var i: Int32 = 0
		for s in exerciseList {
			s.order = i
			i += 1
		}
	}
	
}

public protocol NamedExerciseCollection: ExerciseCollection {
	
	var name: String { get }
	func set(name: String)
	
}
