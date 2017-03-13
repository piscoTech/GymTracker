//
//  RepsSet.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(RepsSet)
class RepsSet: DataObject {
	
	override class var objectType: String {
		get {
			return "RepsSet"
		}
	}
	
	//ID and last modified date are properties of DataObject
	
	@NSManaged var exerize: Exercize
	@NSManaged var order: Int32
	
	@NSManaged var reps: Int32
	@NSManaged var weight: Double
	@NSManaged var rest: TimeInterval
	
	override var description: String {
		return "I'm lazy now"
	}
	
	override class func loadWithID(_ id: String) -> RepsSet? {
		let req = NSFetchRequest<RepsSet>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
}
