//
//  GTRepsSet.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import CoreData

@objc(GTRepsSet)
final public class GTRepsSet: GTSet {
	
	override class var objectType: String {
		return "GTRepsSet"
	}
	
	private let repsKey = "reps"
	private let weightKey = "weight"
	
	@NSManaged private var reps: Int32
	@NSManaged private var weight: Double
	
	override public var description: String {
		return "\(reps)\(timesSign)\(weight.toString())\(GTRepsSet.kgLabel.string)"
	}
	
	public override func descriptionWithSecondaryInfoChange(from ctrl: ExecuteWorkoutController) -> NSAttributedString {
		let ch = ctrl.secondaryInfoChange(for: self)
		let res = NSMutableAttributedString(string: "\(reps)\(timesSign)")
		res.append(weight.secondaryInfoDescriptionEvenForZero(withChange: ch))
		res.append(GTRepsSet.kgLabel)
		
		return res
	}
	
	override class func loadWithID(_ id: String, fromDataManager dataManager: DataManager) -> GTRepsSet? {
		let req = NSFetchRequest<GTRepsSet>(entityName: self.objectType)
		let pred = NSPredicate(format: "id == %@", id)
		req.predicate = pred
		
		return dataManager.executeFetchRequest(req)?.first
	}
	
	override public var isValid: Bool {
		return super.isValid && isSubtreeValid
	}
	
	override var isSubtreeValid: Bool {
		return super.isSubtreeValid && reps > 0 && weight >= 0
	}
	
	public override var isPurgeableToValid: Bool {
		return false
	}
	
	public override func purge(onlySettings: Bool) -> [GTDataObject] {
		return []
	}
	
	public override var shouldBePurged: Bool {
		return !isValid
	}
	
	public override func removePurgeable() -> [GTDataObject] {
		return []
	}
	
	override public func set(mainInfo n: Int) {
		reps = max(Int32(n), 0)
	}
	
	override public func set(secondaryInfo w: Double) {
		weight = max(w, 0).rounded(to: 0.5)
	}
	
	override public var subtreeNodes: Set<GTDataObject> {
		return [self]
	}
	
	// MARK: - Standard accessors
	
	override public var mainInfo: Int {
		return Int(reps)
	}
	
	private static let repsLabel = NSAttributedString(string: GTLocalizedString("CUR_REPS_INFO", comment: "reps"))
	private static let timesSignLabel = NSAttributedString(string: timesSign)
	private static let kgLabel = NSAttributedString(string: "kg")
	
	override func mainInfoDescription(with change: Double) -> NSAttributedString {
		let repsDescription = NSMutableAttributedString(string: "\(reps)")
		if let w = weight.secondaryInfoDescription(withChange: change) {
			repsDescription.append(GTRepsSet.timesSignLabel)
			repsDescription.append(w)
			repsDescription.append(secondaryInfoLabel)
		}
		repsDescription.append(GTRepsSet.repsLabel)
		
		return repsDescription
	}
	
	override public var secondaryInfo: Double {
		return weight
	}
	
	override public var secondaryInfoLabel: NSAttributedString {
		return GTRepsSet.kgLabel
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[repsKey] = reps
		obj[weightKey] = weight
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let reps = src[repsKey] as? Int32,
			let weight = src[weightKey] as? Double else {
				return false
		}
		
		self.reps = reps
		self.weight = weight
		
		return true
	}
	
}
