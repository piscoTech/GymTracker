//
//  WorkoutListTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import GymTrackerCore

class WorkoutListTableViewController: UITableViewController {
	
	@IBOutlet weak var addButton: UIBarButtonItem!
	
	private var workouts = [GTWorkout]()
	private var archivedWorkouts = [GTWorkout]()
	private weak var workoutController: WorkoutTableViewController? {
		didSet {
			workoutController?.delegate = self
		}
	}
	lazy var canEdit = appDelegate.dataManager.preferences.runningWorkout == nil

    override func viewDidLoad() {
        super.viewDidLoad()
		
		appDelegate.workoutList = self
		updateView()
		enableEdit(canEdit)
		
		if #available(iOS 13, *) {} else {
			self.navigationController?.navigationBar.barStyle = .black
			tableView.backgroundColor = .black
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func updateView(autoReload: Bool = true) {
		self.workouts.removeAll(keepingCapacity: true)
		self.archivedWorkouts.removeAll(keepingCapacity: true)
		
		for w in GTWorkout.getList(fromDataManager: appDelegate.dataManager) {
			if w.archived {
				archivedWorkouts.append(w)
			} else {
				workouts.append(w)
			}
		}
		
		workoutController?.updateView()
		
		if autoReload {
			tableView.reloadData()
		}
	}
	
	func refreshData() {
		let old = canEdit
		self.enableEdit(false)
		updateView()
		self.enableEdit(old)
	}
	
	func exitDetailAndCreation(completion: (() -> Void)?) {
		if let wrkt = workoutController {
			wrkt.cancel(animated: false, animationCompletion: completion)
			if !wrkt.isNew {
				self.navigationController?.popToRootViewController(animated: false)
				completion?()
			}
		} else {
			completion?()
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return 1 + min(archivedWorkouts.count, 1)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return max(workouts.count, 1)
		case 1:
			return archivedWorkouts.count
		default:
			return 0
		}
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return GTLocalizedString("WORKOUTS", comment: "Workouts")
		case 1:
			return GTLocalizedString("ARCH_WORKOUTS", comment: "Archived Workouts")
		default:
			return nil
		}
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if workouts.count == 0 && indexPath.section == 0 {
        	return tableView.dequeueReusableCell(withIdentifier: "noWorkout", for: indexPath)
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)
		let w = (indexPath.section == 0 ? workouts : archivedWorkouts)[indexPath.row]
		cell.textLabel?.text = w.name
		cell.detailTextLabel?.text = w.description

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if (indexPath.section == 0 && !workouts.isEmpty) || indexPath.section == 1 {
			openWorkout(sender: indexPath)
		}
	}
	
	func enableEdit(_ flag: Bool) {
		canEdit = flag
		addButton.isEnabled = canEdit
		
		if !canEdit {
			workoutController?.doCancel()
		} else {
			workoutController?.updateButtons()
		}
	}
	
