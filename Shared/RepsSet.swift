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
class RepsSet: DataObject {
	
	override class var objectType: String {
		get {
			return "RepsSet"
		}
	}
	
	//ID and last modified date are properties of DataObject
	
	@NSManaged var exercize: Exercize
	@NSManaged var order: Int32
	
	@NSManaged private(set) var reps: Int32
	@NSManaged private(set) var weight: Double
	@NSManaged private(set) var rest: TimeInterval
	
	override var description: String {
		return "\(reps)" + (weight > 0 ? "\(timesSign)\(weight.toString())kg" : "")
	}
	
	override class func loadWithID(_ id: String) -> RepsSet? {
		let req = NSFetchRequest<RepsSet>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
	var isValid: Bool {
		return reps > 0
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
	
}
