//
//  WorkoutListTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit

class WorkoutListTableViewController: UITableViewController {
	
	private var workouts = [Workout]()
	private var archivedWorkouts = [Workout]()
	private weak var workoutController: WorkoutTableViewController? {
		didSet {
			workoutController?.delegate = self
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		// TODO: Support editing: remove and archive
//        self.navigationItem.rightBarButtonItems?.append(self.editButtonItem)
		updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func updateView(autoReload: Bool = true) {
		self.workouts.removeAll(keepingCapacity: true)
		self.archivedWorkouts.removeAll(keepingCapacity: true)
		
		for w in Workout.getList() {
			if w.archived {
				archivedWorkouts.append(w)
			} else {
				workouts.append(w)
			}
		}
		
		if autoReload {
			tableView.reloadData()
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
			return NSLocalizedString("WORKOUTS", comment: "Workouts")
		case 1:
			return NSLocalizedString("ARCH_WORKOUTS", comment: "Archived Workouts")
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

	/*
	// TODO: Support editing: remove and (un)archive)
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */
	
	// MARK: - Update list
	
	enum WorkoutUpdateType {
		case new, edit, delete, archive, unarchive
	}
	
	func updateWorkout(_ w: Workout, how: WorkoutUpdateType, isManualUpdate: Bool = true) {
		switch how {
		case .new:
			tableView.beginUpdates()
			
			if workouts.count == 0 {
				tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
			}
			updateView(autoReload: false)
			tableView.insertRows(at: [IndexPath(row: workouts.index(of: w)!, section: 0)], with: .automatic)
			
			tableView.endUpdates()
			
			if isManualUpdate {
				// TODO: Auto-segue to workout
			}
		case .edit:
			tableView.beginUpdates()
			
			var index = IndexPath(row: (w.archived ? archivedWorkouts : workouts).index(of: w)!, section: w.archived ? 1 : 0)
			tableView.deleteRows(at: [index], with: .automatic)
			updateView(autoReload: false)
			index.row = (w.archived ? archivedWorkouts : workouts).index(of: w)!
			tableView.insertRows(at: [index], with: .automatic)
			
			tableView.endUpdates()
		case .delete:
			fatalError()
		case .archive:
			fatalError()
		case .unarchive:
			fatalError()
		}
	}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case "newWorkout":
			let dest = (segue.destination as! UINavigationController).viewControllers.first as! WorkoutTableViewController
			workoutController = dest
			dest.editMode = true
		case "showWorkout":
			let w: Workout
			switch sender {
			case let send as Workout:
				w = send
			case _ as UITableViewCell:
				guard let index = tableView.indexPathForSelectedRow else {
					fallthrough
				}
				
				w = (index.section == 0 ? workouts : archivedWorkouts)[index.row]
			default:
				fatalError("Unable to determine workout")
			}
			
			let dest = segue.destination as! WorkoutTableViewController
			workoutController = dest
			dest.workout = w
		default:
			break
		}
    }

}
