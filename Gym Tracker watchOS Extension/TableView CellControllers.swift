//
//  TableView CellControllers.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 21/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import WatchKit

class BasicDetailCell: NSObject {
	
	@IBOutlet var titleLabel: WKInterfaceLabel!
	@IBOutlet var detailLabel: WKInterfaceLabel!
	
}

class RestCell: NSObject {
	
	@IBOutlet weak var restLabel: WKInterfaceLabel!
	
	func setRest(_ r: TimeInterval) {
		restLabel.setText("\(r.getDuration(hideHours: true)) \(NSLocalizedString("REST", comment: "rest").lowercased())")
	}
	
}
