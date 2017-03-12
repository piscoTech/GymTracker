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
	
	//ID and last modified date are properties of DataObject
	
	@NSManaged var name: String
	@NSManaged var exercizes: Set<Exercize>
	
	@NSManaged var archived: Bool
	
	override class func loadWithID(_ id: String) -> Workout? {
		let req = NSFetchRequest<Workout>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}

}
