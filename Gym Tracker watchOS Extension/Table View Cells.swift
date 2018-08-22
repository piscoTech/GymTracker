//
//  Table View Cells.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit
import GymTrackerCore

class BasicDetailCell: NSObject {
	
	@IBOutlet private weak var titleLabel: WKInterfaceLabel!
	@IBOutlet weak var detailLabel: WKInterfaceLabel!
	@IBOutlet private weak var collectionImage: WKInterfaceImage!
	@IBOutlet private weak var collectionLabel: WKInterfaceLabel!
	
	static private let font = UIFont.systemFont(ofSize: 16)
	static private let italicFont = UIFont.italicSystemFont(ofSize: 16)
	
	func set(title: String) {
		titleLabel.setAttributedText(NSAttributedString(string: title, attributes: [.font: BasicDetailCell.font]))
	}
	
	func setCircuit(number: Int, total: Int) {
		collectionImage.setImageNamed("IsCircuit")
		collectionLabel.setText("\(number)/\(total)")
	}
	
	func setChoice(title: String, total: Int) {
		titleLabel.setAttributedText(NSAttributedString(string: title, attributes: [.font: BasicDetailCell.italicFont]))
		collectionImage.setImageNamed("IsChoice")
		collectionLabel.setText(total.description)
	}
	
}

class RestCell: NSObject {
	
	@IBOutlet weak var restLabel: WKInterfaceLabel!
	
	func setRest(_ r: TimeInterval) {
		restLabel.setText("\(r.getDuration(hideHours: true)) \(GTLocalizedString("REST", comment: "rest").lowercased())")
	}
	
}
