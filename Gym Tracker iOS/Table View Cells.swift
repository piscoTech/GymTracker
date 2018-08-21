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
	
	@IBOutlet private weak var name: UILabel!
	@IBOutlet private weak var exercizeInfo: UILabel!
	
	@IBOutlet private weak var isInvalid: UIView!
	@IBOutlet private weak var collectionStatus: UIView!
	@IBOutlet private weak var isCircuit: UIView!
	@IBOutlet private weak var isChoice: UIView!
	@IBOutlet private weak var collectionCount: UILabel!
	
	private static var normalFont: UIFont!
	private static var italicFont: UIFont!
	
	func setInfo(for exercize: GTExercize) {
		if ExercizeTableViewCell.normalFont == nil {
			ExercizeTableViewCell.normalFont = name?.font
			if let font = ExercizeTableViewCell.normalFont?.fontDescriptor, let descr = font.withSymbolicTraits(.traitItalic) {
				ExercizeTableViewCell.italicFont = UIFont(descriptor: descr, size: 0)
			}
		}
		
		name.text = exercize.title
		name.font = exercize is GTSimpleSetsExercize ? ExercizeTableViewCell.normalFont : ExercizeTableViewCell.italicFont
		exercizeInfo.text = exercize.summary
		
		isCircuit.isHidden = true
		isChoice.isHidden = true
		if let c = exercize as? GTCircuit {
			isCircuit.isHidden = false
			collectionCount.text = c.exercizes.count.description
		}
		if let ch = exercize as? GTChoice {
			isChoice.isHidden = false
			collectionCount.text = ch.exercizes.count.description
		}
		collectionStatus.isHidden = isCircuit.isHidden && isChoice.isHidden
	}
	
	func setValidity(_ valid: Bool) {
		isInvalid.isHidden = valid
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
	
	@IBOutlet weak var exportBtn: UIButton!
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
