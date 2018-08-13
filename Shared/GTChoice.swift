//
//  GTChoice.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTChoice)
final class GTChoice: GTSetsExercize, ExercizeCollection {
	
	override class var objectType: String {
		return "GTChoice"
	}
	
	@NSManaged private(set) var exercizes: Set<GTSimpleSetsExercize>

	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTChoice? {
		let req = NSFetchRequest<GTChoice>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override var isValid: Bool {
		return [workout, circuit].compactMap { $0 }.count == 1 && exercizes.count > 1 && exercizes.reduce(true) { $0 && $1.isValid }
	}
	
	override var parentCollection: ExercizeCollection? {
		return [workout, circuit].compactMap { $0 }.first
	}
	
	override var setsCount: Int? {
		let counts = exercizes.compactMap { $0.setsCount }.removingDuplicates()
		return counts.count > 1 ? nil : counts.first
	}
	
	// MARK: - Exercizes handling
	
	var exercizeList: [GTSimpleSetsExercize] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}

    #error("Exercizes accessors")
	
	// MARK: - iOS/watchOS interface
	
	#error("Override from GTDataObject")

}
