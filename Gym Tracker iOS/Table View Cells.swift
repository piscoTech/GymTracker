//
//  Table View Cells.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import GymTrackerCore

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

class ExercizeTableViewCell: UITableViewCell {
	@IBOutlet private weak var stack: UIStackView!
	
	@IBOutlet private weak var name: UILabel!
	@IBOutlet private weak var exercizeInfo: UILabel!
	
	@IBOutlet private var circuitWarning: UIView!
	@IBOutlet private var circuitStatus: UIView!
	@IBOutlet private weak var circuitNumber: UILabel!
	
	private var isCircuit = false
	
	func setInfo(for exercize: GTExercize, circuitInfo: (number: Int, total: Int)?) {
		name.text = exercize.title
		exercizeInfo.text = exercize.summary
		
		circuitWarning.removeFromSuperview()
		if let (n, t) = circuitInfo {
			isCircuit = true
			stack.addArrangedSubview(circuitStatus)
			circuitNumber.text = "\(n)/\(t)"
		} else {
			isCircuit = false
			circuitStatus.removeFromSuperview()
		}
	}
	
	func setValidity(_ valid: Bool) {
		if valid {
			circuitWarning.removeFromSuperview()
			if isCircuit {
				stack.addArrangedSubview(circuitStatus)
			}
		} else {
			circuitStatus.removeFromSuperview()
			stack.addArrangedSubview(circuitWarning)
		}
	}
	
}

class SetCell: UITableViewCell, UITextFieldDelegate {
	
	@IBOutlet weak var repsCount: UITextField!
	@IBOutlet weak var weight: UITextField!
	
	var set: GTSet! {
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
		self.repsCount.text = set.mainInfo > 0 ? "\(set.mainInfo)" : ""
		self.weight.text = set.secondaryInfo > 0 ? set.secondaryInfo.toString() : ""
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
			set.set(mainInfo: Int(sender.text ?? "") ?? 0)
		case weight:
			set.set(secondaryInfo: sender.text?.toDouble() ?? 0)
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

class AddExercizeCell: UITableViewCell {
	
	@IBOutlet weak var addExercize: UIButton!
	@IBOutlet weak var addOther: UIButton!
	@IBOutlet weak var addExistent: UIButton!
	
}

class WorkoutDeleteArchiveCell: UITableViewCell {
	
	@IBOutlet weak var archiveBtn: UIButton!
	@IBOutlet weak var deleteBtn: UIButton!
	
}

class LoadMoreCell: UITableViewCell {
	
	@IBOutlet private weak var loadIndicator: UIActivityIndicatorView!
	@IBOutlet private weak var loadBtn: UIButton!
	
	var isEnabled: Bool {
		get {
			return loadBtn.isEnabled
		}
		set {
			loadBtn.isEnabled = newValue
			loadIndicator.isHidden = newValue
			if !newValue {
				loadIndicator.startAnimating()
			} else {
				loadIndicator.stopAnimating()
			}
		}
	}
	
}
