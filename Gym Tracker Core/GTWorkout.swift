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
final class GTWorkout: GTDataObject, ExercizeCollection {
	
	override class var objectType: String {
		return "GTWorkout"
	}
	
	class func getList(fromDataManager dataManager: DataManager) -> [GTWorkout] {
		let workoutQuery = NSFetchRequest<GTWorkout>(entityName: self.objectType)
		var list = dataManager.executeFetchRequest(workoutQuery) ?? []
		list.sort { $0.name < $1.name }
		
		return list
	}
	
	private let nameKey = "name"
	private let archivedKey = "archived"
	
	@NSManaged private(set) var name: String
	@NSManaged private(set) var parts: Set<GTPart>
	var exercizes: Set<GTPart> {
		return parts
	}
	
	@NSManaged var archived: Bool
	
	override var description: String {
		let n = parts.filter { $0 is GTExercize }.count
		return "\(n) " + NSLocalizedString("EXERCIZE" + (n > 1 ? "S" : ""), comment: "exercize(s)").lowercased()
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTWorkout? {
		let req = NSFetchRequest<GTWorkout>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override var isValid: Bool {
		return name.count > 0 && hasExercizes && parts.reduce(true) { $0 && $1.isValid }
	}
	
	var hasExercizes: Bool {
		#warning("Consider removing and incorporating in isValid")
		return parts.first { $0 is GTExercize } != nil
	}
	
	let parentLevel: CompositeWorkoutLevel? = nil
	
	override var subtreeNodeList: Set<GTDataObject> {
		return Set(parts.flatMap { $0.subtreeNodeList } + [self])
	}
	
	var choices: [GTChoice] {
		#warning("Use me to determine for which choice to ask what to do")
		return exercizeList.flatMap { ($0 as? GTCircuit)?.exercizeList.compactMap { $0 as? GTChoice } ?? [$0 as? GTChoice].compactMap { $0 } }
	}
	
	// MARK: - Parts handling
	
	var exercizeList: [GTPart] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}
	
	func add(parts: GTPart...) {
		for p in parts {
			p.order = Int32(self.parts.count)
			p.set(workout: self)
		}
	}
	
	func remove(part p: GTPart) {
		parts.remove(p)
		recalculatePartsOrder()
	}
	
	func set(name: String) {
		self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	/// Removes rest period from start and end.
	/// - returns: A collection of removed parts (rest periods) from the start, end and somewhere between exercizes.
	func compactExercizes() -> (start: [GTPart], end: [GTPart], middle: [(e: GTPart, oldOrder: Int32)]) {
		var s = [GTPart]()
		var e = [GTPart]()
		var middle = [(GTPart, Int32)]()
		var steps = self.exercizeList
		
		while let f = steps.first, f is GTRest {
			self.remove(part: f)
			s.append(steps.removeFirst())
		}
		
		while let l = steps.last, l is GTRest {
			self.remove(part: l)
			e.append(steps.popLast()!)
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
				middle.append((s, s.order))
			} else {
				hasRest = true
			}
		}
		
		recalculatePartsOrder()
		return (s, e, middle)
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
