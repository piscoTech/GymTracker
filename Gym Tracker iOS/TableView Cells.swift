//
//  TableView Cells.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class MultilineCell: UITableViewCell {
	
	static let font = UIFont.systemFont(ofSize: 20, weight: .heavy)
	
	@IBOutlet weak var label: UILabel! {
		didSet {
			label.font = MultilineCell.font
		}
	}
	
}

class SingleFieldCell: UITableViewCell {

	@IBOutlet weak var textField: UITextField! {
		didSet {
			textField.font = MultilineCell.font
		}
	}

}

class RepsSetCell: UITableViewCell, UITextFieldDelegate {
	
	@IBOutlet weak var repsCount: UITextField!
	@IBOutlet weak var weight: UITextField!
	
	var set: RepsSet! {
		didSet {
			updateView()
		}
	}
	
	var isEnabled: Bool {
		get {
			return repsCount.isEnabled
		}
		set {
			repsCount.isEnabled = newValue
			repsCount.isUserInteractionEnabled = newValue
			weight.isEnabled = newValue
			weight.isUserInteractionEnabled = newValue
		}
	}
	
	private func updateView() {
		self.repsCount.text = set.reps > 0 ? "\(set.reps)" : ""
		self.weight.text = set.weight > 0 ? set.weight.toString() : ""
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let check = "[^0-9\(textField == weight ? "\\\(decimalPoint)" : "")]"
		
		return string.range(of: check, options: .regularExpression) == nil
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}
	
	@IBAction func valueChanged(_ sender: UITextField) {
		switch sender {
		case repsCount:
			set.set(reps: Int32(sender.text ?? "") ?? 0)
		case weight:
			set.set(weight: sender.text?.toDouble() ?? 0)
		default:
			fatalError("Unknown field")
		}
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		updateView()
	}
	
}

class RestPickerCell: UITableViewCell {
	
	@IBOutlet weak var picker: UIPickerView!
	
}

class RestCell: UITableViewCell {
	
	@IBOutlet weak var rest: UILabel!
	
	func set(rest: TimeInterval) {
		self.rest.text = rest.getDuration(hideHours: true)
	}
	
}

class WorkoutManageExercizeCell: UITableViewCell {
	
	@IBOutlet weak var reorderBtn: UIButton!
	
}

class WorkoutDeleteArchiveCell: UITableViewCell {
	
	@IBOutlet weak var archiveBtn: UIButton!
	@IBOutlet weak var deleteBtn: UIButton!
	
}
