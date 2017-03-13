//
//  TableView Cells.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit

class SingleFieldCell: UITableViewCell {

	@IBOutlet weak var textField: UITextField!
	
	var isEnabled: Bool {
		get {
			return textField.isEnabled
		}
		set {
			textField.isEnabled = newValue
			textField.isUserInteractionEnabled = newValue
		}
	}

}
