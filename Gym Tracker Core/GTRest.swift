//
//  GTRest.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GTRest)
final class GTRest: GTPart {
	
	static let restStep: TimeInterval = 30
	private let minRest: TimeInterval = 30
	
	override class var objectType: String {
		return "GTRest"
	}
	
	private let restKey = "rest"
		
	@NSManaged private(set) var rest: TimeInterval
	
	override var parentCollection: ExercizeCollection? {
		return workout
	}
	
	func set(rest r: TimeInterval) {
		rest = max(r, minRest).rounded(to: GTRest.restStep)
	}
	
	override var isValid: Bool {
		return rest >= minRest && workout != nil
	}
	
	// MARK: - iOS/watchOS interface
	
	override var wcObject: WCObject? {
		guard let obj = super.wcObject else {
			return nil
		}
		
		obj[restKey] = rest
		
		return obj
	}
	
	override func mergeUpdatesFrom(_ src: WCObject, inDataManager dataManager: DataManager) -> Bool {
		guard super.mergeUpdatesFrom(src, inDataManager: dataManager) else {
			return false
		}
		
		guard let rest = src[restKey] as? TimeInterval else {
				return false
		}
		
		self.rest = rest
		
		return true
	}
	
}
