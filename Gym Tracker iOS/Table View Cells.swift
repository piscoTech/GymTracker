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
	
	static let heavyFont = UIFont.systemFont(ofSize: 20, weight: .heavy)
	static private(set) var normalFont: UIFont!
	
	@IBOutlet weak var label: UILabel! {
		didSet {
			if MultilineCell.normalFont == nil {
				MultilineCell.normalFont = label.font
			}
			
			label.font = MultilineCell.heavyFont
		}
	}
	
	func useNormalFont(_ normal: Bool = true) {
		label.font = normal ? MultilineCell.normalFont : MultilineCell.heavyFont
	}
	
}

class SingleFieldCell: UITableViewCell {

	@IBOutlet weak var textField: UITextField! {
		didSet {
			textField.font = MultilineCell.heavyFont
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
		if let curWrkt = appDelegate.workoutController, curWrkt.isManaging(exercize) {
			if #available(iOS 13, *) {
				// In iOS 12 and before there's a bug where the appearance color overrides the color of the attributed string
			} else {
				exercizeInfo.textColor = UIColor(named: "Text Color")
			}
			exercizeInfo.attributedText = exercize.summaryWithSecondaryInfoChange(from: curWrkt)
		} else {
			exercizeInfo.text = exercize.summary
		}
		
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
		self.repsCount.text = set.mainInfo > 0 || !isEnabled ? "\(set.mainInfo)" : ""
		if !isEnabled {
			if let curWrkt = appDelegate.workoutController, curWrkt.isManaging(set) {
				let ch = curWrkt.secondaryInfoChange(for: set)
				if #available(iOS 13, *) {
					// In iOS 12 and before there's a bug where the appearance color overrides the color of the attributed string
				} else {
					self.weight.textColor = UIColor(named: "Text Color")
				}
				self.weight.attributedText =  set.secondaryInfo.secondaryInfoDescriptionEvenForZero(withChange: ch)
			} else {
				self.weight.text = set.secondaryInfo.toString()
			}
		} else {
			self.weight.text = set.secondaryInfo > 0 ? set.secondaryInfo.toString() : ""
		}
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
	
	func set(rest r: TimeInterval) {
		self.textLabel?.text = String(format: GTLocalizedString("%@_REST", comment: "rest"), r.getFormattedDuration())
	}
	
}

class MoveExercizeCell: UITableViewCell {
	
	@IBOutlet weak var name: UILabel!
	@IBOutlet weak var exercizeInfo: UILabel!
	@IBOutlet private weak var left: NSLayoutConstraint!
	@IBOutlet private weak var invalidLbl: UILabel!
	
	private static var normalFont, italicFont, thinFont: UIFont!
	private static var invalidColor: UIColor = #colorLiteral(red: 0.4250687957, green: 0.4250687957, blue: 0.4250687957, alpha: 1)
	
	static private func createAspect(from label: UILabel) {
		guard normalFont == nil else {
			return
		}
		
		normalFont = label.font
		if let descr = normalFont.fontDescriptor.withSymbolicTraits(.traitItalic) {
			italicFont = UIFont(descriptor: descr, size: 0)
		}
		thinFont = UIFont.systemFont(ofSize: label.font.pointSize, weight: .ultraLight)
	}
	
	func setLevel(_ l: Int) {
		left.constant = max(CGFloat(l), 0) * 16
		self.setNeedsLayout()
	}
	
	func setInvalid(_ v: MovePartInvalidExercize?, isCollection: Bool) {
		MoveExercizeCell.createAspect(from: name)
		
		if let r = v {
			name.font = MoveExercizeCell.thinFont
			name.textColor = MoveExercizeCell.invalidColor
			exercizeInfo.textColor = MoveExercizeCell.invalidColor
			self.invalidLbl.isHidden = false
			self.invalidLbl.text = r.description
			self.accessoryType = .none
		} else {
			name.font = isCollection ? MoveExercizeCell.italicFont : MoveExercizeCell.normalFont
			let color: UIColor
			if #available(iOS 13.0, *) {
				color = .label
			} else {
				color = UIColor(named: "Text Color")!
			}
			name.textColor = color
			exercizeInfo.textColor = color
			self.invalidLbl.isHidden = true
		}
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
