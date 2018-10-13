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
final public class GTWorkout: GTDataObject, NamedExercizeCollection {
	
	override class var objectType: String {
		return "GTWorkout"
	}
	
	public let collectionType = GTLocalizedString("WORKOUT", comment: "Workout")
	
	public class func getList(fromDataManager dataManager: DataManager) -> [GTWorkout] {
		let workoutQuery = NSFetchRequest<GTWorkout>(entityName: self.objectType)
		var list = dataManager.executeFetchRequest(workoutQuery) ?? []
		list.sort { $0.name < $1.name }
		
		return list
	}
	
	private let nameKey = "name"
	private let archivedKey = "archived"
	
	@NSManaged public private(set) var name: String
	@NSManaged private(set) var parts: Set<GTPart>
	public var exercizes: Set<GTPart> {
		return parts
	}
	
	@NSManaged public var archived: Bool
	
	public override var description: String {
		let n = parts.reduce(0) { $0 + (($1 as? GTCircuit)?.exercizes.count ?? ($1 is GTSetsExercize ? 1 : 0)) }
		return "\(n) " + GTLocalizedString("EXERCIZE" + (n > 1 ? "S" : ""), comment: "exercize(s)").lowercased()
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
		
		return exercizeList.split(omittingEmptySubsequences: false) { $0 is GTRest }.first { $0.isEmpty } == nil
	}
	
	public override var isPurgeableToValid: Bool {
		return name.count > 0 && parts.first { $0 is GTExercize } != nil && parts.reduce(true, { $0 && $1.isValid })
	}
	
	public let parentLevel: CompositeWorkoutLevel? = nil
	
	override public var subtreeNodes: Set<GTDataObject> {
		return Set(parts.flatMap { $0.subtreeNodes } + [self])
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		var res = [GTDataObject]()
	
		if !onlySettings {
			var steps = self.exercizeList
			
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
		return exercizeList.flatMap { ($0 as? GTCircuit)?.exercizeList.compactMap { $0 as? GTChoice } ?? [$0 as? GTChoice].compactMap { $0 } }
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
	
	public var exercizeList: [GTPart] {
		return Array(exercizes).sorted { $0.order < $1.order }
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
	
		obj[nameKey] = name
		obj[archivedKey] = archived
		
		// Steps themselves contain a reference to the workout
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let name = src[nameKey] as? String, name.count > 0, let archived = src[archivedKey] as? Bool else {
			return false
		}
		
		self.name = name
		self.archived = archived
		
		return true
	}

}
