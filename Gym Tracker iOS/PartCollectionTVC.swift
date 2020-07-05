//
//  PartCollectionTableViewController.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 20/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import GymTrackerCore

@objc protocol PartCollectionController: AnyObject {
	
	func addDeletedEntities(_ del: [GTDataObject])
	func exerciseUpdated(_ e: GTPart)
	func updateView(global: Bool)
	func updateSecondaryInfoChange()
	func dismissPresentedController()
	
	var partCollection: GTDataObject { get }
	var tableView: UITableView! { get }
	var editMode: Bool { get }
	
	/// Enable or disable circuit rest for the collection if it's in a circuit and it allow so. After changing it reload section `1` of the table view.
	@objc func enableCircuitRest(_ s: UISwitch)
	
}

extension PartCollectionController {
	
	typealias CellInfo = (nib: String, identifier: String)
	
	var collectionDataId: CellInfo {
		return ("CollectionData", "collectionData")
	}
	
	func numberOfRowInHeaderSection() -> Int {
		var count = 0
		
		if let se = partCollection as? GTSetsExercise, se.isInCircuit {
			count += 1 + (se.allowCircuitRest ? 1 : 0)
		}
		
		return count + ((partCollection as? GTSimpleSetsExercise)?.isInChoice ?? false ? 1 : 0)
	}
	
	func headerCell(forRowAt indexPath: IndexPath, reallyAt realIndex: IndexPath? = nil) -> UITableViewCell {
		let real = realIndex ?? indexPath
		
		switch indexPath.row {
		case 0: // Circuit information
			guard let se = partCollection as? GTSetsExercise, let (n, t) = se.circuitStatus else {
				fallthrough
			}
			
			let cell = tableView.dequeueReusableCell(withIdentifier: collectionDataId.identifier, for: real)
			cell.accessoryView = nil
			cell.textLabel?.text = GTLocalizedString("IS_CIRCUIT", comment: "Circuit info")
			cell.detailTextLabel?.text = String(
				format: GTLocalizedString("COMPOSITE_INFO_%lld_OF_%lld", comment: "Exercise n/m"),
				n, t)
			
			return cell
		case 1:
			guard let se = partCollection as? GTSetsExercise, se.isInCircuit, se.allowCircuitRest else {
				fallthrough
			}
			
			let s = UISwitch()
			s.addTarget(self, action: #selector(enableCircuitRest(_:)), for: .valueChanged)
			s.isOn = se.hasCircuitRest
			s.isEnabled = editMode
			
			let cell = tableView.dequeueReusableCell(withIdentifier: collectionDataId.identifier, for: real)
			cell.accessoryView = s
			cell.textLabel?.text = GTLocalizedString("CIRCUITE_USE_REST", comment: "Use rest")
			cell.detailTextLabel?.text = nil
			
			return cell
		case 2:
			guard let e = partCollection as? GTSimpleSetsExercise, let (n, t) = e.choiceStatus else {
				fallthrough
			}
			
			let cell = tableView.dequeueReusableCell(withIdentifier: collectionDataId.identifier, for: real)
			cell.accessoryView = nil
			cell.textLabel?.text = GTLocalizedString("IS_CHOICE", comment: "Choice info")
			cell.detailTextLabel?.text = String(
				format: GTLocalizedString("COMPOSITE_INFO_%lld_OF_%lld", comment: "Exercise n/m"),
				n, t)
			
			return cell
		default:
			fatalError("Unknown row")
		}
	}
	
	private func updateCollectionCells() {
		let total = tableView.numberOfRows(inSection: 0)
		let collection = numberOfRowInHeaderSection()
		
		// The types of parent collections cannot change until you pop to their respective controller, so just reloading is fine
		tableView.reloadRows(at: ((total - collection) ..< total).map { IndexPath(row: $0, section: 0) }, with: .automatic)
	}
	
}

class PartCollectionTableViewController<T: GTDataObject>: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, PartCollectionController where T: ExerciseCollection {
	
	weak var delegate: WorkoutListTableViewController!
	weak var parentCollection: PartCollectionController?
	
	private weak var mover: UIViewController?
	private(set) weak var subCollection: PartCollectionController?
	private(set) weak var exerciseController: ExerciseTableViewController?
	
