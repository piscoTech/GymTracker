//
//  GTRepsSet.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData
import MBLibrary

@objc(GTRepsSet)
final class GTRepsSet: GTSet {
	
	override class var objectType: String {
		return "GTRepsSet"
	}
	
	private let repsKey = "reps"
	private let weightKey = "weight"
	
	@NSManaged private(set) var reps: Int32
	@NSManaged private(set) var weight: Double
	
	override var description: String {
		return "\(reps)x\(weight.toString())kg"
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTRepsSet? {
		let req = NSFetchRequest<GTRepsSet>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override var isValid: Bool {
		return super.isValid && reps > 0 && weight >= 0
	}
	
	func set(reps n: Int32) {
		reps = max(n, 0)
	}
	
	func set(weight w: Double) {
		weight = max(w, 0).rounded(to: 0.5)
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[repsKey] = reps
		obj[weightKey] = weight
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let reps = src[repsKey] as? Int32,
			let weight = src[weightKey] as? Double else {
				return false
		}
		
		self.reps = reps
		self.weight = weight
		
		return true
	}
	
}
