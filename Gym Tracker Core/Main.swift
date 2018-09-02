//
//  Main.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 16/11/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import UIKit
import HealthKit

public let customTint = #colorLiteral(red: 0.7568627451, green: 0.9215686275, blue: 0.2, alpha: 1)
public let redTint = #colorLiteral(red: 1, green: 0.1882352941, blue: 0, alpha: 1)
public let greenTint = #colorLiteral(red: 0, green: 0.7529411765, blue: 0, alpha: 1)
public let textColor = #colorLiteral(red: 0.9198423028, green: 0.9198423028, blue: 0.9198423028, alpha: 1)

let applicationDocumentsDirectory: URL = {
	return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
}()

let timesSign = "×"
let minusSign = "−"
let plusSign = "+"

/// Returns a localized string from the GymTrackerCore framework bundle.
public func GTLocalizedString(_ key: String, comment: String) -> String {
	// Use any class from the framework included in all targets
	let bundle = Bundle(for: DataManager.self)
	return NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: comment)
}

public enum GTError: Error {
	case importFailure(Set<GTDataObject>)
	case generic
	case migration
}

/// List of health data to require access to.
public let healthReadData = Set([
	HKObjectType.workoutType(),
	HKObjectType.quantityType(forIdentifier: .heartRate)!,
	HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
	])
/// List of health data to require write access to.
public let healthWriteData = Set([
	HKObjectType.workoutType(),
	HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
	])
public let healthStore = HKHealthStore()
