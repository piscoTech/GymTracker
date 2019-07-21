//
//  GTSimpleSetsExercise.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(GTSimpleSetsExercise)
public class GTSimpleSetsExercise: GTSetsExercise {
	
	override class var objectType: String {
		return "GTSimpleSetsExercise"
	}
	
	private let nameKey = "name"
	private let choiceKey = "choice"
	
	@NSManaged public private(set) var name: String
	@NSManaged private(set) var choice: GTChoice?
	@NSManaged public private(set) var sets: Set<GTSet>
	
	override public var description: String {
		return "N \(order): \(name) - \(sets.count) set(s) - \(summary)"
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTSimpleSetsExercise? {
		let req = NSFetchRequest<GTSimpleSetsExercise>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override func set(workout w: GTWorkout?) {
		super.set(workout: w)
		
		if w != nil {
			set(choice: nil)
		}
	}
	
	override func set(circuit c: GTCircuit?) {
		super.set(circuit: c)
		
		if c != nil {
			set(choice: nil)
		}
	}
	
	/// Make the exercise a part of the given choice.
	///
	/// Unless when passing `nil`, don't call this method directly but rather call `add(parts:_)` on the choice.
	func set(choice c: GTChoice?) {
		let old = self.choice
		
		self.choice = c
		old?.recalculatePartsOrder()
		
		if c != nil {
			set(workout: nil)
			set(circuit: nil)
		}
	}
	
	override public var isValid: Bool {
		return [workout, circuit, choice].compactMap { $0 }.count == 1 && isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		return name.count > 0 && sets.count > 0 && sets.reduce(true) { $0 && $1.isValid }
	}
	
	public override var isPurgeableToValid: Bool {
		return false
	}
	
	override public var parentLevel: CompositeWorkoutLevel? {
		return [workout, circuit, choice].compactMap { $0 }.first
	}
	
	public var setList: [GTSet] {
		return Array(sets).sorted { $0.order < $1.order }
	}
	
	public subscript (n: Int32) -> GTSet? {
		return sets.first { $0.order == n }
	}
	
	override public var title: String {
		return name
	}
	
	override public var summary: String {
		return setList.map { $0.description }.joined(separator: ", ")
	}
	
	public override func summaryWithSecondaryInfoChange(from ctrl: ExecuteWorkoutController) -> NSAttributedString {
		return setList.map { $0.descriptionWithSecondaryInfoChange(from: ctrl) }.joined(separator: ", ")
	}
	
	///Set the name of the exercise.
	public func set(name n: String) {
		self.name = n.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	override var setsCount: Int? {
		return sets.count
	}
	
	override public var subtreeNodes: Set<GTDataObject> {
		return (sets as Set<GTDataObject>).union([self])
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		return sets.reduce(super.purge(onlySettings: onlySettings) + recalculateSetOrder(filterInvalid: true)) { $0 + $1.purge(onlySettings: onlySettings) }
	}
	
	public override var shouldBePurged: Bool {
		return !isValid
	}
	
	public override func removePurgeable() -> [GTDataObject] {
		var res = [GTDataObject]()
		for s in sets {
			if s.shouldBePurged {
				res.append(s)
				sets.remove(s)
			} else {
				res.append(contentsOf: s.removePurgeable())
			}
		}
		
		recalculateSetOrder(filterInvalid: false)
		return res
	}
	
	// MARK: - Choice Support
	
	/// Whether the exercise is at some point part of a choice.
	public var isInChoice: Bool {
		return self.parentHierarchy.first { $0 is GTChoice } != nil
	}
	
	/// The position of the exercise in the choice, `nil` outside of choices.
	public var choiceStatus: (number: Int, total: Int)? {
		let hierarchy = self.parentHierarchy
		guard let cIndex = hierarchy.firstIndex(where: { $0 is GTChoice }),
			let c = hierarchy[cIndex] as? GTChoice,
			let exInChoice = cIndex > hierarchy.startIndex
				? hierarchy[hierarchy.index(before: cIndex)] as? GTPart
				: self
			else {
				return nil
		}
		
		return (Int(exInChoice.order) + 1, c.exercises.count)
	}
	
	// MARK: - Sets handling
	
	internal func add(set: GTSet) {
		set.order = Int32(sets.count)
		set.exercise = self
	}
	
	public func removeSet(_ s: GTSet) {
		sets.remove(s)
		recalculateSetOrder()
	}
	
	@discardableResult private func recalculateSetOrder(filterInvalid filter: Bool = false) -> [GTSet] {
		var res = [GTSet]()
		var i: Int32 = 0
		
		for s in setList {
			if s.isValid || !filter {
				s.order = i
				i += 1
			} else {
				res.append(s)
				sets.remove(s)
			}
		}
		
		return res
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[nameKey] = name
		if let ch = choice?.recordID.wcRepresentation {
			obj[choiceKey] = ch
		}
		
		// Sets themselves contain a reference to the exercise
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let name = src[nameKey] as? String, name.count > 0 else {
			return false
		}
		
		self.name = name
		self.choice = CDRecordID(wcRepresentation: src[choiceKey] as? [String])?.getObject(fromDataManager: dataManager) as? GTChoice
		
		return true
	}
	
}
