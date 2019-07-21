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
final public class GTChoice: GTSetsExercise, ExerciseCollection {
	
	override class var objectType: String {
		return "GTChoice"
	}
	
	public static let collectionType = GTLocalizedString("CHOICE", comment: "Choice")
	
	static private let lastChosenKey = "lastChosen"
	
	/// The index of the last chosen exercise.
	///
	/// A negative value represent no choice, a value grater than the last index is equivalent to `0`.
	@NSManaged public var lastChosen: Int32
	@NSManaged public private(set) var exercises: Set<GTSimpleSetsExercise>

	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTChoice? {
		let req = NSFetchRequest<GTChoice>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	public override var title: String {
		return Self.collectionType
	}
	
	public override var summary: String {
		return exerciseList.lazy.map { $0.title }.joined(separator: ", ")
	}
	
	override public var isValid: Bool {
		return [workout, circuit].compactMap { $0 }.count == 1 && isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		return exercises.count > 1 && exercises.reduce(true) { $0 && $1.isValid } && inCircuitExercisesError?.isEmpty ?? true
	}
	
	public override var isPurgeableToValid: Bool {
		return false
	}
	
	public override var shouldBePurged: Bool {
		return exercises.isEmpty
	}
	
	override public var parentLevel: CompositeWorkoutLevel? {
		return [workout, circuit].compactMap { $0 }.first
	}
	
	public override var allowCircuitRest: Bool {
		return false
	}
	
	override var setsCount: Int? {
		let counts = exercises.compactMap { $0.setsCount }.removingDuplicates()
		return counts.count > 1 ? nil : counts.first
	}
	
	override public var subtreeNodes: Set<GTDataObject> {
		return Set(exercises.flatMap { $0.subtreeNodes } + [self])
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		return exercises.reduce(super.purge(onlySettings: onlySettings)) { $0 + $1.purge(onlySettings: onlySettings) }
	}

	public override func removePurgeable() -> [GTDataObject] {
		var res = [GTDataObject]()
		for e in exercises {
			if e.shouldBePurged {
				res.append(e)
				self.remove(part: e)
			} else {
				res.append(contentsOf: e.removePurgeable())
			}
		}
		
		recalculatePartsOrder()
		return res
	}
	
	/// Whether or not the exercises of this choice are valid inside the parent circuit or `nil` if none.
	///
	/// An exercise has its index in `exerciseList` included if it has not the same number of sets as the most frequent sets count in the circuit.
	public var inCircuitExercisesError: [Int]? {
		guard isInCircuit, let c = circuit else {
			return nil
		}
		
		return GTCircuit.invalidIndices(for: exerciseList.map { $0.setsCount }, mode: c.exercises.count > 1 ? c.exercises.lazy.map { $0.setsCount }.mode : nil)
	}
	
	// MARK: - Exercises handling
	
	public var exerciseList: [GTSimpleSetsExercise] {
		return Array(exercises).sorted { $0.order < $1.order }
	}
	
	public func add(parts: GTSimpleSetsExercise...) {
		for e in parts {
			e.order = Int32(self.exercises.count)
			e.set(choice: self)
		}
	}
	
	public func remove(part e: GTSimpleSetsExercise) {
		exercises.remove(e)
		recalculatePartsOrder()
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[Self.lastChosenKey] = lastChosen
		
		// Exercises themselves contain a reference to the choice
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let lastChosen = src[Self.lastChosenKey] as? Int32 else {
			return false
		}
		
		self.lastChosen = lastChosen
		
		return true
	}

}
