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
public class Exercize: DataObject {
	
	override class var objectType: String {
		return "Exercize"
	}
	
	//ID and last modified date are properties of DataObject
	
	@NSManaged var workout: Workout
	@NSManaged var order: Int32
	@NSManaged private(set) var isRest: Bool
	
	///Whether this exercize create a circuit with the next, can be chained.
	@NSManaged private(set) var isCircuit: Bool
	@NSManaged private(set) var hasCircuitRest: Bool
	
	@NSManaged private(set) var name: String?
	@NSManaged private(set) var rest: TimeInterval
	
	@NSManaged private(set) var sets: Set<RepsSet>
	
	private let workoutKey = "workout"
	private let orderKey = "order"
	private let isRestKey = "isRest"
	private let nameKey = "name"
	private let restKey = "rest"
	
	override public var description: String {
		return "N \(order): \(String(describing: name)) - \(sets.count) set(s) - \(setsSummary)"
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> Exercize? {
		let req = NSFetchRequest<Exercize>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
	var isValid: Bool {
		return isRest || name?.length ?? 0 > 0 && sets.count > 0 && sets.reduce(true) { $0 && $1.isValid }
	}
	
	var setList: [RepsSet] {
		return Array(sets).sorted { $0.order < $1.order }
	}
	
	subscript (n: Int32) -> RepsSet? {
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
		self.isCircuit = false
		self.hasCircuitRest = false
		self.rest = max(r, 30).rounded(to: 30)
	}
	
	var previous: Exercize? {
		return workout[order - 1]
	}
	
	var next: Exercize? {
		return workout[order + 1]
	}
	
	///Make this exercize part of a circuit with the next one.
	///
	/// - Important: Don't call this function directly, use `OrganizedWorkout` instead.
	func makeCircuit(_ isCircuit: Bool) {
		guard !self.isRest else {
			return
		}
		
		self.isCircuit = isCircuit
	}
	
	///Enables rest periods in circuits for this exercize.
	///
	/// - Important: Don't call this function directly, use `OrganizedWorkout` instead.
	func enableCircuitRest(_ hasCircuitRest: Bool) {
		guard !self.isRest else {
			return
		}
		
		self.hasCircuitRest = hasCircuitRest
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
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[workoutKey] = workout.recordID.wcRepresentation
		obj[orderKey] = order
		obj[isRestKey] = isRest
		obj[nameKey] = name ?? ""
		obj[restKey] = rest
		
		// Sets themselves contain a reference to the exercize
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let wData = src[workoutKey] as? [String], let workout = CDRecordID(wcRepresentation: wData)?.getObject(fromDataManager: dataManager) as? Workout else {
			return false
		}
		
		guard let order = src[orderKey] as? Int32,
			let isRest = src[isRestKey] as? Bool,
			let name = src[nameKey] as? String, (isRest || name.length > 0),
			let rest = src[restKey] as? TimeInterval else {
			return false
		}
		
		self.workout = workout
		self.order = order
		self.isRest = isRest
		self.name = name
		self.rest = rest
		
		return true
	}
	
}
