//
//  Notification.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 30/07/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UserNotifications

public struct GTNotification {
	
	public enum ID: String {
		case restStart = "restTimeNotificationID"
		case restEnd = "restEndNotificationID"
		case currentSetInfo = "nextSetNotificationID"
	}
	
	public enum Action: String {
		case endRest = "endRestNotificationActionID"
		case endSet = "endSetNotificationActionID"
		case endSetWeight = "endSetWeightNotificationActionID"
		case endSetWeightInApp = "endSetWeightInAppNotificationActionID"
		
		static public var genericSetWeightUpdateOptions: UNNotificationActionOptions = {
			if #available(iOS 12.0, *) {
				return []
			} else {
				return .foreground
			}
		}()
	}
	
	public enum Category: String {
		case restStart = "endRestNowNotificationCategoryID"
		case restEnd = "endRestNotificationCategoryID"
		
		case interactiveCurrentSetInfo = "interactiveEndSetNotificationCategoryID"
		case interactiveLastSetInfo = "interactiveEndWorkoutNotificationCategoryID"
		
		case staticCurrentSetInfo = "endSetNotificationCategoryID"
		case staticLastSetInfo = "endWorkoutNotificationCategoryID"
		
		static public let currentSetInfo: Category = {
			if #available(iOS 12.0, *) {
				return .interactiveCurrentSetInfo
			} else {
				return .staticCurrentSetInfo
			}
		}()
		
		static public let lastSetInfo: Category = {
			if #available(iOS 12.0, *) {
				return .interactiveLastSetInfo
			} else {
				return .staticLastSetInfo
			}
		}()
	}
	
	public enum UserInfo: String {
		case setWeight = "setWeight"
		case setWeightChange = "setWeightChange"
	}
	
	static public let immediateNotificationDelay: TimeInterval = 1
	
}
