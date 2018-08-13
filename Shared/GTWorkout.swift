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
	
	@NSManaged private(set) var name: String
	@NSManaged private(set) var parts: Set<GTPart>
	
	@NSManaged var archived: Bool
	
	private let nameKey = "name"
	private let archivedKey = "archived"
	
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
		return name.count > 0 && hasExercizes
	}
	
	var hasExercizes: Bool {
		return parts.first { $0 is GTExercize } != nil
	}
	
	var parentCollection: ExercizeCollection? {
		return nil
	}
	
	// MARK: - Parts handling
	
	var partList: [GTPart] {
		return Array(parts).sorted { $0.order < $1.order }
	}
	
	subscript (n: Int32) -> GTPart? {
		return parts.first { $0.order == n }
	}
	
	func part(after part: GTPart) -> GTPart? {
		let list = partList
		guard let i = list.index(of: part), i < list.endIndex else {
			return nil
		}
		
		return list.suffix(from: list.index(after: i)).first
	}
	
	func part(before part: GTPart) -> GTPart? {
		let list = partList
		guard let i = list.index(of: part) else {
			return nil
		}
		
		return list.prefix(upTo: i).last
	}
	
	func removePart(_ p: GTPart) {
		parts.remove(p)
		recalculateStepOrder()
	}
	
	func set(name: String) {
		self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
	}
	
	/// Move the step at the specified index to `to` index, the old exercize at `to` index will have index `dest+1` if the exercize is being moved towards the start of the workout, `dest-1` otherwise.
	func moveStepAt(number from: Int, to dest: Int) {
		guard let e = self[Int32(from)], dest < parts.count else {
			return
		}
		
		let newIndex = dest > from ? dest + 1 : dest
		_ = parts.map {
			if Int($0.order) >= newIndex {
				$0.order += 1
			}
		}
		
		e.order = Int32(newIndex)
		recalculateStepOrder()
	}
	
	/// Removes rest period from start and end.
	/// - returns: A collection of removed parts (rest periods) from the start, end and somewhere between exercizes.
	func compactExercizes() -> (start: [GTPart], end: [GTPart], middle: [(e: GTPart, oldOrder: Int32)]) {
		#error("Make recursive for each gtPart that is an ExercizeCollection, use a protocol method")
		var s = [GTPart]()
		var e = [GTPart]()
		var middle = [(GTPart, Int32)]()
		var steps = self.partList
		
		while let f = steps.first, f is GTRest {
			self.removePart(f)
			s.append(steps.removeFirst())
		}
		
		while let l = steps.last, l is GTRest {
			self.removePart(l)
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
				self.removePart(s)
				middle.append((s, s.order))
			} else {
				hasRest = true
			}
		}
		
		self.recalculateStepOrder()
		return (s, e, middle)
	}
	
	private func recalculateStepOrder() {
		var i: Int32 = 0
		for s in partList {
			s.order = i
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
