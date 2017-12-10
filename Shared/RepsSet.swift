//
//  RepsSet.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData
import MBLibrary

@objc(RepsSet)
public class RepsSet: DataObject {
	
	override class var objectType: String {
		return "RepsSet"
	}
	
	//ID and last modified date are properties of DataObject
	
	@NSManaged var exercize: Exercize
	@NSManaged var order: Int32
	
	@NSManaged private(set) var reps: Int32
	@NSManaged private(set) var weight: Double
	@NSManaged private(set) var rest: TimeInterval
	
	private let exercizeKey = "exercize"
	private let orderKey = "order"
	private let repsKey = "reps"
	private let weightKey = "weight"
	private let restKey = "rest"
	
	override public var description: String {
		return "\(reps)" + (weight > 0 ? "\(timesSign)\(weight.toString())kg" : "")
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> RepsSet? {
		let req = NSFetchRequest<RepsSet>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
	var isValid: Bool {
		return reps > 0 && weight >= 0 && rest >= 0
	}
	
	func set(reps n: Int32) {
		reps = max(n, 0)
	}
	
	func set(weight w: Double) {
		weight = max(w, 0).rounded(to: 0.5)
	}
	
	func set(rest r: TimeInterval) {
		rest = max(r, 0).rounded(to: 30)
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[exercizeKey] = exercize.recordID.wcRepresentation
		obj[orderKey] = order
		obj[repsKey] = reps
		obj[weightKey] = weight
		obj[restKey] = rest
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let eData = src[exercizeKey] as? [String], let exercize = CDRecordID(wcRepresentation: eData)?.getObject(fromDataManager: dataManager) as? Exercize else {
			return false
		}
		
		guard let order = src[orderKey] as? Int32,
			let reps = src[repsKey] as? Int32,
			let weight = src[weightKey] as? Double,
			let rest = src[restKey] as? TimeInterval else {
				return false
		}
		
		self.exercize = exercize
		self.order = order
		self.reps = reps
		self.weight = weight
		self.rest = rest
		
		return true
	}
	
}
