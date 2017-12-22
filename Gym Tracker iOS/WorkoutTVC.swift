//
//  WorkoutTableViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 13/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class WorkoutTableViewController: UITableViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
	
	weak var delegate: WorkoutListTableViewController!
	weak var exercizeController: ExercizeTableViewController?
	var workout: OrganizedWorkout!
	var editMode = false
	private var circuitInvalidityCache: Set<Int>!
	private(set) var isNew = false
	
	@IBOutlet var cancelBtn: UIBarButtonItem!
	@IBOutlet var doneBtn: UIBarButtonItem!
	private var startBtn: UIBarButtonItem!
	private var editBtn: UIBarButtonItem!
	
	private var deletedEntities = [DataObject]()
	private var reorderLbl = NSLocalizedString("REORDER_EXERCIZE", comment: "Reorder")
	private var doneReorderLbl = NSLocalizedString("DONE_REORDER_EXERCIZE", comment: "Done Reorder")

    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 44

		// Create a new workout
		if editMode && workout == nil {
			workout = OrganizedWorkout(appDelegate.dataManager.newWorkout())
			isNew = true
		}
		
		startBtn = UIBarButtonItem(title: NSLocalizedString("START_WORKOUT", comment: "Start"), style: .done, target: self, action: #selector(startWorkout))
		editBtn = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit(_:)))
		
		// The view is already in edit mode
		if !editMode {
			updateButtons()
		} else {
			updateValidityAndButtons()
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func updateButtons(includeDeleteArchive: Bool = false) {
		navigationItem.leftBarButtonItem = editMode ? cancelBtn : nil
		navigationItem.rightBarButtonItems = editMode
			? [doneBtn]
			: ( (workout?.archived ?? true)
				? [editBtn]
				: [startBtn, editBtn]
			)
		
		editBtn.isEnabled = delegate.canEdit
		startBtn.isEnabled = delegate.canEdit
		if includeDeleteArchive {
			tableView.reloadSections([2], with: .none)
		}
	}
	
	private func updateValidityAndButtons(doUpdateTable: Bool = true) {
		guard !(self.navigationController?.isBeingDismissed ?? false) else {
			// Cancelling creation, nothing to do
			return
		}
		
		workout.purgeInvalidSettings()
		let (global, circuit) = workout.validityStatus
		doneBtn.isEnabled = global
		circuitInvalidityCache = circuit
		
		if doUpdateTable {
			tableView.reloadRows(at: workout.exercizes.filter { !$0.isRest }.map { self.exercizeCellIndexPath(for: $0) }, with: .automatic)
		}
	}
	
	@objc func startWorkout() {
		guard delegate.canEdit && !isNew else {
			return
		}
		
		appDelegate.startWorkout(workout)
	}
	
	func updateView() {
		tableView.reloadData()
		
		exercizeController?.updateView()
	}

    // MARK: - Table view data source
	
	private enum ExercizeCellType {
		case exercize, rest, picker
	}

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 1 {
			return NSLocalizedString("EXERCIZES", comment: "Exercizes")
		}
		
		return nil
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if editMode && section == 1 {
			return NSLocalizedString("EXERCIZE_MANAGEMENT_TIP", comment: "Remove exercize")
		}
		
		return nil
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 1 && workout.count > 0 && exercizeCellType(for: indexPath) == .picker {
			return 150
		} else if indexPath.section == 0 && !editMode {
			return UITableViewAutomaticDimension
		}
		
		return tableView.estimatedRowHeight
	}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
		case 1:
			return max(workout.count, 1) + (editRest != nil ? 1 : 0)
		case 2:
			return 1
		default:
			return 0
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			if editMode {
				let cell = tableView.dequeueReusableCell(withIdentifier: "editTitle", for: indexPath) as! SingleFieldCell
				cell.textField.text = workout.name
				return cell
			} else {
				let cell = tableView.dequeueReusableCell(withIdentifier: "title", for: indexPath) as! MultilineCell
				cell.isUserInteractionEnabled = false
				cell.label.text = workout.name
				return cell
			}
		case 1:
			if workout.count == 0 {
				return tableView.dequeueReusableCell(withIdentifier: "noExercize", for: indexPath)
			}
			
			let e = workout[exercizeNumber(for: indexPath)]!
			switch exercizeCellType(for: indexPath) {
			case .rest:
				let cell = tableView.dequeueReusableCell(withIdentifier: "rest", for: indexPath) as! RestCell
				cell.set(rest: e.rest)
				cell.isUserInteractionEnabled = editMode
				
				return cell
			case .exercize:
				if circuitInvalidityCache == nil {
					updateValidityAndButtons(doUpdateTable: false)
				}
				
				let cell = tableView.dequeueReusableCell(withIdentifier: "exercize", for: indexPath) as! ExercizeTableViewCell
				cell.setInfo(for: e, circuitInfo: workout.circuitStatus(for: e))
				cell.setValidity(circuitInvalidityCache.index(of: Int(e.order)) == nil)
				
				return cell
			case .picker:
				let cell = tableView.dequeueReusableCell(withIdentifier: "restPicker", for: indexPath) as! RestPickerCell
				cell.picker.selectRow(Int(ceil(e.rest / 30) - 1), inComponent: 0, animated: false)
				
				return cell
			}
		case 2:
			if editMode {
				let cell = tableView.dequeueReusableCell(withIdentifier: "add", for: indexPath) as! WorkoutManageExercizeCell
				cell.reorderBtn.setTitle(self.isEditing ? doneReorderLbl : reorderLbl, for: [])
				
				return cell
			} else {
				let cell = tableView.dequeueReusableCell(withIdentifier: "actions", for: indexPath) as! WorkoutDeleteArchiveCell
				let title = (workout.archived ? "UN" : "") + "ARCHIVE_WORKOUT"
				cell.archiveBtn.setTitle(NSLocalizedString(title, comment: "(Un)archive"), for: [])
				cell.archiveBtn.isEnabled = delegate.canEdit
				cell.deleteBtn.isEnabled = delegate.canEdit
				
				return cell
			}
		default:
			fatalError("Unknown section")
		}
    }
	
	// MARK: - Editing
	
	@objc func edit(_ sender: AnyObject) {
		guard delegate.canEdit else {
			return
		}
		
		editMode = true
		navigationController?.interactivePopGestureRecognizer?.isEnabled = false
		appDelegate.tabController.isPopToWorkoutListRootEnabled = false
		updateButtons()
		
		tableView.reloadSections([0, 1, 2], with: .automatic)
	}
	
	private func exitEdit() {
		editMode = false
		deletedEntities.removeAll()
		navigationController?.interactivePopGestureRecognizer?.isEnabled = true
		appDelegate.tabController.isPopToWorkoutListRootEnabled = true
		if exercizeController != nil {
			_ = navigationController?.popToViewController(self, animated: true)
		}
		updateButtons()
		editRest = nil
		
		self.setEditing(false, animated: false)
		tableView.reloadSections([0, 1, 2], with: .automatic)
	}
	
	@IBAction func saveEdit(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		if let rest = editRest {
			//Simulate tap on rest row to hide picker
			self.tableView(tableView, didSelectRowAt: IndexPath(row: rest, section: 1))
		}
		
		if workout.count > 0 {
			tableView.beginUpdates()
			
			let totExercizeRows = tableView.numberOfRows(inSection: 1)
			let (s, e, m) = workout.compactExercizes()
			deletedEntities += (s + e + m.map { $0.e } ) as [DataObject]
			var removeRows = [IndexPath]()
			
			for i in 0 ..< s.count {
				removeRows.append(IndexPath(row: i, section: 1))
			}
			for i in totExercizeRows - e.count ..< totExercizeRows {
				removeRows.append(IndexPath(row: i, section: 1))
			}
			for (_, r) in m {
				removeRows.append(IndexPath(row: r, section: 1))
			}
			
			tableView.deleteRows(at: removeRows, with: .automatic)
			tableView.endUpdates()
			updateValidityAndButtons()
		}
		
		guard doneBtn.isEnabled else {
			return
		}
		
		let changes = [workout.raw as DataObject]
			+ workout.exercizes.map { [$0 as DataObject] + Array($0.sets) as [DataObject] }.reduce([]) { $0 + $1 }
		if appDelegate.dataManager.persistChangesForObjects(changes, andDeleteObjects: deletedEntities) {
			if isNew {
				delegate.updateWorkout(workout.raw, how: .new, wasArchived: false)
				self.dismiss(animated: true)
			} else {
				delegate.updateWorkout(workout.raw, how: .edit, wasArchived: workout.archived)
				exitEdit()
			}
		} else {
			self.present(UIAlertController(simpleAlert: NSLocalizedString("WORKOUT_SAVE_ERR", comment: "Cannot save"), message: nil), animated: true)
		}
	}
	
	func markAsDeleted(_ obj: [DataObject]) {
		guard editMode else {
			return
		}
		
		deletedEntities += obj
	}
	
	@IBAction func newExercize(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		tableView.beginUpdates()
		if workout.count == 0 {
			tableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
		}
		
		let e = appDelegate.dataManager.newExercize(for: workout.raw)
		e.set(name: nil)
		
		tableView.insertRows(at: [IndexPath(row: Int(e.order), section: 1)], with: .automatic)
		tableView.endUpdates()
		performSegue(withIdentifier: "exercizeDetail", sender: e)
	}
	
	func exercizeUpdated(_ e: Exercize) {
		precondition(e.workout == workout.raw, "Exercize is not from current workout")
		
		deletedEntities += e.compactSets() as [DataObject]
	
		if !e.isValid {
			removeExercize(e)
		}
		
		updateValidityAndButtons()
	}
	
	private func removeExercize(_ e: Exercize) {
		let index = IndexPath(row: Int(e.order), section: 1)
		// No need to also mark the sets as removed: if they are new there is no need to send them, else they will be deleted in cascade with the exercize.
		deletedEntities.append(e)
		workout.removeExercize(e)
		
		tableView.beginUpdates()
		tableView.deleteRows(at: [index], with: .automatic)
		
		if workout.isEmpty {
			tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
		}
		
		if let rest = editRest, rest == Int(e.order) {
			editRest = nil
			tableView.deleteRows(at: [IndexPath(row: index.row + 1, section: 1)], with: .fade)
		}
		
		tableView.endUpdates()
		
		DispatchQueue.main.async {
			self.updateValidityAndButtons()
		}
	}
	
	@IBAction func deleteWorkout(_ sender: AnyObject) {
		guard !editMode, delegate.canEdit else {
			return
		}
		
		let confirm = UIAlertController(title: NSLocalizedString("DELETE_WORKOUT", comment: "Del"), message: NSLocalizedString("DELETE_WORKOUT_CONFIRM", comment: "Del confirm") + workout.name + "?", preferredStyle: .actionSheet)
		confirm.addAction(UIAlertAction(title: NSLocalizedString("DELETE", comment: "Del"), style: .destructive) { _ in
			let archived = self.workout.archived
			if appDelegate.dataManager.persistChangesForObjects([], andDeleteObjects: [self.workout.raw]) {
				self.delegate.updateWorkout(self.workout.raw, how: .delete, wasArchived: archived)
				_ = self.navigationController?.popViewController(animated: true)
			} else {
				appDelegate.dataManager.discardAllChanges()
				let alert = UIAlertController(simpleAlert: NSLocalizedString("DELETE_WORKOUT_FAIL", comment: "Err"), message: nil)
				self.present(alert, animated: true)
			}
		})
		confirm.addAction(UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
		
		self.present(confirm, animated: true)
	}
	
	@IBAction func archiveWorkout(_ sender: AnyObject) {
		guard !editMode, delegate.canEdit else {
			return
		}
		
		let errTitle = NSLocalizedString((workout.archived ? "UN" : "") + "ARCHIVE_WORKOUT_FAIL", comment: "(Un)archive fail")
		let archived = workout.archived
		workout.archived = !archived
		if appDelegate.dataManager.persistChangesForObjects([self.workout.raw], andDeleteObjects: []) {
			self.delegate.updateWorkout(self.workout.raw, how: .archiveChange, wasArchived: archived)
			self.updateButtons()
			tableView.reloadSections(IndexSet(integer: 2), with: .fade)
		} else {
			appDelegate.dataManager.discardAllChanges()
			let alert = UIAlertController(simpleAlert: errTitle, message: nil)
			self.present(alert, animated: true)
		}
	}
	
	// MARK: - Edit name
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}
	
	@IBAction func nameChanged(_ sender: UITextField) {
		workout.set(name: sender.text ?? "")
		updateValidityAndButtons()
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.text = workout.name
		updateValidityAndButtons()
	}
	
	// MARK: - Edit rest
	
	private var editRest: Int?
	
	private func exercizeNumber(for i: IndexPath) -> Int {
		var row = i.row
		
		if let r = editRest {
			if r + 1 == i.row {
				return r
			} else if r + 1 < row {
				row -= 1
			}
		}
		
		return row
	}
	
	private func exercizeCellType(for i: IndexPath) -> ExercizeCellType {
		var row = i.row
		
		if let r = editRest {
			if r + 1 == row {
				return .picker
			} else if r + 1 < row {
				row -= 1
			}
		}
		
		return workout[row]!.isRest ? .rest : .exercize
	}
	
	private func exercizeCellIndexPath(for e: Exercize) -> IndexPath {
		var i = IndexPath(row: Int(e.order), section: 1)
		
		if let r = editRest, r < i.row {
			i.row += 1
		}
		
		return i
	}
	
	@IBAction func newRest(_ sender: AnyObject) {
		guard editMode else {
			return
		}
		
		tableView.beginUpdates()
		if workout.isEmpty {
			tableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
		}
		
		let r = appDelegate.dataManager.newExercize(for: workout.raw)
		r.set(rest: 4 * 60)
		
		tableView.insertRows(at: [IndexPath(row: Int(r.order), section: 1)], with: .automatic)
		tableView.endUpdates()
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard editMode, !workout.isEmpty, indexPath.section == 1 && exercizeCellType(for: indexPath) == .rest else {
			return
		}
		let exNum = exercizeNumber(for: indexPath)
		
		tableView.beginUpdates()
		
		var onlyClose = false
		if let r = editRest {
			onlyClose = r == exNum
			tableView.deleteRows(at: [IndexPath(row: r + 1, section: 1)], with: .fade)
		}
		
		if onlyClose {
			editRest = nil
		} else {
			tableView.insertRows(at: [IndexPath(row: exNum + 1, section: 1)], with: .automatic)
			editRest = exNum
		}
		
		tableView.endUpdates()
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return Int(ceil(maxRest / 30))
	}
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		let color = UILabel.appearance().textColor ?? .black
		let txt = (TimeInterval(row + 1) * 30).getDuration(hideHours: true)
		
		return NSAttributedString(string: txt, attributes: [.foregroundColor : color])
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard let exN = editRest, let ex = workout[exN] else {
			return
		}
		
		ex.set(rest: TimeInterval(row + 1) * 30)
		tableView.reloadRows(at: [IndexPath(row: exN, section: 1)], with: .none)
	}
	
	// MARK: - Delete rest & exercize
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return editMode && indexPath.section == 1 && !workout.isEmpty && exercizeCellType(for: indexPath) != .picker
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		guard editingStyle == .delete else {
			return
		}
		
		let exN = exercizeNumber(for: indexPath)
		guard let e = workout[exN] else {
			return
		}
		
		removeExercize(e)
	}
	
	// MARK: - Reorder rest & exercize
	
	@IBAction func updateReorderMode(_ sender: AnyObject) {
		guard editMode && !workout.isEmpty else {
			return
		}
		
		if let rest = editRest {
			//Simulate tap on rest row to hide picker
			self.tableView(tableView, didSelectRowAt: IndexPath(row: rest, section: 1))
		}
		
		self.setEditing(!self.isEditing, animated: true)
		tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .none)
	}

	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return editMode && indexPath.section == 1 && !workout.isEmpty && exercizeCellType(for: indexPath) != .picker
	}
	
	override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
		if proposedDestinationIndexPath.section < 1 {
			return IndexPath(row: 0, section: 1)
		} else if proposedDestinationIndexPath.section > 1 {
			return IndexPath(row: workout.count - 1, section: 1)
		}
		
		return proposedDestinationIndexPath
	}
	
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		guard editMode && fromIndexPath.section == 1 && to.section == 1 && !workout.isEmpty else {
			return
		}
		
		workout.moveExercizeAt(number: fromIndexPath.row, to: to.row)
		DispatchQueue.main.async {
			self.updateValidityAndButtons()
		}
	}

    // MARK: - Navigation
	
	private var documentController: UIActivityViewController?
	
	@IBAction func cancel(_ sender: AnyObject) {
		cancel(sender, animated: true, animationCompletion: nil)
	}
	
	func cancel(_ sender: AnyObject, animated: Bool, animationCompletion: (() -> Void)?) {
		appDelegate.dataManager.discardAllChanges()
		
		if isNew {
			self.dismiss(animated: animated, completion: animationCompletion)
		} else {
			exitEdit()
		}
	}
	
	@IBAction func export(_ sender: UIButton) {
		let loading = UIAlertController.getModalLoading()
		present(loading, animated: true)
		DispatchQueue.background.async {
			if let path = appDelegate.dataManager.importExportManager.export(workout: self.workout.raw) {
				DispatchQueue.main.async {
					loading.dismiss(animated: true) {
						self.documentController = UIActivityViewController(activityItems: [path], applicationActivities: nil)
						self.documentController?.completionWithItemsHandler = { _, _, _, _ in
							self.documentController = nil
						}
						
						self.present(self.documentController!, animated: true)
					}
				}
			} else {
				DispatchQueue.main.async {
					loading.dismiss(animated: true) {
						self.present(UIAlertController(simpleAlert: NSLocalizedString("EXPORT_FAIL", comment: "Error"), message: nil), animated: true)
					}
				}
			}
		}
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case "exercizeDetail":
			let e: Exercize
			switch sender {
			case let send as Exercize:
				e = send
			case _ as UITableViewCell:
				guard let index = tableView.indexPathForSelectedRow, index.section == 1 else {
					fallthrough
				}
				
				guard let tmp = workout[index.row], !tmp.isRest else {
					fallthrough
				}
				
				e = tmp
			default:
				fatalError("Unable to determine exercize")
			}
			
			let dest = segue.destination as! ExercizeTableViewController
			dest.exercize = e
			dest.editMode = self.editMode
			dest.delegate = self
			self.exercizeController = dest
		default:
			break
		}
	}

}

// MARK: - Cells

class ExercizeTableViewCell: UITableViewCell {
	@IBOutlet private weak var stack: UIStackView!
	
	@IBOutlet private weak var name: UILabel!
	@IBOutlet private weak var exercizeInfo: UILabel!

	@IBOutlet private var circuitWarning: UIView!
	@IBOutlet private var circuitStatus: UIView!
	@IBOutlet private weak var circuitNumber: UILabel!
	
	private var isCircuit = false
	
	fileprivate func setInfo(for exercize: Exercize, circuitInfo: (number: Int, total: Int)?) {
		guard !exercize.isRest else {
			return
		}
		
		name.text = exercize.name
		exercizeInfo.text = exercize.setsSummary
		
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
	
	fileprivate func setValidity(_ valid: Bool) {
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