	var editMode = false
	var isNew: Bool {
		return false
	}
	final var canControlEdit: Bool {
		return parentCollection == nil
	}
	
	private var invalidityCache: Set<Int>!
	
	var cancelBtn: UIBarButtonItem?
	var doneBtn: UIBarButtonItem?
	private var editBtn: UIBarButtonItem?
	private var reorderBtn: UIBarButtonItem!
	var additionalRightButton: UIBarButtonItem? {
		return nil
	}

	private let reorderLbl = GTLocalizedString("REORDER_EXERCISE", comment: "Reorder")
	private let doneReorderLbl = GTLocalizedString("DONE_REORDER_EXERCISE", comment: "Done Reorder")
	private let additionalTip: String?
	
	var collection: T!
	var partCollection: GTDataObject {
		return collection
	}

	private var deletedEntities = [GTDataObject]()
	func addDeletedEntities(_ del: [GTDataObject]) {
		if let parent = parentCollection {
			parent.addDeletedEntities(del)
		} else {
			deletedEntities += del
		}
	}
	
	typealias CellInfo = PartCollectionController.CellInfo
	private let collectionDataId: CellInfo = ("CollectionData", "collectionData")
	private let noExercisesId: CellInfo = ("NoExercises", "noExercise")
	private let exerciseId: CellInfo = ("ExerciseTableViewCell", "exercise")
	private let restId: CellInfo = ("RestCell", "rest")
	private let restPickerId: CellInfo = ("RestPickerCell", "restPicker")
	private let addExerciseId: CellInfo = ("AddExerciseCell", "add")
	
	init(additionalTip: String? = nil) {
		self.additionalTip = additionalTip
		
		super.init(style: .grouped)
	}
	
	required init?(coder aDecoder: NSCoder) {
		additionalTip = nil
		
		super.init(coder: aDecoder)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		for (n, i) in [collectionDataId, noExercisesId, exerciseId, restId, restPickerId, addExerciseId] {
			tableView.register(UINib(nibName: n, bundle: Bundle.main), forCellReuseIdentifier: i)
		}

		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 44
		
		title = T.collectionType
		if #available(iOS 11.0, *) {
			navigationItem.largeTitleDisplayMode = .never
		}
		
