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
	private var errNoBackup: String!
	private var backupUsageManual: String!
	private var backupUsageAuto: String!
	
	private var iCloudEnabled = false
	
	override func viewDidLoad() {
		super.viewDidLoad()

		appDelegate.settings = self
		
		appInfo = NSLocalizedString("REPORT_TEXT", comment: "Report problem") + "\n\nGym Tracker \(Bundle.main.versionDescription)\n© 2017 Marco Boschi"
		errNoBackup = NSLocalizedString("ERR_BACKUP_UNAVAILABLE", comment: "Cannot use becuase...")
		backupUsageManual = NSLocalizedString("BACKUP_USAGE_MANUAL", comment: "How-to")
		backupUsageAuto = NSLocalizedString("BACKUP_USAGE_AUTO", comment: "How-to")
		
		dataManager.reportICloudStatus { res in
			self.iCloudEnabled = res
			importExportManager.doBackup()
			
			DispatchQueue.main.async {
				self.tableView.reloadSections([1], with: .automatic)
			}
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case 1:
			return iCloudEnabled ? (preferences.useBackups ? backupUsageAuto : backupUsageManual) : errNoBackup
		case 2:
			return appInfo
		default:
			return nil
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 1:
			return iCloudEnabled ? 2 : 1
		default:
			return 1
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			return tableView.dequeueReusableCell(withIdentifier: "authorize", for: indexPath)
		case 1:
			if indexPath.row == 0 {
				let cell = tableView.dequeueReusableCell(withIdentifier: "enableBackup", for: indexPath)
				let swt = cell.viewWithTag(10) as! UISwitch
				swt.isEnabled = iCloudEnabled
				swt.isOn = iCloudEnabled && preferences.useBackups
				
				return cell
			} else {
				return tableView.dequeueReusableCell(withIdentifier: "backupList", for: indexPath)
			}
		case 2:
			return tableView.dequeueReusableCell(withIdentifier: "sourceCode", for: indexPath)
		default:
			fatalError("Unknown section")
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch (indexPath.section, indexPath.row) {
		case (0, 0):
			appDelegate.authorizeHealthAccess()
		case (2, 0):
			UIApplication.shared.open(URL(string: "https://github.com/piscoTech/GymTracker")!, options: [:], completionHandler: nil)
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	@IBAction func enableDisableBackups(_ sender: UISwitch) {
		guard iCloudEnabled else {
			return
		}
		
		preferences.useBackups = sender.isOn
		tableView.reloadSections([1], with: .automatic)
		if sender.isOn {
			importExportManager.doBackup()
		}
	}
	
}
