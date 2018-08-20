//
//  GTCircuit.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTCircuit)
final public class GTCircuit: GTExercize, ExercizeCollection {
	
	override class var objectType: String {
		return "GTCircuit"
	}
	
	public let collectionType = GTLocalizedString("CIRCUIT", comment: "Circuit")
	
	@NSManaged public private(set) var exercizes: Set<GTSetsExercize>
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTCircuit? {
		let req = NSFetchRequest<GTCircuit>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override public var isValid: Bool {
		return workout != nil && isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		return exercizes.count > 1 && exercizes.reduce(true) { $0 && $1.isValid } && exercizesError.isEmpty
	}
	
	override public var parentLevel: CompositeWorkoutLevel? {
		return workout
	}
	
	override public var subtreeNodeList: Set<GTDataObject> {
		return Set(exercizes.flatMap { $0.subtreeNodeList } + [self])
	}
	
	override public func purgeInvalidSettings() {
		for e in exercizes {
			e.purgeInvalidSettings()
		}
	}
	
	/// Whether or not the exercizes of this circuit are valid inside of it.
	///
	/// An exercize has its index in `exercizeList` included if it has not the same number of sets as the most frequent sets count in the circuit.
	var exercizesError: [Int] {
		return GTCircuit.invalidIndices(for: exercizeList.map { $0.setsCount })
	}
	
	class func invalidIndices(for setsCount: [Int?]) -> [Int] {
		let mode = setsCount.mode
		return zip(setsCount, 0 ..< setsCount.count).filter { $0.0 == nil || $0.0 != mode }.map { $0.1 }
	}
	
	// MARK: - Exercizes handling
	
	public var exercizeList: [GTSetsExercize] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}
	
	public func add(parts: GTSetsExercize...) {
		for se in parts {
			se.order = Int32(self.exercizes.count)
			se.set(circuit: self)
		}
	}
	
	public func remove(part se: GTSetsExercize) {
		exercizes.remove(se)
		recalculatePartsOrder()
	}
	
}
