//
//  SettingsViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 03/04/17.
//  Copyright (c) 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class SettingsViewController: UITableViewController {
	
	private var appInfo: String!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		appDelegate.settings = self
		
		appInfo = NSLocalizedString("REPORT_TEXT", comment: "Report problem") + "\n\nGym Tracker \(Bundle.main.versionDescription)\n© 2017 Marco Boschi"
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == 1 {
			return appInfo
		}
		
		return nil
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch (indexPath.section, indexPath.row) {
		case (0, 0):
			appDelegate.authorizeHealthAccess()
		case (1, 0):
			UIApplication.shared.open(URL(string: "https://github.com/piscoTech/GymTracker")!, options: [:], completionHandler: nil)
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
}
