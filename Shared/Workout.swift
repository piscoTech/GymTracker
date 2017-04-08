//
//  Workout.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(Workout)
class Workout: DataObject {
	
	override class var objectType: String {
		get {
			return "Workout"
		}
	}
	
	class func getList() -> [Workout] {
		let workoutQuery = NSFetchRequest<Workout>(entityName: self.objectType)
		var list = dataManager.executeFetchRequest(workoutQuery) ?? []
		list.sort { $0.name < $1.name }
		
		return list
	}
	
	@NSManaged private(set) var name: String
	@NSManaged private(set) var exercizes: Set<Exercize>
	
	@NSManaged var archived: Bool
	
	private let nameKey = "name"
	private let archivedKey = "archived"
	
	override var description: String {
		let n = exercizes.filter { !$0.isRest }.count
		return "\(n) " + NSLocalizedString("EXERCIZE" + (n > 1 ? "S" : ""), comment: "exercize(s)").lowercased()
	}
	
	override class func loadWithID(_ id: String) -> Workout? {
		let req = NSFetchRequest<Workout>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return (dataManager.executeFetchRequest(req) ?? []).first
	}
	
	var hasExercizes: Bool {
		for e in exercizes {
			if !e.isRest {
				return true
			}
		}
		
		return false
	}
	
	var exercizeList: [Exercize] {
		return Array(exercizes).sorted { $0.order < $1.order }
	}
	
	func exercize(n: Int32) -> Exercize? {
		return exercizes.first { $0.order == n }
	}
	
	func removeExercize(_ e: Exercize) {
		exercizes.remove(e)
		recalculateExercizeOrder()
	}
	
	func set(name: String) {
		self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	func moveExercizeAt(number from: Int, to dest: Int) {
		guard let e = exercize(n: Int32(from)), dest < exercizes.count else {
			return
		}
		
		let newIndex = dest > from ? dest + 1 : dest

		for tmp in exercizes.filter({ Int($0.order) >= newIndex }) {
			tmp.order += 1
		}
		
		e.order = Int32(newIndex)
		recalculateExercizeOrder()
	}
	
	///Removes rest period from start and end.
	///- returns: A collection of removed exercizes from the start and end.
	func compactExercizes() -> (start: [Exercize], end: [Exercize], middle: [(e: Exercize, oldOrder: Int32)]) {
		var s = [Exercize]()
		var e = [Exercize]()
		var middle = [(Exercize, Int32)]()
		var exercises = self.exercizeList
		
		while let f = exercises.first, f.isRest {
			self.removeExercize(f)
			s.append(exercises.removeFirst())
		}
		
		while let l = exercises.last, l.isRest {
			self.removeExercize(l)
			e.append(exercises.popLast()!)
		}
		
		var hasRest = false
		while let ex = exercises.first {
			exercises.remove(at: 0)
			
			guard ex.isRest else {
				hasRest = false
				continue
			}
			
			if hasRest {
				self.removeExercize(ex)
				middle.append((ex, ex.order))
			} else {
				hasRest = true
			}
		}
		
		self.recalculateExercizeOrder()
		return (s, e, middle)
	}
	
	private func recalculateExercizeOrder() {
		var i: Int32 = 0
		for e in exercizeList {
			e.order = i
			i += 1
		}
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
	
		obj[nameKey] = name
		obj[archivedKey] = archived
		
		// Exercizes themselves contain a reference to the workout
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject) -> Bool {
		guard super.mergeUpdatesFrom(src) else {
			return false
		}
		
		guard let name = src[nameKey] as? String, name.length > 0, let archived = src[archivedKey] as? Bool else {
			return false
		}
		
		self.name = name
		self.archived = archived
		
		return true
	}

}
