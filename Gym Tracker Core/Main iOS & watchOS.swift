//
//  Main iOS & watchOS.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 12/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

///Keep track of the version of health authorization required, increase this number to automatically display an authorization request.
public let authRequired = 2
///List of health data to require access to.
public let healthReadData = Set([
	HKObjectType.workoutType(),
	HKObjectType.quantityType(forIdentifier: .heartRate)!,
	HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
])
///List of health data to require write access to.
public let healthWriteData = Set([
	HKObjectType.workoutType(),
	HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
])
public let healthStore = HKHealthStore()
