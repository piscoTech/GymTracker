//
//  AskChoiceTableViewController.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 22/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import GymTrackerCore

class AskChoiceTableViewController: UITableViewController {
	
	var choices: [GTChoice]!
	var n: Int!
	
	private var choice: Int32!
	var otherChoices: [GTChoice: Int32] = [:]
	private var isDone = false
	
	@IBOutlet private weak var doneBtn: UIBarButtonItem!
	@IBOutlet private weak var nextBtn: UIBarButtonItem!
	
	private var acceptBtn: UIBarButtonItem! {
		return [doneBtn, nextBtn].compactMap { $0 }.first
	}
	
	@IBOutlet private weak var choiceLbl: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

		if n == choices.count - 1 {
			navigationItem.rightBarButtonItems = [doneBtn]
			nextBtn = nil
		} else {
			navigationItem.rightBarButtonItems = [nextBtn]
			doneBtn = nil
		}
		
		choiceLbl.text = String(format: GTLocalizedString("ASK_CHOICE\(choices.count > 1 ? "S" : "")", comment: "x/y"), n + 1, choices.count)
		if n > 0 {
			navigationItem.leftBarButtonItem = nil
		}
		
		let ch = choices[n]
		let count = Int32(ch.exercizes.count)
		choice = min(ch.lastChosen, count - 1)
		choice = choice >= 0 ? (choice + 1) % count : nil
		
		updateButtons()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if !isDone, navigationController?.isBeingDismissed ?? false {
			appDelegate.cancelStartup()
		}
	}
	
	private func updateButtons() {
		acceptBtn.isEnabled = choice != nil
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return choices[n].exercizes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exercize", for: indexPath)

		let i = Int32(indexPath.row)
		let ch = choices[n][i]!
        cell.textLabel?.text = ch.title
		cell.detailTextLabel?.text = ch.summary
		cell.accessoryType = choice == i ? .checkmark : .none

        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		if let old = choice {
			tableView.cellForRow(at: IndexPath(row: Int(old), section: 0))?.accessoryType = .none
		}
		
		choice = Int32(indexPath.row)
		tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		
		updateButtons()
	}

	
    // MARK: - Navigation
	
	@IBAction func cancel() {
		self.dismiss(animated: true)
	}
	
	@IBAction func done() {
		isDone = true
		appDelegate.reportChoices(otherChoices + [choices[n]: choice])
		
		cancel()
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "next", let ask = segue.destination as? AskChoiceTableViewController else {
			return
		}
		
		ask.choices = choices
		ask.n = n + 1
		ask.otherChoices = otherChoices + [choices[n]: choice]
    }

}
