//
//  ExercizeCollection.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation

protocol ExercizeCollection {
	
	associatedtype Step: GTStep
	
	var exercizeList: [Step] { get }
	
}
