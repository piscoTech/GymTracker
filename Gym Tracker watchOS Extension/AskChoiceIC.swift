//
//  AskChoiceInterfaceController.swift
//  Gym Tracker watchOS Extension
//
//  Created by Marco Boschi on 23/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import WatchKit
import MBLibrary
import GymTrackerCore

struct AskChoiceData {
	
	var choices: [GTChoice]
	var n: Int
	var otherChoices: [GTChoice: Int32]
	var delegate: ExecuteWorkoutInterfaceController
	
}

class AskChoiceInterfaceController: WKInterfaceController {
	
	private var data: AskChoiceData!
	private var choice: Int32!
	
	@IBOutlet private weak var choiceNum: WKInterfaceLabel!
	@IBOutlet private weak var table: WKInterfaceTable!
	@IBOutlet private weak var doneBtn: WKInterfaceButton!
	@IBOutlet private weak var nextBtn: WKInterfaceButton!
	
	private var acceptBtn: WKInterfaceButton! {
		return data.n == data.choices.count - 1 ? doneBtn : nextBtn
	}

	private var shouldCancel = true
	
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
		guard let data = context as? AskChoiceData else {
			self.dismiss()
			return
		}
		self.data = data
		
		reload()
	}
	
	private func reload() {
		if data.n == data.choices.count - 1 {
			nextBtn.setEnabled(false)
			nextBtn.setHidden(true)
			doneBtn.setHidden(false)
		} else {
			doneBtn.setEnabled(false)
			doneBtn.setHidden(true)
			nextBtn.setHidden(false)
		}
		
		choiceNum.setText(String(format: GTLocalizedString("ASK_CHOICES", comment: "x/y"), data.n + 1, data.choices.count))
		
		let ch = data.choices[data.n]
		let count = Int32(ch.exercises.count)
		choice = min(ch.lastChosen, count - 1)
		choice = choice >= 0 ? (choice + 1) % count : nil

		table.setNumberOfRows(Int(count), withRowType: "exercise")
		
		for i in 0 ..< Int(count) {
			guard let row = table.rowController(at: i) as? AccessoryCell else {
				continue
			}
			
			row.accessoryWidth = 20
			let e = ch[Int32(i)]!
			row.titleLabel.setText(e.title)
			row.detailLabel.setText(e.summary)
			
			row.showAccessory(Int32(i) == choice)
		}
		
		updateButtons()
    }
	
	override func didAppear() {
		super.didAppear()
		
		shouldCancel = true
	}

	override func willDisappear() {
		super.willDisappear()
		
		if shouldCancel {
			data.delegate.cancelStartup()
		}
	}
	
	private func updateButtons() {
		acceptBtn.setEnabled(choice != nil)
	}
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		if let old = choice {
			(table.rowController(at: Int(old)) as? AccessoryCell)?.showAccessory(false)
		}
		
		choice = Int32(rowIndex)
		(table.rowController(at: rowIndex) as? AccessoryCell)?.showAccessory(true)
		
		updateButtons()
	}
	
	@IBAction func nextChoice() {
		var ctx: AskChoiceData = data
		
		ctx.n += 1
		ctx.otherChoices += [data.choices[data.n]: choice]
		
		self.data = ctx
		reload()
	}
	
	@IBAction func reportChoices() {
		data.delegate.reportChoices(data.otherChoices + [data.choices[data.n]: choice])
		shouldCancel = false
		self.dismiss()
	}

}
