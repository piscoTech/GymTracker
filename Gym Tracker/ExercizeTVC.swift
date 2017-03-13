//
//  ExercizeTVC.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 14/11/2016.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit

class ExercizeTableViewController: UITableViewController { //, UIPickerViewDelegate, UIPickerViewDataSource {
	
	var editMode = false
	var exercize: Exercize!
	weak var delegate: WorkoutTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	deinit {
		delegate.updateExercize(exercize)
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
