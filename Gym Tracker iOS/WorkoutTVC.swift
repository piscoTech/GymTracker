//
//  WorkoutTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import GymTrackerCore

class WorkoutTableViewController: NamedPartCollectionTableViewController<GTWorkout> {
	
	private var isNewWorkout = false
	override var isNew: Bool {
		return isNewWorkout
	}
	
	private var startBtn: UIBarButtonItem!
	
	override var additionalRightButton: UIBarButtonItem? {
		return collection?.archived ?? true ? nil : startBtn
	}
	
	private let workoutActionId: CellInfo = ("WorkoutActionCell", "actions")

    override func viewDidLoad() {
		// Create a new workout
		if editMode && collection == nil {
			collection = appDelegate.dataManager.newWorkout()
			isNewWorkout = true
		}
		startBtn = UIBarButtonItem(title: GTLocalizedString("START_WORKOUT", comment: "Start"), style: .done, target: self, action: #selector(startWorkout))
		
		super.viewDidLoad()
		
		for (n, i) in [workoutActionId] {
			tableView.register(UINib(nibName: n, bundle: Bundle.main), forCellReuseIdentifier: i)
		}
		
		if #available(iOS 13, *) {} else {
			if self.presentationController != nil {
				self.navigationController?.navigationBar.barStyle = .black
			}
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	override func updateButtons() {
		super.updateButtons()
		
		startBtn.isEnabled = delegate.canEdit
		if !editMode {
			tableView.reloadSections([2], with: .none)
		}
	}
	
	@objc func startWorkout() {
		guard delegate.canEdit && !isNew else {
			return
		}
		
		appDelegate.startWorkout(collection)
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return super.numberOfSections(in: tableView) + (editMode ? 0 : 1)
	}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 2 && !editMode {
			return 1
		}
		
		return super.tableView(tableView, numberOfRowsInSection: section)
    }
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if !editMode && indexPath.section == 2 {
			let cell = tableView.dequeueReusableCell(withIdentifier: workoutActionId.identifier, for: indexPath) as! WorkoutDeleteArchiveCell
			
			cell.exportBtn.addTarget(self, action: #selector(export), for: .primaryActionTriggered)
			
			let title = (collection.archived ? "UN" : "") + "ARCHIVE_WORKOUT"
			cell.archiveBtn.setTitle(GTLocalizedString(title, comment: "(Un)archive"), for: [])
			cell.archiveBtn.isEnabled = delegate.canEdit
			cell.archiveBtn.addTarget(self, action: #selector(archiveWorkout), for: .primaryActionTriggered)
			
			cell.deleteBtn.isEnabled = delegate.canEdit
			cell.deleteBtn.addTarget(self, action: #selector(deleteWorkout), for: .primaryActionTriggered)
			
			return cell
		}
		
		return super.tableView(tableView, cellForRowAt: indexPath)
	}
	
	// MARK: - Edit
	
	override func saveEdit() -> Bool{
		if super.saveEdit() {
			if isNew {
				delegate.updateWorkout(collection, how: .new, wasArchived: false)
			} else {
				delegate.updateWorkout(collection, how: .edit, wasArchived: collection.archived)
			}
			
			return true
		} else {
			return false
		}
	}
	
	@objc func deleteWorkout() {
		guard !editMode, delegate.canEdit else {
			return
		}
		
		let confirm = UIAlertController(title: GTLocalizedString("DELETE_WORKOUT", comment: "Del"), message: GTLocalizedString("DELETE_WORKOUT_CONFIRM", comment: "Del confirm") + collection.name + "?", preferredStyle: .alert)
		confirm.addAction(UIAlertAction(title: GTLocalizedString("DELETE", comment: "Del"), style: .destructive) { _ in
			let archived = self.collection.archived
			if appDelegate.dataManager.persistChangesForObjects([], andDeleteObjects: [self.collection]) {
				self.delegate.updateWorkout(self.collection, how: .delete, wasArchived: archived)
				_ = self.navigationController?.popViewController(animated: true)
			} else {
				appDelegate.dataManager.discardAllChanges()
				let alert = UIAlertController(simpleAlert: GTLocalizedString("DELETE_WORKOUT_FAIL", comment: "Err"), message: nil)
				self.present(alert, animated: true)
			}
		})
		confirm.addAction(UIAlertAction(title: GTLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
		
		self.present(confirm, animated: true)
	}
	
	@objc func archiveWorkout() {
		guard !editMode, delegate.canEdit else {
			return
		}
		
		let errTitle = GTLocalizedString((collection.archived ? "UN" : "") + "ARCHIVE_WORKOUT_FAIL", comment: "(Un)archive fail")
		let archived = collection.archived
		collection.archived = !archived
		if appDelegate.dataManager.persistChangesForObjects([self.collection], andDeleteObjects: []) {
			self.delegate.updateWorkout(self.collection, how: .archiveChange, wasArchived: archived)
			tableView.reloadSections(IndexSet(integer: 2), with: .fade)
		} else {
			appDelegate.dataManager.discardAllChanges()
			let alert = UIAlertController(simpleAlert: errTitle, message: nil)
			self.present(alert, animated: true)
		}
	}
	
	// MARK: - Export
	
	private var documentController: UIActivityViewController?
	
	@objc func export() {
		let loading = UIAlertController.getModalLoading()
		present(loading, animated: true)
		DispatchQueue.background.async {
			if let path = appDelegate.dataManager.importExportManager.export(workout: self.collection) {
				DispatchQueue.main.async {
					loading.dismiss(animated: true) {
						self.documentController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
						self.documentController?.completionWithItemsHandler = { _, _, _, _ in
							self.documentController = nil
						}
						
						self.present(self.documentController!, animated: true)
					}
				}
			} else {
				DispatchQueue.main.async {
					loading.dismiss(animated: true) {
						self.present(UIAlertController(simpleAlert: GTLocalizedString("EXPORT_FAIL", comment: "Error"), message: nil), animated: true)
					}
				}
			}
		}
	}

}
