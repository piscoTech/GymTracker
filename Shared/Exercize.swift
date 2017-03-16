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
	@NSManaged private(set) var isRest: Bool
	
	@NSManaged private(set) var name: String?
	@NSManaged private(set) var rest: TimeInterval
	
	@NSManaged private(set) var sets: Set<RepsSet>
	
	override var description: String {
		return "N \(order): \(name) - \(sets.count) set(s) - \(setsSummary)"
	}
	
	override class func loadWithID(_ id: String) -> Exercize? {
		let req = NSFetchRequest<Exercize>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
	var setList: [RepsSet] {
		return Array(sets).sorted { $0.order < $1.order }
	}
	
	func set(n: Int32) -> RepsSet? {
		return sets.first { $0.order == n }
	}
	
	var setsSummary: String {
		return setList.map { $0.description }.joined(separator: ", ")
	}
	
	///Set the name of the exercize and configure it as an exercize.
	func set(name: String?) {
		self.isRest = false
		self.name = name?.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	///Set the rest time of the exercize and configure it as rest period.
	func set(rest r: TimeInterval) {
		self.isRest = true
		self.rest = max(r, 0).rounded(to: 30)
	}
	
	///Checks all sets and remove invalid ones.
	///- returns: A collection of removed sets.
	func compactSets() -> [RepsSet] {
		return recalculateSetOrder(filterInvalid: true)
	}
	
	func removeSet(_ s: RepsSet) {
		sets.remove(s)
		recalculateSetOrder()
	}
	
	@discardableResult private func recalculateSetOrder(filterInvalid filter: Bool = false) -> [RepsSet] {
		var res = [RepsSet]()
		var i: Int32 = 0
		
		for s in setList {
			if s.isValid || !filter {
				s.order = i
				i += 1
			} else {
				res.append(s)
				sets.remove(s)
			}
		}
		
		return res
	}
	
}
