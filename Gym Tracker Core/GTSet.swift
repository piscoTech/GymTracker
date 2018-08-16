//
//  GTSet+CoreDataProperties.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTSet)
class GTSet: GTDataObject {
	
	private let minRest: TimeInterval = 0
	
	final private let exercizeKey = "exercize"
	final private let orderKey = "order"
	final private let restKey = "rest"
	
    @NSManaged final var exercize: GTSimpleSetsExercize
	@NSManaged final var order: Int32
	
	@NSManaged final private(set) var rest: TimeInterval

	override var isValid: Bool {
		return rest >= 0
	}
	
	func set(rest r: TimeInterval) {
		rest = max(r, minRest).rounded(to: GTRest.restStep)
	}
	
	var mainInfo: Int {
		fatalError("Abstract property not implemented")
	}
	
	func mainInfoDescription(with change: Double) -> NSAttributedString {
		fatalError("Abstract method not implemented")
	}
	
	var secondaryInfo: Double {
		fatalError("Abstract property not implemented")
	}
	
	var secondaryInfoLabel: NSAttributedString {
		fatalError("Abstract property not implemented")
	}
	
	func set(mainInfo n: Int) {
		fatalError("Abstract method not implemented")
	}
	
	func set(secondaryInfo s: Double) {
		fatalError("Abstract method not implemented")
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[exercizeKey] = exercize.recordID.wcRepresentation
		obj[orderKey] = order
		obj[restKey] = rest
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let exercize = CDRecordID(wcRepresentation: src[exercizeKey] as? [String])?.getObject(fromDataManager: dataManager) as? GTSimpleSetsExercize,
			let order = src[orderKey] as? Int32,
			let rest = src[restKey] as? TimeInterval else {
				return false
		}
		
		self.exercize = exercize
		self.order = order
		self.rest = rest
		
		return true
	}

}
