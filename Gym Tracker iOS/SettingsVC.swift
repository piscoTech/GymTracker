//
//  SettingsViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 03/04/17.
//  Copyright (c) 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import GymTrackerCore

class SettingsViewController: UITableViewController {
	
	private var appInfo: String!
	private var errNoBackup: String!
	private var backupUsageManual: String!
	private var backupUsageAuto: String!
	
	private var iCloudEnabled = false
	
	private var documentController: UIActivityViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		appDelegate.settings = self
		
		appInfo = GTLocalizedString("REPORT_TEXT", comment: "Report problem") + "\n\nGym Tracker \(Bundle.main.versionDescription)\n© 2017-2020 Marco Boschi"
		errNoBackup = GTLocalizedString("ERR_BACKUP_UNAVAILABLE", comment: "Cannot use becuase...")
		backupUsageManual = GTLocalizedString("BACKUP_USAGE_MANUAL", comment: "How-to")
		backupUsageAuto = GTLocalizedString("BACKUP_USAGE_AUTO", comment: "How-to")
		
		appDelegate.dataManager.reportICloudStatus { res in
			self.iCloudEnabled = res
			appDelegate.dataManager.importExportManager.doBackup()
			
			DispatchQueue.main.async {
				self.tableView.reloadSections([0], with: .automatic)
			}
		}
		
		if #available(iOS 13, *) {} else {
			self.navigationController?.navigationBar.barStyle = .black
			tableView.backgroundColor = .black
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case 0:
			return iCloudEnabled ? (
				appDelegate.dataManager.preferences.useBackups ? backupUsageAuto : backupUsageManual
				) : errNoBackup
		case 1:
			return appInfo
		default:
			return nil
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return iCloudEnabled ? 2 : 1
		case 1:
			return 2
		default:
			fatalError("Unknown section")
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			if indexPath.row == 0 {
				let cell = tableView.dequeueReusableCell(withIdentifier: "enableBackup", for: indexPath)
				let swt = cell.viewWithTag(10) as! UISwitch
				swt.isEnabled = iCloudEnabled
				swt.isOn = iCloudEnabled && appDelegate.dataManager.preferences.useBackups
				
				return cell
			} else {
				return tableView.dequeueReusableCell(withIdentifier: "backupList", for: indexPath)
			}
		case 1:
			return tableView.dequeueReusableCell(withIdentifier: indexPath.row == 0 ? "sourceCode" : "contact", for: indexPath)
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
		case (1, 0):
			UIApplication.shared.open(URL(string: "https://github.com/piscoTech/GymTracker")!)
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	@IBAction func enableDisableBackups(_ sender: UISwitch) {
		guard iCloudEnabled else {
			return
		}
		
		appDelegate.dataManager.preferences.useBackups = sender.isOn
		tableView.reloadSections([0], with: .automatic)
		if sender.isOn {
			appDelegate.dataManager.importExportManager.doBackup()
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let id = segue.identifier else {
			return
		}
		
		switch id {
		case "contact":
			let dest = (segue.destination as! UINavigationController).topViewController as! ContactMeViewController
			dest.appName = "GymTracker"
		default:
			break
		}
	}
	
}
