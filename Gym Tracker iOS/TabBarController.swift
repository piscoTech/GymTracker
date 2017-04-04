//
//  TabBarController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 04/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate {

    var isPopToWorkoutListRootEnabled = true
	
	func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
		if let cur = self.viewControllers?[self.selectedIndex], cur == viewController {
			return isPopToWorkoutListRootEnabled
		}
		
		return true
	}

}
