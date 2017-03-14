//
//  Workout.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(Workout)
class Workout: DataObject {
	
	override class var objectType: String {
		get {
			return "Workout"
		}
	}
	
	class func getList() -> [Workout] {
		let workoutQuery = NSFetchRequest<Workout>(entityName: self.objectType)
		var list = dataManager.executeFetchRequest(workoutQuery) ?? []
		list.sort { $0.name < $1.name }
		
		return list
	}
	
	@NSManaged var name: String
	@NSManaged var exercizes: Set<Exercize>
	
	@NSManaged var archived: Bool
	
	override var description: String {
		return "\(name) - \(exercizes.count) exercize(s) - \(exercizes)"
	}
	
	override class func loadWithID(_ id: String) -> Workout? {
		let req = NSFetchRequest<Workout>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
	var hasExercizes: Bool {
		for e in exercizes {
			if !e.isRest {
				return true
			}
		}
		
		return false
	}
	
	var exercizeList: [Exercize] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}
	
	func exercize(n: Int32) -> Exercize? {
		return exercizes.first { $0.order == n }
	}
	
	func removeExercize(_ e: Exercize) {
		exercizes.remove(e)
		recalculateExercizeOrder()
	}
	
	private func recalculateExercizeOrder() {
		var i: Int32 = 0
		for e in exercizeList {
			e.order = i
			i += 1
		}
	}

}
