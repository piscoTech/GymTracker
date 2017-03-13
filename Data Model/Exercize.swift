//
//  Exercize.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(Exercize)
class Exercize: DataObject {
	
	override class var objectType: String {
		get {
			return "Exercize"
		}
	}
	
	//ID and last modified date are properties of DataObject
	
	@NSManaged var workout: Workout
	@NSManaged var order: Int32
	@NSManaged var isRest: Bool
	
	@NSManaged var name: String?
	@NSManaged var rest: TimeInterval
	
	@NSManaged var sets: Set<RepsSet>
	
	override var description: String {
		return "N \(order): \(name) - \(sets.count) set(s) - \(setsSummary)"
	}
	
	override class func loadWithID(_ id: String) -> Exercize? {
		let req = NSFetchRequest<Exercize>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
	var hasInvalidSets: Bool {
		// TODO: check if all sets have reps count
		
		return false
	}
	
	var setList: [RepsSet] {
		return Array(sets).sorted { $0.order < $1.order }
	}
	
	func set(n: Int32) -> RepsSet? {
		return sets.first { $0.order == n }
	}
	
	var setsSummary: String {
		return "I'm lazy now"
	}
	
	///Checks all sets and remove invalid ones.
	///- returns: A collection of removed sets.
	func compactSets() -> [RepsSet] {
		// TODO: Implement me
		return []
	}
	
}
