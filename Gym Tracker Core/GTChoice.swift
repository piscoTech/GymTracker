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
final public class GTChoice: GTSetsExercize, ExercizeCollection {
	
	override class var objectType: String {
		return "GTChoice"
	}
	
	public let collectionType = GTLocalizedString("CHOICE", comment: "Choice")
	
	private let lastChosenKey = "lastChosen"
	
	/// The index of the last chosen exercize.
	///
	/// A negative value represent no choice, a value grater than the last index is equivalent to `0`.
	@NSManaged public var lastChosen: Int32
	@NSManaged public private(set) var exercizes: Set<GTSimpleSetsExercize>

	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTChoice? {
		let req = NSFetchRequest<GTChoice>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	public override var title: String {
		return collectionType
	}
	
	public override var summary: String {
		return exercizeList.lazy.map { $0.title }.joined(separator: ", ")
	}
	
	override public var isValid: Bool {
		return [workout, circuit].compactMap { $0 }.count == 1 && isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		return exercizes.count > 1 && exercizes.reduce(true) { $0 && $1.isValid } && inCircuitExercizesError?.isEmpty ?? true
	}
	
	public override var isPurgeableToValid: Bool {
		return false
	}
	
	public override var shouldBePurged: Bool {
		return exercizes.isEmpty
	}
	
	override public var parentLevel: CompositeWorkoutLevel? {
		return [workout, circuit].compactMap { $0 }.first
	}
	
	public override var allowCircuitRest: Bool {
		return false
	}
	
	override var setsCount: Int? {
		let counts = exercizes.compactMap { $0.setsCount }.removingDuplicates()
		return counts.count > 1 ? nil : counts.first
	}
	
	override public var subtreeNodes: Set<GTDataObject> {
		return Set(exercizes.flatMap { $0.subtreeNodes } + [self])
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		return exercizes.reduce(super.purge(onlySettings: onlySettings)) { $0 + $1.purge(onlySettings: onlySettings) }
	}
	
	/// Whether or not the exercizes of this choice are valid inside the parent circuit or `nil` if none.
	///
	/// An exercize has its index in `exercizeList` included if it has not the same number of sets as the most frequent sets count in the circuit.
	public var inCircuitExercizesError: [Int]? {
		guard isInCircuit, let c = circuit else {
			return nil
		}
		
		return GTCircuit.invalidIndices(for: exercizeList.map { $0.setsCount }, mode: c.exercizes.count > 1 ? c.exercizes.lazy.map { $0.setsCount }.mode : nil)
	}
	
	// MARK: - Exercizes handling
	
	public var exercizeList: [GTSimpleSetsExercize] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}
	
	public func add(parts: GTSimpleSetsExercize...) {
		for e in parts {
			e.order = Int32(self.exercizes.count)
			e.set(choice: self)
		}
	}
	
	public func remove(part e: GTSimpleSetsExercize) {
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
