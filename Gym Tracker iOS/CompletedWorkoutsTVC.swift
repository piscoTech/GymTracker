//
//  CompletedWorkoutsTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 10/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary

class CompletedWorkoutsTableViewController: UITableViewController {
	
	let displayLimit = 50
	
	private var inInit = true
	private var workouts = [(name: String?, start: Date, duration: TimeInterval)]()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		appDelegate.completedWorkouts = self

        refresh(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
	
	@IBAction func refresh(_ sender: AnyObject) {
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let filter = HKQuery.predicateForObjects(from: HKSource.default())
		let type = HKObjectType.workoutType()
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: filter, limit: displayLimit, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			self.workouts = (r as? [HKWorkout] ?? []).map { w in
				let name = w.metadata?[ExecuteWorkoutController.workoutNameMetadataKey] as? String
				let start = w.startDate
				let dur = w.duration
				
				return (name?.count ?? 0 > 0 ? name : nil, start, dur)
			}
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
		
		healthStore.execute(workoutQuery)
	}

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, workouts.count)
    }

	private var normalFont: UIFont!
	private var italicFont: UIFont!
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard workouts.count > 0 else {
			return tableView.dequeueReusableCell(withIdentifier: "noWorkout", for: indexPath)
		}
		
		let w = workouts[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)
		
		if normalFont == nil {
			normalFont = cell.textLabel?.font
			if let font = normalFont?.fontDescriptor, let descr = font.withSymbolicTraits(.traitItalic) {
				italicFont = UIFont(descriptor: descr, size: 0)
			}
		}
		
		if let n = w.name {
			cell.textLabel?.text = n
			cell.textLabel?.font = normalFont
		} else {
			cell.textLabel?.text = NSLocalizedString("WORKOUT", comment: "Workout")
			cell.textLabel?.font = italicFont
		}
		
		cell.detailTextLabel?.text = [w.start.getFormattedDateTime(), w.duration.getDuration()].joined(separator: " – ")

        return cell
    }

}
