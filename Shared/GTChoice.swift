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
	var parts: Set<GTPart> {
		return exercizes
	}

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
	var partList: [GTPart] {
		return exercizeList
	}
	
	subscript (n: Int32) -> GTPart? {
		return exercizes.first { $0.order == n }
	}
	
	func part(after part: GTPart) -> GTPart? {
		let list = exercizeList
		guard let ex = part as? GTSimpleSetsExercize, let i = list.index(of: ex), i < list.endIndex else {
			return nil
		}
		
		return list.suffix(from: list.index(after: i)).first
	}
	
	func part(before part: GTPart) -> GTPart? {
		let list = exercizeList
		guard let ex = part as? GTSimpleSetsExercize, let i = list.index(of: ex) else {
			return nil
		}
		
		return list.prefix(upTo: i).last
	}

	#warning("Add exercize to end of choice")
	
	func removeExercize(_ e: GTSimpleSetsExercize) {
		exercizes.remove(e)
		recalculatePartsOrder()
	}
	
	// MARK: - iOS/watchOS interface
	
	#error("Add attribute to save the last chosen exercize")

}