	// MARK: - Delete, (Un)archive & Start Workout

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return canEdit && (indexPath.section == 0 ? workouts : archivedWorkouts).count > 0
    }
	
	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		var act = [UITableViewRowAction]()
		
		if canEdit && indexPath.section == 0 {
			let start = UITableViewRowAction(style: .default, title: GTLocalizedString("START_WORKOUT", comment: "Start")) { _, row in
				self.tableView.setEditing(false, animated: true)
				guard self.canEdit && row.section == 0 else {
					return
				}
				
				appDelegate.startWorkout(self.workouts[row.row])
			}
			start.backgroundColor = greenTint
			act.append(start)
		}
		
		let archive = UITableViewRowAction(style: .normal, title: GTLocalizedString((indexPath.section == 1 ? "UN" : "") + "ARCHIVE_WORKOUT", comment: "(un)archive")) { _, row in
			self.tableView.setEditing(false, animated: true)
			guard self.canEdit else {
				return
			}
			
			let workout = (row.section == 0 ? self.workouts : self.archivedWorkouts)[row.row]
			let errTitle = GTLocalizedString((workout.archived ? "UN" : "") + "ARCHIVE_WORKOUT_FAIL", comment: "(Un)archive fail")
			let archived = workout.archived
			workout.archived = !archived
			if appDelegate.dataManager.persistChangesForObjects([workout], andDeleteObjects: []) {
				self.updateWorkout(workout, how: .archiveChange, wasArchived: archived)
			} else {
				appDelegate.dataManager.discardAllChanges()
				let alert = UIAlertController(simpleAlert: errTitle, message: nil)
				self.present(alert, animated: true)
			}
		}
		act.append(archive)
		
		let del = UITableViewRowAction(style: .destructive, title: GTLocalizedString("DELETE", comment: "Del")) { _, row in
			self.tableView.setEditing(false, animated: true)
			guard self.canEdit else {
				return
			}
			
			let workout = (row.section == 0 ? self.workouts : self.archivedWorkouts)[row.row]
			let confirm = UIAlertController(
				title: GTLocalizedString("DELETE_WORKOUT", comment: "Del"),
				message: String(format: GTLocalizedString("DELETE_WORKOUT_CONFIRM", comment: "Del confirm"), workout.name),
				preferredStyle: .alert)
			confirm.addAction(UIAlertAction(title: GTLocalizedString("DELETE", comment: "Del"), style: .destructive) { _ in
				let archived = workout.archived
				if appDelegate.dataManager.persistChangesForObjects([], andDeleteObjects: [workout]) {
					self.updateWorkout(workout, how: .delete, wasArchived: archived)
				} else {
					appDelegate.dataManager.discardAllChanges()
					let alert = UIAlertController(simpleAlert: GTLocalizedString("DELETE_WORKOUT_FAIL", comment: "Err"), message: nil)
					self.present(alert, animated: true)
				}
			})
			confirm.addAction(UIAlertAction(title: GTLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
			
			self.present(confirm, animated: true)
		}
		act.append(del)
		
		return act
	}
	
	// MARK: - Update list
	
	enum WorkoutUpdateType {
		case new, edit, delete, archiveChange
	}
	
	func updateWorkout(_ w: GTWorkout, how: WorkoutUpdateType, wasArchived: Bool) {
		switch how {
		case .new:
			tableView.beginUpdates()
			
			if workouts.count == 0 {
				tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
			}
			updateView(autoReload: false)
			tableView.insertRows(at: [IndexPath(row: workouts.firstIndex(of: w)!, section: 0)], with: .automatic)
			
			tableView.endUpdates()
		case .edit:
			tableView.beginUpdates()
			
			var index = IndexPath(row: (wasArchived ? archivedWorkouts : workouts).firstIndex(of: w)!, section: wasArchived ? 1 : 0)
			tableView.deleteRows(at: [index], with: .automatic)
			updateView(autoReload: false)
			index.row = (wasArchived ? archivedWorkouts : workouts).firstIndex(of: w)!
			tableView.insertRows(at: [index], with: .automatic)
			
			tableView.endUpdates()
		case .delete:
			tableView.beginUpdates()
			
			let index = IndexPath(row: (wasArchived ? archivedWorkouts : workouts).firstIndex(of: w)!, section: wasArchived ? 1 : 0)
			tableView.deleteRows(at: [index], with: .automatic)
			updateView(autoReload: false)
			if index.section == 1 && archivedWorkouts.count == 0 {
				tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
			}
			if index.section == 0 && workouts.count == 0 {
				tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
			}
			
			tableView.endUpdates()
		case .archiveChange:
			let countOld = workouts.count
			let countArchOld = archivedWorkouts.count
			let index = IndexPath(row: (wasArchived ? archivedWorkouts : workouts).firstIndex(of: w)!, section: wasArchived ? 1 : 0)
			updateView(autoReload: false)
			let newIndex = IndexPath(row: (!wasArchived ? archivedWorkouts : workouts).firstIndex(of: w)!, section: !wasArchived ? 1 : 0)
			
			tableView.beginUpdates()
			var doInsert = true
			var doRemove = true
			
			// Archiving
			if index.section == 0 && countArchOld == 0 {
				tableView.insertSections(IndexSet(integer: 1), with: .automatic)
				doInsert = false
			}
			// Unarchiving
			if index.section == 1 && archivedWorkouts.count == 0 {
				tableView.deleteSections(IndexSet(integer: 1), with: .automatic)
				doRemove = false
			}
			
			if doRemove {
				tableView.deleteRows(at: [index], with: .automatic)
			}
			if doInsert {
				tableView.insertRows(at: [newIndex], with: .automatic)
			}
			
			// Unarchiving
			if index.section == 1 && countOld == 0 {
				tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
			}
			// Archiving
			if index.section == 0 && workouts.count == 0 {
				tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
			}
			
			tableView.endUpdates()
		}
	}
	
	func globallyUpdateSecondaryInfoChange() {
		workoutController?.updateSecondaryInfoChange()
	}

    // MARK: - Navigation
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		if identifier == "newWorkout" {
			return canEdit
		}
		
		return true
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case "newWorkout":
			let nav = segue.destination as! UINavigationController
			let dest = WorkoutTableViewController()
			nav.viewControllers = [dest]
			
			workoutController = dest
			dest.editMode = true
		default:
			break
		}
    }
	
	private func openWorkout(sender: Any?) {
		let w: GTWorkout
		switch sender {
		case let send as GTWorkout:
			w = send
		case let index as IndexPath:
			w = (index.section == 0 ? workouts : archivedWorkouts)[index.row]
		default:
			fatalError("Unable to determine workout")
		}
		
		let dest = WorkoutTableViewController()
		workoutController = dest
		dest.collection = w
		
		navigationController?.pushViewController(dest, animated: true)
	}

}
