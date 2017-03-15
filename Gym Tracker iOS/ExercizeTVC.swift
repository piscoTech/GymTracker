//
//  ExercizeTVC.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/11/2016.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class ExercizeTableViewController: UITableViewController, UITextFieldDelegate { //, UIPickerViewDelegate, UIPickerViewDataSource {
	
	var editMode = false
	var exercize: Exercize!
	weak var delegate: WorkoutTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		if exercize.sets.count == 0 {
			//This can only appen if it's a new exercize
			newSet(self)
		}
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if self.isMovingFromParentViewController {
			delegate.updateExercize(exercize)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return exercize.sets.count * 2 - 1
		case 2:
			return 1
		default:
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			let cell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath) as! SingleFieldCell
			cell.isEnabled = editMode
			cell.textField.text = exercize.name
			return cell
		case 1:
			let s = exercize.set(n: Int32(indexPath.row / 2))!
			let isRest = indexPath.row % 2 == 1
			if isRest {
				return tableView.dequeueReusableCell(withIdentifier: "rest", for: indexPath)
			} else {
				let cell = tableView.dequeueReusableCell(withIdentifier: "set", for: indexPath) as! RepsSetCell
				cell.set = s
				
				return cell
			}
		case 2:
			return tableView.dequeueReusableCell(withIdentifier: "add", for: indexPath)
		default:
			fatalError("Unknown section")
		}
	}
	
	// MARK: Editing
	
	@IBAction func newSet(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		let s = dataManager.newSet(for: exercize)
	
		if let tmp = sender as? ExercizeTableViewController, tmp == self {
			return
		}
		
		insertSet(s)
	}
	
	@IBAction func cloneSet(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		guard let last = exercize.setList.last else {
			return
		}
		
		let s = dataManager.newSet(for: exercize)
		s.set(reps: last.reps)
		s.set(weight: last.weight)
		insertSet(s)
	}
	
	private func insertSet(_ s: RepsSet) {
		let count = tableView(tableView, numberOfRowsInSection: 1)
		var rows = [IndexPath(row: count - 1, section: 1)]
		if count > 1 {
			rows.append(IndexPath(row: count - 2, section: 1))
		}
		
		tableView.insertRows(at: rows, with: .automatic)
	}
	
	// MARK: - Edit name
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}
	
	@IBAction func nameChanged(_ sender: UITextField) {
		exercize.set(name: sender.text ?? "")
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.text = exercize.name ?? ""
	}
	
//	func numberOfComponents(in pickerView: UIPickerView) -> Int {
//		switch pickerView {
//		case typePicker:
//			return 1
//		case restPicker:
//			return 3
//		case repPicker:
//			return 3
//		default:
//			preconditionFailure("Unknown picker")
//		}
//	}
//	
//	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//		switch pickerView {
//		case typePicker:
//			return 2
//		case restPicker:
//			switch component {
//			case 0:
//				return 11
//			case 1:
//				return 1
//			case 2:
//				return 2
//			default:
//				preconditionFailure("Unknown picker component")
//			}
//		case repPicker:
//			switch component {
//			case 0:
//				return 10
//			case 1:
//				return 1
//			case 2:
//				return 20
//			default:
//				preconditionFailure("Unknown picker component")
//			}
//		default:
//			preconditionFailure("Unknown picker")
//		}
//	}
	
//	func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
//		switch pickerView {
//		case typePicker:
//			return 1
//		case restPicker:
//			return 3
//		case repPicker:
//			return 3
//		case weightPicker:
//			return 2
//		default:
//			preconditionFailure("Unknown picker")
//		}
//	}
	
//	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//		switch pickerView {
//		case typePicker:
//			return ExercizeType(rawValue: row)?.description
//		case restPicker:
//			switch component {
//			case 0:
//				return "\(row)"
//			case 1:
//				return ":"
//			case 2:
//				return "\(row * 30)"
//			default:
//				preconditionFailure("Unknown picker component")
//			}
//		case repPicker:
//			switch component {
//			case 0:
//				return "\(row + 1)"
//			case 1:
//				return "×"
//			case 2:
//				return "\(row + 1)"
//			default:
//				preconditionFailure("Unknown picker component")
//			}
//		default:
//			preconditionFailure("Unknown picker")
//		}
//	}

}
