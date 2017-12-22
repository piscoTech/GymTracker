//
//  UpdateWeightInterfaceController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 25/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import Foundation

class UpdateWeightInterfaceController: WKInterfaceController {
	
	private weak var delegate: ExecuteWorkoutController!
	private var set: RepsSet!
	
	private var sum = 0.0
	
	@IBOutlet weak var base: WKInterfaceLabel!
	@IBOutlet weak var plus: WKInterfaceLabel!
	@IBOutlet weak var minus: WKInterfaceLabel!
	@IBOutlet weak var add: WKInterfaceLabel!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
		// Configure interface objects here.
		guard let data = context as? UpdateWeightData else {
			self.dismiss()
			
			return
		}
		
		self.delegate = data.workoutController
		self.set = data.set
		self.sum = delegate.weightChange(for: set)
		
		base.setText(set.weight.toString())
		updateView()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
	
	private func addWeight(_ w: Double) {
		sum += w
		sum = sum < 0 ? max(sum, -set.weight) : sum
		updateView()
	}
	
	private func updateView() {
		if sum >= 0 {
			plus.setHidden(false)
			minus.setHidden(true)
		} else {
			plus.setHidden(true)
			minus.setHidden(false)
		}
		add.setText(abs(sum).toString())
	}
	
	@IBAction func done() {
		if sum != 0 {
			// Avoid unnecessary saves
			set.set(weight: sum + set.weight)
			if appDelegate.dataManager.persistChangesForObjects([set], andDeleteObjects: []) {
				delegate.setWeightChange(sum, for: set)
			} else {
				appDelegate.dataManager.discardAllChanges()
			}
		} else {
			delegate.setWeightChange(sum, for: set)
		}
		
		self.dismiss()
	}
	
	@IBAction func addHalf() {
		addWeight(0.5)
	}
	
	@IBAction func addOne() {
		addWeight(1)
	}
	
	@IBAction func addFive() {
		addWeight(5)
	}
	
	@IBAction func minusHalf() {
		addWeight(-0.5)
	}
	
	@IBAction func minusOne() {
		addWeight(-1)
	}
	
	@IBAction func minusFive() {
		addWeight(-5)
	}
	
}