		if canControlEdit {
			cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(doCancel))
			doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveEdit))
			editBtn = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
		}
		reorderBtn = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(updateReorderMode))
		
		updateButtons()
		if editMode {
			updateValidityAndButtons()
		}
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if self.isMovingFromParent {
			DispatchQueue.main.async {
				self.parentCollection?.exerciseUpdated(self.collection as! GTPart)
			}
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if editMode && canControlEdit {
			navigationController?.interactivePopGestureRecognizer?.isEnabled = false
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if editMode && canControlEdit {
			navigationController?.interactivePopGestureRecognizer?.isEnabled = true
			
			if navigationController?.isBeingDismissed ?? false {
				// Make sure the actual cancel action is triggered when swiping down to dismiss
				if self.presentationController != nil {
					self.cancel(animated: false, animationCompletion: nil)
				}
			}
		}
	}
	
	func updateButtons() {
		navigationItem.leftBarButtonItem = editMode ? cancelBtn : nil
		let right = (editMode
			? [doneBtn, reorderBtn]
			: [additionalRightButton, canControlEdit ? editBtn : nil]
			).compactMap { $0 }
		navigationItem.rightBarButtonItems = right
		
		editBtn?.isEnabled = delegate.canEdit
		reorderBtn.title = isEditing ? doneReorderLbl : reorderLbl
	}
	
	func updateValidityAndButtons(doUpdateTable: Bool = true) {
		guard !(self.navigationController?.isBeingDismissed ?? false) else {
			// Cancelling creation, nothing to do
			return
		}
		
		addDeletedEntities(collection.purge(onlySettings: true))
		invalidityCache = Set(collection.exercises.lazy.filter { !$0.isValid }.map { Int($0.order) })
		invalidityCache.formUnion((collection as? GTCircuit)?.exercisesError ?? [])
		invalidityCache.formUnion((collection as? GTChoice)?.inCircuitExercisesError ?? [])
		doneBtn?.isEnabled = collection.isPurgeableToValid
		
		if doUpdateTable {
			tableView.reloadRows(at: collection.exerciseList.lazy.filter { $0 is GTExercise }.map { self.exerciseCellIndexPath(for: $0) }, with: .automatic)
		}
	}
	
	func updateView(global: Bool = false) {
		if global {
			if let p = parentCollection {
				p.updateView(global: global)
				return
			} else {
				addDeletedEntities(collection.removePurgeable())
			}
		}
		
		updateValidityAndButtons(doUpdateTable: false)
		tableView.reloadData()
		
		subCollection?.updateView(global: false)
		exerciseController?.updateView()
	}
	
	func updateSecondaryInfoChange() {
		subCollection?.updateSecondaryInfoChange()
		exerciseController?.updateSecondaryInfoChange()
		
		tableView.reloadSections([mainSectionIndex], with: .automatic)
	}

    // MARK: - Table view data source
	
	private enum ExerciseCellType {
		case exercise, rest, picker
	}
	
	var mainSectionIndex: Int {
		return numberOfRowInHeaderSection() > 0 ? 1 : 0
	}

    override func numberOfSections(in tableView: UITableView) -> Int {
		return mainSectionIndex + (editMode ? 2 : 1)
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == mainSectionIndex {
			return GTLocalizedString("EXERCISES", comment: "Exercises")
		}
		
		return nil
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if editMode && section == mainSectionIndex {
			var tip = GTLocalizedString("EXERCISE_MANAGEMENT_TIP", comment: "Remove exercise")
			if let addTip = additionalTip {
				tip += "\n\(addTip)"
			}
			
			return tip
		}
		
		return nil
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == mainSectionIndex && collection.exercises.count > 0 && exerciseCellType(for: indexPath) == .picker {
			return 150
		}
		
		return tableView.estimatedRowHeight
	}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case mainSectionIndex:
			return max(collection.exercises.count, 1) + (editRest != nil ? 1 : 0)
		case mainSectionIndex + 1:
			return 1
		case 0:
			return numberOfRowInHeaderSection()
		default:
			return 0
		}
    }

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case mainSectionIndex:
			if collection.exercises.isEmpty {
				return tableView.dequeueReusableCell(withIdentifier: noExercisesId.identifier, for: indexPath)
			}
			
			let p = collection[Int32(exerciseNumber(for: indexPath))]!
			switch exerciseCellType(for: indexPath) {
			case .rest:
				let cell = tableView.dequeueReusableCell(withIdentifier: restId.identifier, for: indexPath) as! RestCell
				let r = p as! GTRest
				cell.set(rest: r.rest)
				cell.isUserInteractionEnabled = editMode
				
				return cell
			case .exercise:
				if invalidityCache == nil {
					updateValidityAndButtons(doUpdateTable: false)
				}
				
				let cell = tableView.dequeueReusableCell(withIdentifier: exerciseId.identifier, for: indexPath) as! ExerciseTableViewCell
				let e = p as! GTExercise
				cell.setInfo(for: e)
				cell.setValidity(!invalidityCache.contains(Int(e.order)))
				
				return cell
			case .picker:
				let cell = tableView.dequeueReusableCell(withIdentifier: restPickerId.identifier, for: indexPath) as! RestPickerCell
				let r = p as! GTRest
				cell.picker.delegate = self
				cell.picker.dataSource = self
				cell.picker.selectRow(Int(ceil(r.rest / GTRest.restStep) - 1), inComponent: 0, animated: false)
				
				return cell
			}
		case mainSectionIndex + 1:
			let cell = tableView.dequeueReusableCell(withIdentifier: addExerciseId.identifier, for: indexPath) as! AddExerciseCell
			cell.addExercise.addTarget(self, action: #selector(newExercise), for: .primaryActionTriggered)
			
			if handleableTypes().count == 1 {
				cell.addOther.isHidden = true
			} else {
				cell.addOther.isHidden = false
				cell.addOther.addTarget(self, action: #selector(newChoose), for: .primaryActionTriggered)
			}
			
			cell.addExistent.addTarget(self, action: #selector(moveExercises), for: .primaryActionTriggered)
			
			return cell
		case 0:
			return headerCell(forRowAt: indexPath)
		default:
			fatalError("Unknown section")
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard !collection.exercises.isEmpty, !self.isEditing, indexPath.section == mainSectionIndex else {
			return
		}
		
		switch exerciseCellType(for: indexPath) {
		case .rest:
			guard editMode else {
				break
			}
			
			self.editRest(at: indexPath)
		case .exercise:
			self.openExercise(collection[Int32(exerciseNumber(for: indexPath))]!)
		default:
			break
		}
	}
	
	private func reloadAllSections() {
		let old = tableView.numberOfSections
		let new = self.numberOfSections(in: tableView)
		
		tableView.beginUpdates()
		tableView.reloadSections(IndexSet(integersIn: 0 ..< min(old, new)), with: .automatic)
		
		if old < new {
			tableView.insertSections(IndexSet(integersIn: old ..< new), with: .automatic)
		} else if old > new {
			tableView.deleteSections(IndexSet(integersIn: new ..< old), with: .automatic)
		}
		tableView.endUpdates()
	}
	
	// MARK: - Editing
	
	@objc private func edit() {
		guard delegate.canEdit, canControlEdit else {
			return
		}
		
		editMode = true
		navigationController?.interactivePopGestureRecognizer?.isEnabled = false
		appDelegate.tabController.isPopToWorkoutListRootEnabled = false
		reorderBtn.title = reorderLbl
		updateButtons()
		
		reloadAllSections()
	}
	
	private func exitEdit() {
		if isNew {
			self.dismiss(animated: true)
		} else {
			tableView.beginUpdates()
			editMode = false
			deletedEntities.removeAll()
			navigationController?.interactivePopGestureRecognizer?.isEnabled = true
			appDelegate.tabController.isPopToWorkoutListRootEnabled = true
			_ = navigationController?.popToViewController(self, animated: true)
			updateButtons()
			editRest = nil
			
			self.setEditing(false, animated: false)
			reloadAllSections()
			tableView.endUpdates()
		}
	}
	
	@objc func saveEdit() -> Bool {
		guard editMode, canControlEdit else {
			return false
		}
		
		endEditRest()
		
		guard doneBtn?.isEnabled ?? false else {
			return false
		}
		
		addDeletedEntities(collection.purge())
		
		if appDelegate.dataManager.persistChangesForObjects(collection.subtreeNodes, andDeleteObjects: deletedEntities) {
			exitEdit()
			return true
		} else {
			self.present(UIAlertController(simpleAlert: GTLocalizedString("WORKOUT_SAVE_ERR", comment: "Cannot save"), message: nil), animated: true)
			tableView.reloadSections([mainSectionIndex], with: .automatic)
			return false
		}
	}
	
	private func canHandle(_ p: GTPart.Type) -> Bool {
		return p is T.Exercise.Type
	}
	
	private func handleableTypes() -> [(String, GTPart.Type)] {
		return [("CIRCUIT", GTCircuit.self), ("CHOICE", GTChoice.self), ("EXERCISE", GTSimpleSetsExercise.self), ("REST", GTRest.self)].filter { canHandle($0.1) }
	}
	
	@objc private func newChoose() {
		let choose = UIAlertController(title: GTLocalizedString("ADD_CHOOSE", comment: "Choose"), message: nil, preferredStyle: .actionSheet)
		
		for (n, t) in handleableTypes() {
			guard canHandle(t) else {
				continue
			}
			
			choose.addAction(UIAlertAction(title: GTLocalizedString(n, comment: "Type"), style: .default) { _ in
				self.newPart(of: t)
			})
		}
		
		choose.addAction(UIAlertAction(title: GTLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
		
		self.present(choose, animated: true)
	}
	
	@objc private func newExercise() {
		newPart(of: GTSimpleSetsExercise.self)
	}
	
	private func newPart(of type: GTPart.Type) {
		guard editMode, canHandle(type) else {
			return
		}
		
		endEditRest()
		
		tableView.beginUpdates()
		if collection.exercises.isEmpty {
			tableView.deleteRows(at: [IndexPath(row: 0, section: mainSectionIndex)], with: .automatic)
		}
		
		let p = appDelegate.dataManager.newPart(type) as! T.Exercise
		collection.add(parts: p)
		if let e = p as? GTSimpleSetsExercise {
			e.set(name: "")
		} else if let r = p as? GTRest {
			r.set(rest: 4 * 60)
		}
		
		tableView.insertRows(at: [IndexPath(row: Int(p.order), section: mainSectionIndex)], with: .automatic)
		tableView.endUpdates()
		openExercise(p)
		updateValidityAndButtons(doUpdateTable: false)
	}
	
	func exerciseUpdated(_ e: GTPart) {
		guard let p = e as? T.Exercise, collection.exercises.contains(p) else {
			return
		}
		
		addDeletedEntities(p.purge())
		if p.shouldBePurged {
			removeExercise(p)
		}

		DispatchQueue.main.async {
			self.updateValidityAndButtons()
		}
	}
	
	private func removeExercise(_ e: T.Exercise) {
		let index = IndexPath(row: Int(e.order), section: mainSectionIndex)
		addDeletedEntities([e])
		collection.remove(part: e)
		
		tableView.beginUpdates()
		tableView.deleteRows(at: [index], with: .automatic)
		
		if collection.exercises.isEmpty {
			tableView.insertRows(at: [IndexPath(row: 0, section: mainSectionIndex)], with: .automatic)
		}
		
		if let rest = editRest, rest == Int(e.order) {
			editRest = nil
			tableView.deleteRows(at: [IndexPath(row: index.row + 1, section: mainSectionIndex)], with: .fade)
		}
		
		tableView.endUpdates()
		
		DispatchQueue.main.async {
			self.updateValidityAndButtons()
		}
	}
	
	// MARK: - Edit circuit
	
	func enableCircuitRest(_ s: UISwitch) {
		guard editMode, let se = partCollection as? GTSetsExercise, se.isInCircuit, se.allowCircuitRest else {
			return
		}
		
		se.enableCircuitRest(s.isOn)
		s.isOn = se.hasCircuitRest
		tableView.reloadSections([mainSectionIndex], with: .automatic)
	}
	
	// MARK: - Edit rest
	
	private var editRest: Int?
	
	private func exerciseNumber(for i: IndexPath) -> Int {
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
	
	private func exerciseCellType(for i: IndexPath) -> ExerciseCellType {
		var row = i.row
		
		if let r = editRest {
			if r + 1 == row {
				return .picker
			} else if r + 1 < row {
				row -= 1
			}
		}
		
		return collection.exerciseList[row] is GTRest ? .rest : .exercise
	}
	
	private func exerciseCellIndexPath(for e: T.Exercise) -> IndexPath {
		var i = IndexPath(row: Int(e.order), section: mainSectionIndex)
		
		if let r = editRest, r < i.row {
			i.row += 1
		}
		
		return i
	}
	
	func endEditRest() {
		if let rest = editRest {
			//Simulate tap on rest row to hide picker
			self.tableView(tableView, didSelectRowAt: IndexPath(row: rest, section: mainSectionIndex))
		}
	}
	
	private func editRest(at indexPath: IndexPath) {
		let exNum = exerciseNumber(for: indexPath)
		
		tableView.beginUpdates()
		
		var onlyClose = false
		if let r = editRest {
			onlyClose = r == exNum
			tableView.deleteRows(at: [IndexPath(row: r + 1, section: mainSectionIndex)], with: .fade)
		}
		
		if onlyClose {
			editRest = nil
		} else {
			tableView.insertRows(at: [IndexPath(row: exNum + 1, section: mainSectionIndex)], with: .automatic)
			editRest = exNum
		}
		
		tableView.endUpdates()
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return Int(ceil(GTRest.maxRest / GTRest.restStep))
	}
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		if #available(iOS 13, *) {
			// Fallback to un-styled picker
			return nil
		} else {
			guard let title = self.pickerView(pickerView, titleForRow: row, forComponent: component) else {
				return nil
			}
			
			return NSAttributedString(string: title, attributes: [.foregroundColor : UIColor(named: "Text Color")!])
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return (TimeInterval(row + 1) * GTRest.restStep).formattedDuration
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard let exN = editRest, let rest = collection.exerciseList[exN] as? GTRest else {
			return
		}
		
		rest.set(rest: TimeInterval(row + 1) * GTRest.restStep)
		tableView.reloadRows(at: [IndexPath(row: exN, section: mainSectionIndex)], with: .none)
	}
	
	// MARK: - Delete exercises
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return editMode && indexPath.section == mainSectionIndex && !collection.exercises.isEmpty && exerciseCellType(for: indexPath) != .picker
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		guard editingStyle == .delete else {
			return
		}

		let exN = exerciseNumber(for: indexPath)
		guard let p = collection[Int32(exN)] else {
			return
		}

		removeExercise(p)
	}
	
	// MARK: - Reorder exercises
	
	@objc private func updateReorderMode() {
		guard editMode, !collection.exercises.isEmpty || self.isEditing else {
			return
		}

		endEditRest()

		self.setEditing(!self.isEditing, animated: true)
		reorderBtn.title = self.isEditing ? doneReorderLbl : reorderLbl
	}

	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return editMode && indexPath.section == mainSectionIndex && !collection.exercises.isEmpty && exerciseCellType(for: indexPath) != .picker
	}

	override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
		if proposedDestinationIndexPath.section < mainSectionIndex {
			return IndexPath(row: 0, section: mainSectionIndex)
		} else if proposedDestinationIndexPath.section > mainSectionIndex {
			return IndexPath(row: collection.exercises.count - 1, section: mainSectionIndex)
		}

		return proposedDestinationIndexPath
	}

	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		guard editMode && fromIndexPath.section == mainSectionIndex && to.section == mainSectionIndex && !collection.exercises.isEmpty else {
			return
		}

		collection.movePart(at: Int32(fromIndexPath.row), to: Int32(to.row))
		DispatchQueue.main.async {
			self.updateValidityAndButtons()
		}
	}

    // MARK: - Navigation
	
	@objc func doCancel() {
		cancel(animated: true, animationCompletion: nil)
	}
	
	func cancel(animated: Bool, animationCompletion: (() -> Void)?) {
		appDelegate.dataManager.discardAllChanges()
		
		dismissPresentedController()
		if isNew {
			self.dismiss(animated: animated, completion: animationCompletion)
		} else {
			exitEdit()
		}
	}
	
	func dismissPresentedController() {
		self.mover?.dismiss(animated: false)
		self.subCollection?.dismissPresentedController()
		self.exerciseController?.dismissPresentedController()
	}
	
	func openExercise(_ p: T.Exercise) {
		let circuitChoiceAdditionalTip = GTLocalizedString("EXERCISE_MANAGEMENT_CIRC_CHOICE_TIP", comment: "2 exercises")
		
		if let e = p as? GTSimpleSetsExercise {
			let dest = ExerciseTableViewController.instanciate()
			
			dest.exercise = e
			dest.editMode = self.editMode
			dest.delegate = self
			self.exerciseController = dest
			
			navigationController?.pushViewController(dest, animated: true)
		} else if p is GTRest {
			// No need to push anything else, edit is in place
		} else if let c = p as? GTCircuit {
			let dest = PartCollectionTableViewController<GTCircuit>(additionalTip: circuitChoiceAdditionalTip)
			
			self.subCollection = dest
			dest.parentCollection = self
			dest.editMode = editMode
			dest.collection = c
			
			navigationController?.pushViewController(dest, animated: true)
		} else if let ch = p as? GTChoice {
			let dest = PartCollectionTableViewController<GTChoice>(additionalTip: circuitChoiceAdditionalTip)
			
			self.subCollection = dest
			dest.parentCollection = self
			dest.editMode = editMode
			dest.collection = ch
			
			navigationController?.pushViewController(dest, animated: true)
		} else {
			fatalError("Unknown part type")
		}
	}
	
	@objc private func moveExercises() {
		let mover = MovePartTableViewController.initialize(currentPart: collection) {
			self.updateView(global: true)
		}
		self.mover = mover
		self.present(mover, animated: true)
	}

}
