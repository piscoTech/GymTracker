//
//  Notification.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 30/07/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UserNotifications

struct GTNotification {
	
	enum ID: String {
		case restStart = "restTimeNotificationID"
		case restEnd = "restEndNotificationID"
		case currentSetInfo = "nextSetNotificationID"
	}
	
	enum Action: String {
		case endRest = "endRestNotificationActionID"
		case endSet = "endSetNotificationActionID"
		case endSetWeight = "endSetWeightNotificationActionID"
		case endSetWeightInApp = "endSetWeightInAppNotificationActionID"
		
		static var genericSetWeightUpdateOptions: UNNotificationActionOptions = {
			if #available(iOS 12.0, *) {
				return []
			} else {
				return .foreground
			}
		}()
	}
	
	enum Category: String {
		case restStart = "endRestNowNotificationCategoryID"
		case restEnd = "endRestNotificationCategoryID"
		
		case interactiveCurrentSetInfo = "interactiveEndSetNotificationCategoryID"
		case interactiveLastSetInfo = "interactiveEndWorkoutNotificationCategoryID"
		
		case staticCurrentSetInfo = "endSetNotificationCategoryID"
		case staticLastSetInfo = "endWorkoutNotificationCategoryID"
		
		static let currentSetInfo: Category = {
			if #available(iOS 12.0, *) {
				return .interactiveCurrentSetInfo
			} else {
				return .staticCurrentSetInfo
			}
		}()
		
		static let lastSetInfo: Category = {
			if #available(iOS 12.0, *) {
				return .interactiveLastSetInfo
			} else {
				return .staticLastSetInfo
			}
		}()
	}
	
	enum UserInfo: String {
		case setWeight = "setWeight"
		case setWeightChange = "setWeightChange"
	}
	
	static let immediateNotificationDelay: TimeInterval = 1
	
}
