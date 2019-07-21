//
//  GTWorkout.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(GTWorkout)
final public class GTWorkout: GTDataObject, NamedExerciseCollection {
	
	override class var objectType: String {
		return "GTWorkout"
	}
	
	public static let collectionType = GTLocalizedString("WORKOUT", comment: "Workout")
	
	public class func getList(fromDataManager dataManager: DataManager) -> [GTWorkout] {
		let workoutQuery = NSFetchRequest<GTWorkout>(entityName: self.objectType)
		var list = dataManager.executeFetchRequest(workoutQuery) ?? []
		list.sort { $0.name < $1.name }
		
		return list
	}
	
	static private let nameKey = "name"
	static private let archivedKey = "archived"
	
	@NSManaged public private(set) var name: String
	@NSManaged private(set) var parts: Set<GTPart>
	public var exercises: Set<GTPart> {
		return parts
	}
	
	@NSManaged public var archived: Bool
	
	static private let descriptionTemplate = GTLocalizedString("%lld_EXERCISES", comment: "exercise(s)")
	public override var description: String {
		let n = parts.reduce(0) { partial, current in
			let count: Int
			if let c = current as? GTCircuit {
				
				count = c.exercises.count
			} else if current is GTSetsExercise {
				count = 1
			} else {
				count = 0
			}
			
			return partial + count
		}
		
		return String(format: Self.descriptionTemplate, n)
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTWorkout? {
		let req = NSFetchRequest<GTWorkout>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override public var isValid: Bool {
		return isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		guard isPurgeableToValid else {
			return false
		}
		
		return exerciseList.split(omittingEmptySubsequences: false) { $0 is GTRest }.first { $0.isEmpty } == nil
	}
	
	public override var isPurgeableToValid: Bool {
		return name.count > 0 && parts.first { $0 is GTExercise } != nil && parts.reduce(true, { $0 && $1.isValid })
	}
	
	public let parentLevel: CompositeWorkoutLevel? = nil
	
	override public var subtreeNodes: Set<GTDataObject> {
		return Set(parts.flatMap { $0.subtreeNodes } + [self])
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		var res = [GTDataObject]()
	
		if !onlySettings {
			var steps = self.exerciseList
			
			while let f = steps.first, f is GTRest {
				self.remove(part: f)
				res.append(steps.removeFirst())
			}
			
			while let l = steps.last, l is GTRest {
				self.remove(part: l)
				res.append(steps.popLast()!)
			}
			
			var hasRest = false
			while let s = steps.first {
				steps.remove(at: 0)
				
				guard s is GTRest else {
					hasRest = false
					continue
				}
				
				if hasRest {
					self.remove(part: s)
					res.append(s)
				} else {
					hasRest = true
				}
			}
			
			recalculatePartsOrder()
		}
		
		return parts.reduce(res) { $0 + $1.purge(onlySettings: onlySettings) }
	}
	
	var choices: [GTChoice] {
		return exerciseList.flatMap { ($0 as? GTCircuit)?.exerciseList.compactMap { $0 as? GTChoice } ?? [$0 as? GTChoice].compactMap { $0 } }
	}

	public override var shouldBePurged: Bool {
		return false
	}
	
	public override func removePurgeable() -> [GTDataObject] {
		var res = [GTDataObject]()
		for p in parts {
			if p.shouldBePurged {
				res.append(p)
				self.remove(part: p)
			} else {
				res.append(contentsOf: p.removePurgeable())
			}
		}
		
		recalculatePartsOrder()
		return res
	}
	
	// MARK: - Parts handling
	
	public var exerciseList: [GTPart] {
		return Array(exercises).sorted { $0.order < $1.order }
	}
	
	public func add(parts: GTPart...) {
		for p in parts {
			p.order = Int32(self.parts.count)
			p.set(workout: self)
		}
	}
	
	public func remove(part p: GTPart) {
		parts.remove(p)
		recalculatePartsOrder()
	}
	
	public func set(name: String) {
		self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
	
		obj[Self.nameKey] = name
		obj[Self.archivedKey] = archived
		
		// Steps themselves contain a reference to the workout
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let name = src[Self.nameKey] as? String, name.count > 0, let archived = src[Self.archivedKey] as? Bool else {
			return false
		}
		
		self.name = name
		self.archived = archived
		
		return true
	}

}
