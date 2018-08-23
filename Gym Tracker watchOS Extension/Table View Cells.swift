//
//  Table View Cells.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import GymTrackerCore

class AccessoryCell: NSObject {
	
	@IBOutlet weak var titleLabel: WKInterfaceLabel!
	@IBOutlet weak var detailLabel: WKInterfaceLabel!
	@IBOutlet private weak var accessory: WKInterfaceObject!
	@IBOutlet private weak var mainContent: WKInterfaceObject!
	
	var accessoryWidth: CGFloat = 0
	
	func showAccessory(_ visible: Bool) {
		if visible {
			accessory.setHidden(false)
			mainContent.setRelativeWidth(1, withAdjustment: -accessoryWidth - 1)
		} else {
			accessory.setHidden(true)
			mainContent.setRelativeWidth(1, withAdjustment: 0)
		}
	}
	
}

class ExercizeCell: AccessoryCell {

	@IBOutlet private weak var collectionImage: WKInterfaceImage!
	@IBOutlet private weak var collectionLabel: WKInterfaceLabel!
	
	static private let font = UIFont.systemFont(ofSize: 16)
	static private let italicFont = UIFont.italicSystemFont(ofSize: 16)
	
	func set(title: String) {
		titleLabel.setAttributedText(NSAttributedString(string: title, attributes: [.font: ExercizeCell.font]))
	}
	
	func setCircuit(number: Int, total: Int) {
		collectionImage.setImageNamed("IsCircuit")
		collectionLabel.setText("\(number)/\(total)")
		showAccessory(true)
	}
	
	func setChoice(title: String, total: Int) {
		titleLabel.setAttributedText(NSAttributedString(string: title, attributes: [.font: ExercizeCell.italicFont]))
		collectionImage.setImageNamed("IsChoice")
		collectionLabel.setText(total.description)
		showAccessory(true)
	}
	
}

class RestCell: NSObject {
	
	@IBOutlet weak var restLabel: WKInterfaceLabel!
	
	func setRest(_ r: TimeInterval) {
		restLabel.setText("\(r.getDuration(hideHours: true)) \(GTLocalizedString("REST", comment: "rest").lowercased())")
	}
	
}
