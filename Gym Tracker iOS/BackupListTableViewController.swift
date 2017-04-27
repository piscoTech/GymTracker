//
//  BackupListTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 26/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit

class BackupListTableViewController: UITableViewController {
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		updateList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func updateList(lazy: Bool = false) {
		if !lazy {
			importExportManager.loadBackups { bcks in
				DispatchQueue.main.async {
					self.tableView.reloadSections([0], with: .automatic)
				}
			}
		} else {
			DispatchQueue.main.async {
				self.tableView.reloadSections([0], with: .automatic)
			}
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, importExportManager.backups.count)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard importExportManager.backups.count > 0 else {
			return tableView.dequeueReusableCell(withIdentifier: "noBackup", for: indexPath)
		}
		
		let b = importExportManager.backups[indexPath.row]
		let name = Date.fromWorkoutExportName(URL(fileURLWithPath: b.path.lastPathComponent).deletingPathExtension().lastPathComponent) ?? b.date
		let cell = tableView.dequeueReusableCell(withIdentifier: "backup", for: indexPath)
			
		cell.textLabel?.text = name.getFormattedDateTime()
		
		return cell
    }
	
	// MARK: - Manage Backups
	
	@IBAction func backupNow(_ sender: UIBarButtonItem) {
		sender.isEnabled = false
		
		importExportManager.doBackup(manual: true) { success in
			DispatchQueue.main.async {
				sender.isEnabled = true
				if success {
					self.updateList(lazy: true)
				}
			}
		}
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

}
