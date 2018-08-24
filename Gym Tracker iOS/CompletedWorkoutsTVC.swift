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
import GymTrackerCore

class CompletedWorkoutsTableViewController: UITableViewController {
	
	private let batchSize = 40
	private var moreToBeLoaded = false
	private var isLoadingMore = true
	
	private weak var loadMoreCell: LoadMoreCell?
	
	private var workouts = [(name: String?, start: Date, duration: TimeInterval)]()
	private var ignoreWorkoutsWhenLoadingMore: [HKWorkout] = []

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
		workouts = []
		ignoreWorkoutsWhenLoadingMore = []
		moreToBeLoaded = false
		
		loadData()
	}
	
	private func loadData() {
		isLoadingMore = true
		loadMoreCell?.isEnabled = false
		
		let filter = HKQuery.predicateForObjects(from: HKSource.default())
		let limit: Int
		let predicate: NSPredicate
		
		if let lastStart = ignoreWorkoutsWhenLoadingMore.first?.startDate {
			predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
				filter,
				NSPredicate(format: "%K <= %@", HKPredicateKeyPathStartDate, lastStart as NSDate)
				])
			limit = ignoreWorkoutsWhenLoadingMore.count + batchSize
		} else {
			predicate = filter
			limit = batchSize
		}
		
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let type = HKObjectType.workoutType()
		
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			if let res = r as? [HKWorkout] {
				DispatchQueue.main.async {
					self.moreToBeLoaded = res.count >= limit
					let newWorkout = res.subtract(self.ignoreWorkoutsWhenLoadingMore)
					let addLineCount = self.workouts.isEmpty ? nil : newWorkout.count
					self.workouts += newWorkout.map { w in
						let name = w.metadata?[ExecuteWorkoutController.workoutNameMetadataKey] as? String
						let start = w.startDate
						let dur = w.duration
						
						return (name?.count ?? 0 > 0 ? name : nil, start, dur)
					}
					
					if let lastLoaded = newWorkout.last, let index = newWorkout.firstIndex(where: { $0.startDate == lastLoaded.startDate }) {
						self.ignoreWorkoutsWhenLoadingMore = Array(newWorkout.suffix(from: index))
					}
					
					self.tableView.beginUpdates()
					self.isLoadingMore = false
					if let added = addLineCount {
						let oldCount = self.tableView.numberOfRows(inSection: 0)
						self.tableView.insertRows(at: (oldCount ..< (oldCount + added)).map { IndexPath(row: $0, section: 0) }, with: .automatic)
						self.loadMoreCell?.isEnabled = true
					} else {
						self.tableView.reloadSections([0], with: .automatic)
					}
					
					if self.moreToBeLoaded && self.tableView.numberOfSections == 1 {
						self.tableView.insertSections([1], with: .automatic)
					} else if !self.moreToBeLoaded && self.tableView.numberOfSections > 1 {
						self.tableView.deleteSections([1], with: .automatic)
					}
					self.tableView.endUpdates()
				}
			}
		}
		
		healthStore.execute(workoutQuery)
	}

    override func numberOfSections(in tableView: UITableView) -> Int {
        return moreToBeLoaded ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			 return max(1, workouts.count)
		case 1:
			return 1
		default:
			return 0
		}
    }

	private var normalFont: UIFont!
	private var italicFont: UIFont!
	
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard workouts.count > 0 else {
			return tableView.dequeueReusableCell(withIdentifier: "noWorkout", for: indexPath)
		}
		
		if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "loadMore", for: indexPath) as! LoadMoreCell
			loadMoreCell = cell
			cell.isEnabled = !isLoadingMore
			
			return cell
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
			cell.textLabel?.text = GTLocalizedString("WORKOUT", comment: "Workout")
			cell.textLabel?.font = italicFont
		}
		
		cell.detailTextLabel?.text = [w.start.getFormattedDateTime(), w.duration.getDuration()].joined(separator: " – ")

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 1, loadMoreCell?.isEnabled ?? false {
			loadMoreCell?.isEnabled = false
			loadData()
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}

}
