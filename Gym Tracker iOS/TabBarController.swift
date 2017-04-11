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
		var res = true
		if self.selectedIndex == 0, let cur = self.viewControllers?[self.selectedIndex], cur == viewController {
			res = isPopToWorkoutListRootEnabled
		}
		
		if res && self.selectedIndex == 1 {
			appDelegate.currentWorkout?.exitWorkoutTrackingIfAppropriate()
		}
		
		return res
	}
	
	func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
		if self.selectedIndex == 2 {
			appDelegate.completedWorkouts?.refresh(self)
		}
	}

}
