//
//  WorkoutTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit

class WorkoutTableViewController: UITableViewController {
	
	var workout: Workout!
	var editMode = false
	private var isNew = false
	
	@IBOutlet var cancelBtn: UIBarButtonItem!
	@IBOutlet var doneBtn: UIBarButtonItem!
	private var editBtn: UIBarButtonItem!
	
	private var deletedEntities = [DataObject]()

    override func viewDidLoad() {
        super.viewDidLoad()

		// Create a new workout
		if editMode && workout == nil {
			workout = dataManager.newWorkout()
			isNew = true
		}
		
		editBtn = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
		
		// The view is already in edit mode
		if !editMode {
			updateView()
		} else {
			updateBtn()
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func updateView() {
		fatalError("Add complete support")
		
		updateBtn()
		// TODO: Set bar items
		tableView.reloadData()
	}
	
	private func updateBtn() {
		doneBtn.isEnabled = workout.name.length > 0 && workout.hasExercizes
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return max(workout.exercizes.count, 1)
		case 2:
			return editMode && !isNew ? 2 : 1
		default:
			return 0
		}
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 1 {
			return NSLocalizedString("EXERCIZES", comment: "Exercizes")
		}
		
		return nil
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			let cell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath) as! SingleFieldCell
			cell.isEnabled = !editMode
			cell.textField.text = workout.name
			return cell
		case 1:
			if workout.exercizes.count == 0 {
				return tableView.dequeueReusableCell(withIdentifier: "noExercize", for: indexPath)
			}
			
			let e = workout.exercize(n: Int32(indexPath.row))!
			if e.isRest {
				fatalError("I'm lazy now")
			} else {
				let cell = tableView.dequeueReusableCell(withIdentifier: "exercize", for: indexPath)
				updateExercizeCell(cell, for: e)
				
				return cell
			}
		case 2:
			let id = editMode && indexPath.row == 0 ? "add" : "actions"
			return tableView.dequeueReusableCell(withIdentifier: id, for: indexPath)
		default:
			fatalError("Unknown section")
		}
    }
	
	private func updateExercizeCell(_ cell: UITableViewCell, for e: Exercize) {
		cell.textLabel?.text = e.name
		cell.detailTextLabel?.text = e.setsSummary
	}
	
	// MARK: Editing
	
	func edit(_ sender: AnyObject) {
		editMode = true
		updateView()
	}
	
	func saveEdit(_ sender: AnyObject) {
		// TODO: follow the whole workout relation tree and mark all entities as changed
	}
	
	@IBAction func newExercize(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		tableView.beginUpdates()
		if workout.exercizes.count == 0 {
			tableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
		}
		
		let e = dataManager.newExercize(for: workout)
		e.isRest = false
		
		tableView.insertRows(at: [IndexPath(row: Int(e.order), section: 1)], with: .automatic)
		tableView.endUpdates()
		performSegue(withIdentifier: "exercizeDetail", sender: e)
		
		print(workout.exercizeList)
	}
	
	func updateExercize(_ e: Exercize) {
		precondition(e.workout == workout, "Exercize is not from current workout")
		
		deletedEntities += e.compactSets() as [DataObject]
		let keep = e.name?.length ?? 0 > 0 && e.sets.count > 0
		
		if !keep {
			removeExercize(e)
		} else if let cell = tableView.cellForRow(at: IndexPath(row: Int(e.order), section: 1)) {
			updateExercizeCell(cell, for: e)
		}
		
		print(workout.exercizeList)
	}
	
	private func removeExercize(_ e: Exercize) {
		
		let index = IndexPath(row: Int(e.order), section: 1)
		// No need to also mark the sets as removed: if they are new there is no need to send them, else they will be deleted in cascade with the exercize.
		deletedEntities.append(e)
		workout.removeExercize(e)
		
		tableView.beginUpdates()
		tableView.deleteRows(at: [index], with: .automatic)
		
		if workout.exercizes.count == 0 {
			tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
		}
		
		tableView.endUpdates()
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

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation
	
	@IBAction func cancel(_ sender: AnyObject) {
		dataManager.discardAllChanges()
		
		if isNew {
			self.dismiss(animated: true)
		} else {
			editMode = false
			deletedEntities.removeAll()
			updateView()
		}
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case "exercizeDetail":
			let e: Exercize
			switch sender {
			case let send as Exercize:
				e = send
			case _ as UITableViewCell:
				guard let index = tableView.indexPathForSelectedRow, index.section == 1 else {
					fallthrough
				}
				
				guard let tmp = workout.exercize(n: Int32(index.row)), !tmp.isRest else {
					fallthrough
				}
				
				e = tmp
			default:
				fatalError("Unable to determine exercize")
			}
			
			let dest = segue.destination as! ExercizeTableViewController
			dest.exercize = e
			dest.editMode = self.editMode
			dest.delegate = self
		default:
			break
		}
	}

}
