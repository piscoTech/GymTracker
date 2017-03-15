//
//  ExercizeTVC.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/11/2016.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class ExercizeTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
	
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
	
	private enum SetCellType {
		case reps, rest, picker
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 3
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 1 && setCell(for: indexPath) == .picker {
			return 150
		}
		
		return UITableViewAutomaticDimension
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return exercize.sets.count * 2 - 1 + (editRest != nil ? 1 : 0)
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
			let s = exercize.set(n: setNumber(for: indexPath))!
			switch setCell(for: indexPath) {
			case .rest:
				let cell = tableView.dequeueReusableCell(withIdentifier: "rest", for: indexPath) as! RestCell
				cell.set(rest: s.rest)
				
				return cell
			case .reps:
				let cell = tableView.dequeueReusableCell(withIdentifier: "set", for: indexPath) as! RepsSetCell
				cell.set = s
				
				return cell
			case .picker:
				let cell = tableView.dequeueReusableCell(withIdentifier: "restPicker", for: indexPath) as! RestPickerCell
				cell.picker.selectRow(Int(ceil(s.rest / 30)), inComponent: 0, animated: false)
				
				return cell
			}
		case 2:
			return tableView.dequeueReusableCell(withIdentifier: "add", for: indexPath)
		default:
			fatalError("Unknown section")
		}
	}
	
	// MARK: - Editing
	
	@IBAction func newSet(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		let s = dataManager.newSet(for: exercize)
		s.set(rest: 60)
	
		if let tmp = sender as? ExercizeTableViewController, tmp == self {
			return
		}
		
		insertSet(s)
	}
	
	@IBAction func cloneSet(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		var setList = exercize.setList
		guard let last = setList.popLast() else {
			return
		}
		
		let s = dataManager.newSet(for: exercize)
		s.set(reps: last.reps)
		s.set(weight: last.weight)
		last.set(rest: setList.last?.rest ?? last.rest)
		s.set(rest: last.rest)
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
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return indexPath.section == 1 && setCell(for: indexPath) == .reps
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		guard editingStyle == .delete else {
			return
		}
		
		let setN = setNumber(for: indexPath)
		guard let set = exercize.set(n: setN) else {
			return
		}
		
		var remove = [indexPath]
		var removeFade = [IndexPath]()
		
		if Int(setN) != exercize.sets.count - 1 {
			remove.append(IndexPath(row: indexPath.row + 1, section: 1))
		}
		
		if let rest = editRest, rest == Int(setN) {
			editRest = nil
			removeFade.append(IndexPath(row: indexPath.row + 2, section: 1))
		}
		
		exercize.removeSet(set)
		delegate.markAsDeleted([set])
		
		tableView.beginUpdates()
		tableView.deleteRows(at: remove, with: .automatic)
		tableView.deleteRows(at: removeFade, with: .fade)
		tableView.endUpdates()
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
	
	// MARK: - Edit rest
	
	private var editRest: Int?
	
	private func setNumber(for i: IndexPath) -> Int32 {
		var row = i.row
		
		if let r = editRest {
			if (r + 1) * 2 == row {
				return Int32(r)
			} else if (r + 1) * 2 < row {
				row -= 1
			}
		}
		
		return Int32(row / 2)
	}
	
	private func setCell(for i: IndexPath) -> SetCellType {
		var row = i.row
		
		if let r = editRest {
			if (r + 1) * 2 == row {
				return .picker
			} else if (r + 1) * 2 < row {
				row -= 1
			}
		}
		
		return row % 2 == 0 ? .reps : .rest
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard indexPath.section == 1 && setCell(for: indexPath) == .rest else {
			return
		}
		let setNum = setNumber(for: indexPath)
		
		tableView.beginUpdates()
		
		var onlyClose = false
		if let r = editRest {
			onlyClose = Int32(r) == setNum
			tableView.deleteRows(at: [IndexPath(row: (r + 1) * 2, section: 1)], with: .fade)
		}
		
		if onlyClose {
			editRest = nil
		} else {
			tableView.insertRows(at: [IndexPath(row: (Int(setNum) + 1) * 2, section: 1)], with: .automatic)
			editRest = Int(setNum)
		}
		
		tableView.endUpdates()
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return Int(ceil(maxRest / 30)) + 1
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return (TimeInterval(row) * 30).getDuration(hideHours: true)
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard let setN = editRest, let set = exercize.set(n: Int32(setN)) else {
			return
		}
		
		set.set(rest: TimeInterval(row) * 30)
		tableView.reloadRows(at: [IndexPath(row: setN * 2 + 1, section: 1)], with: .none)
	}

}
