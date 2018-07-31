//
//  DataManagerUse.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 31/07/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation

extension DataManager {
	
	enum Usage: CustomStringConvertible {
		case application, testing
		
		var description: String {
			switch self {
			case .application:
				return "[App]"
			case .testing:
				return "[Test]"
			}
		}
	}
	
}
