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
	@IBOutlet private weak var accessory: WKInterfaceImage!
	@IBOutlet private weak var mainContent: WKInterfaceObject!
	
	var accessoryWidth: CGFloat = 0

	func setAccessory(_ image: UIImage?) {
		accessory.setImage(image)
	}
	
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

class ExerciseCell: AccessoryCell {

	@IBOutlet private weak var collectionImage: WKInterfaceImage!
	@IBOutlet private weak var collectionLabel: WKInterfaceLabel!
	
	static private let font = UIFont.systemFont(ofSize: 16)
	static private let italicFont = UIFont.italicSystemFont(ofSize: 16)
	
	private var isChoice = false
	
	func set(title: String) {
		titleLabel.setAttributedText(NSAttributedString(string: title, attributes: [.font: Self.font]))
	}
	
	func setCircuit(number: Int, total: Int) {
		collectionImage.setImageNamed(isChoice ? "IsChoiceCircuit" : "IsCircuit")
		collectionLabel.setText("\(number)/\(total)")
		showAccessory(true)
	}
	
	func setChoice(title: String, total: Int) {
		isChoice = true
		titleLabel.setAttributedText(NSAttributedString(string: title, attributes: [.font: Self.italicFont]))
		collectionImage.setImageNamed("IsChoice")
		collectionLabel.setText(total.description)
		showAccessory(true)
	}
	
}

class RestCell: NSObject {
	
	@IBOutlet weak var restLabel: WKInterfaceLabel!
	
	func set(rest r: TimeInterval) {
		restLabel.setText(String(format: GTLocalizedString("%@_REST", comment: "rest"), r.formattedDuration))
	}
	
}
