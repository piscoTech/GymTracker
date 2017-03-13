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
	
	private func updateView() {
		self.workouts.removeAll(keepingCapacity: true)
		self.archivedWorkouts.removeAll(keepingCapacity: true)
		
		for w in Workout.getList() {
			if w.archived {
				archivedWorkouts.append(w)
			} else {
				workouts.append(w)
			}
		}
		
		tableView.reloadData()
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
		cell.textLabel?.text = (indexPath.section == 0 ? workouts : archivedWorkouts)[indexPath.row].name

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

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case "newWorkout":
			break
//			let dest = (segue.destination as! UINavigationController).viewControllers.first as! WorkoutTableViewController
			// TODO: Set destination in create-new mode
		default:
			break
		}
    }

}
