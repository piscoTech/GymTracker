//
//  BackupListTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 26/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit

class BackupListTableViewController: UITableViewController {
	
	private var backups: ImportExportBackupManager.BackupList = []
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		updateList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func updateList(lazy: Bool = false) {
		let load = {
			DispatchQueue.main.async {
				self.backups = importExportManager.backups
				self.tableView.reloadSections([0], with: .automatic)
			}
		}
		
		if !lazy {
			importExportManager.loadBackups { bcks in
				load()
			}
		} else {
			load()
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, backups.count)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard backups.count > 0 else {
			return tableView.dequeueReusableCell(withIdentifier: "noBackup", for: indexPath)
		}
		
		let b = backups[indexPath.row]
		let name = Date.fromWorkoutExportName(URL(fileURLWithPath: b.path.lastPathComponent).deletingPathExtension().lastPathComponent) ?? b.date
		let cell = tableView.dequeueReusableCell(withIdentifier: "backup", for: indexPath)
			
		cell.textLabel?.text = name.getFormattedDateTime()
		
		return cell
    }
	
	// MARK: - Manage Backups
	
	private var documentController: UIActivityViewController?
	
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

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return importExportManager.backups.count > 0
    }

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		var act = [UITableViewRowAction]()
		
		let export = UITableViewRowAction(style: .normal, title: NSLocalizedString("EXPORT_BACKUP", comment: "export")) { _, row in
			self.tableView.setEditing(false, animated: true)
			
			DispatchQueue.main.async {
				self.documentController = UIActivityViewController(activityItems: [self.backups[row.row].path], applicationActivities: nil)
				self.documentController?.popoverPresentationController?.sourceView = tableView
				self.documentController?.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
				self.documentController?.completionWithItemsHandler = { _, _, _, _ in
					self.documentController = nil
				}
				
				self.present(self.documentController!, animated: true)
			}
		}
		act.append(export)
		
		if appDelegate.workoutList.canEdit {
			let restore = UITableViewRowAction(style: .default, title: NSLocalizedString("RESTORE_BACKUP", comment: "Restore")) { _, row in
				self.tableView.setEditing(false, animated: true)
				guard appDelegate.workoutList.canEdit else {
					return
				}
	
				// TODO: Restore backup
				print("Should restore backup with confirm")
			}
			restore.backgroundColor = #colorLiteral(red: 0, green: 0.7529411765, blue: 0, alpha: 1)
			act.append(restore)
		}
		
		let del = UITableViewRowAction(style: .destructive, title: NSLocalizedString("DELETE_BACKUP", comment: "Del")) { _, row in
			self.tableView.setEditing(false, animated: true)
			
			let b = self.backups[row.row]
			let name = Date.fromWorkoutExportName(URL(fileURLWithPath: b.path.lastPathComponent).deletingPathExtension().lastPathComponent) ?? b.date
			let confirm = UIAlertController(title: NSLocalizedString("DELETE_BACKUP_TITLE", comment: "Del"), message: NSLocalizedString("DELETE_BACKUP_CONFIRM", comment: "Del confirm") + name.getFormattedDateTime() + "?", preferredStyle: .actionSheet)
			confirm.addAction(UIAlertAction(title: NSLocalizedString("DELETE_BACKUP", comment: "Del"), style: .destructive) { _ in
				dataManager.deleteICloudDocument(b.path) { success in
					DispatchQueue.main.async {
						if success {
							self.backups.remove(at: row.row)
							self.tableView.reloadSections([0], with: .automatic)
						} else {
							let alert = UIAlertController(simpleAlert: NSLocalizedString("DELETE_BACKUP_FAIL", comment: "Err"), message: nil)
							self.present(alert, animated: true)
						}
					}
				}
			})
			confirm.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
			
			self.present(confirm, animated: true)
		}
		act.append(del)
		
		return act
	}

}
