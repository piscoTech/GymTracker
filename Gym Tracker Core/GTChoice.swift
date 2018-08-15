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
	
	private let lastChosenKey = "lastChosen"
	
	/// The index of the last chosen exercize.
	///
	/// A negative value represent no choice, a value grater than the last index is equivalent to `0`.
	@NSManaged var lastChosen: Int32
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
	
	///Enables rest periods in circuits for this exercize.
	///
	///Regardless on what is passed circuit rest will always be disabled, set circuit rest in each individual exercize.
	override func enableCircuitRest(_ r: Bool) {
		super.enableCircuitRest(false)
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

	func canHandle(part: GTPart.Type) -> Bool {
		return part is GTSimpleSetsExercize.Type
	}
	
	func add(parts: GTPart...) {
		for p in parts {
			guard let e = p as? GTSimpleSetsExercize else {
				fatalError("Circuit cannot handle a \(type(of: p))")
			}
			
			e.order = Int32(self.exercizes.count)
			e.set(choice: self)
		}
	}
	
	func remove(part p: GTPart) {
		guard let e = p as? GTSimpleSetsExercize else {
			fatalError("Choice cannot handle a \(type(of: p))")
		}
		
		exercizes.remove(e)
		recalculatePartsOrder()
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[lastChosenKey] = lastChosen
		
		// Exercizes themselves contain a reference to the choice
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let lastChosen = src[lastChosenKey] as? Int32 else {
			return false
		}
		
		self.lastChosen = lastChosen
		
		return true
	}

}
