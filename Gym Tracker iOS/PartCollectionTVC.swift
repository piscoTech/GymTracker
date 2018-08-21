//
//  PartCollectionTableViewController.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 20/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import GymTrackerCore

protocol PartCollectionController: AnyObject {
	
	func addDeletedEntities(_ del: [GTDataObject])
	func exercizeUpdated(_ e: GTPart)
	
}

class PartCollectionTableViewController<T: GTDataObject>: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, PartCollectionController where T: ExercizeCollection {
	
	weak var delegate: WorkoutListTableViewController!
	weak var parentCollection: PartCollectionTableViewController?
	
	private(set) weak var subCollection: PartCollectionTableViewController?
	private(set) weak var exercizeController: ExercizeTableViewController?
	
	var editMode = false
	var isNew: Bool {
		return false
	}
	final var canControlEdit: Bool {
		return parentCollection == nil
	}
	
	private var invalidityCache: Set<Int32>!
	
	var cancelBtn: UIBarButtonItem?
	var doneBtn: UIBarButtonItem?
	private var editBtn: UIBarButtonItem?
	private var reorderBtn: UIBarButtonItem!
	var additionalRightButton: UIBarButtonItem? {
		return nil
	}
	
	private let reorderLbl = GTLocalizedString("REORDER_EXERCIZE", comment: "Reorder")
	private let doneReorderLbl = GTLocalizedString("DONE_REORDER_EXERCIZE", comment: "Done Reorder")
	
	var collection: T!

	private var deletedEntities = [GTDataObject]()
	func addDeletedEntities(_ del: [GTDataObject]) {
		if let parent = parentCollection {
			parent.addDeletedEntities(del)
		} else {
			deletedEntities += del
		}
	}
	
	typealias CellInfo = (nib: String, identifier: String)
	private let collectionDataId: CellInfo = ("CollectionData", "collectionData")
	private let noExercizesId: CellInfo = ("NoExercizes", "noExercize")
	private let exercizeId: CellInfo = ("ExercizeTableViewCell", "exercize")
	private let restId: CellInfo = ("RestCell", "rest")
	private let restPickerId: CellInfo = ("RestPickerCell", "restPicker")
	private let addExercizeId: CellInfo = ("AddExercizeCell", "add")
	
	init() {
		super.init(style: .grouped)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		for (n, i) in [collectionDataId, noExercizesId, exercizeId, restId, restPickerId, addExercizeId] {
			tableView.register(UINib(nibName: n, bundle: Bundle.main), forCellReuseIdentifier: i)
		}

		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 44
		
		title = collection.collectionType
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
	
	func updateButtons(includeOthers: Bool = false) {
		navigationItem.leftBarButtonItem = editMode ? cancelBtn : nil
		navigationItem.rightBarButtonItems = (editMode
			? [doneBtn, reorderBtn]
			: [additionalRightButton, canControlEdit ? editBtn : nil]
			).compactMap { $0 }
		
		editBtn?.isEnabled = delegate.canEdit
	}
	
	func updateValidityAndButtons(doUpdateTable: Bool = true) {
		guard !(self.navigationController?.isBeingDismissed ?? false) else {
			// Cancelling creation, nothing to do
			return
		}
		
		addDeletedEntities(collection.purge(onlySettings: true))
		invalidityCache = Set(collection.exercizes.lazy.filter { !$0.isValid }.map { $0.order })
		#warning("Add invalidity for circuit (and circuit in choice)")
		doneBtn?.isEnabled = collection.isPurgeableToValid
		
		if doUpdateTable {
			tableView.reloadRows(at: collection.exercizeList.lazy.filter { $0 is GTExercize }.map { self.exercizeCellIndexPath(for: $0) }, with: .automatic)
		}
	}
	
	func updateView() {
		tableView.reloadData()
		
		subCollection?.updateView()
		exercizeController?.updateView()
	}

    // MARK: - Table view data source
	
	private enum ExercizeCellType {
		case exercize, rest, picker
	}

    override func numberOfSections(in tableView: UITableView) -> Int {
		return editMode ? 3 : 2
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 1 {
			return GTLocalizedString("EXERCIZES", comment: "Exercizes")
		}
		
		return nil
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 1 && collection.exercizes.count > 0 && exercizeCellType(for: indexPath) == .picker {
			return 150
		}
		
		return tableView.estimatedRowHeight
	}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 0
//				+ ((collection as? GTSetsExercize)?.isInCircuit ?? false ? 1 : 0)
//				+ ((collection as? GTSimpleSetsExercize)?.isInChoice ?? false ? 1 : 0)
		case 1:
			return max(collection.exercizes.count, 1) + (editRest != nil ? 1 : 0)
		case 2:
			return 1
		default:
			return 0
		}
    }

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			#warning("Handle circuit/choice")
			fatalError()
		case 1:
			if collection.exercizes.isEmpty {
				return tableView.dequeueReusableCell(withIdentifier: noExercizesId.identifier, for: indexPath)
			}
			
			let p = collection[Int32(exercizeNumber(for: indexPath))]!
			switch exercizeCellType(for: indexPath) {
			case .rest:
				let cell = tableView.dequeueReusableCell(withIdentifier: restId.identifier, for: indexPath) as! RestCell
				let r = p as! GTRest
				cell.set(rest: r.rest)
				cell.isUserInteractionEnabled = editMode
				
				return cell
			case .exercize:
				if invalidityCache == nil {
					updateValidityAndButtons(doUpdateTable: false)
				}
				
				let cell = tableView.dequeueReusableCell(withIdentifier: exercizeId.identifier, for: indexPath) as! ExercizeTableViewCell
				let e = p as! GTExercize
				cell.setInfo(for: e, circuitInfo: nil)
				cell.setValidity(!invalidityCache.contains(e.order))
				
				return cell
			case .picker:
				let cell = tableView.dequeueReusableCell(withIdentifier: restPickerId.identifier, for: indexPath) as! RestPickerCell
				let r = p as! GTRest
				cell.picker.delegate = self
				cell.picker.dataSource = self
				cell.picker.selectRow(Int(ceil(r.rest / GTRest.restStep) - 1), inComponent: 0, animated: false)
				
				return cell
			}
		case 2:
			let cell = tableView.dequeueReusableCell(withIdentifier: addExercizeId.identifier, for: indexPath) as! AddExercizeCell
			#warning("Link add actions")
			cell.addExercize.addTarget(self, action: #selector(newExercize), for: .primaryActionTriggered)
			cell.addOther.addTarget(self, action: #selector(newChoose), for: .primaryActionTriggered)
			
			return cell
		default:
			fatalError("Unknown section")
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		guard !collection.exercizes.isEmpty, !self.isEditing, indexPath.section == 1 else {
			return
		}
		
		switch exercizeCellType(for: indexPath) {
		case .rest:
			guard editMode else {
				break
			}
			
			self.editRest(at: indexPath)
		case .exercize:
			self.openExercize(collection[Int32(exercizeNumber(for: indexPath))]!)
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
			editMode = false
			deletedEntities.removeAll()
			navigationController?.interactivePopGestureRecognizer?.isEnabled = true
			appDelegate.tabController.isPopToWorkoutListRootEnabled = true
			_ = navigationController?.popToViewController(self, animated: true)
			updateButtons()
			editRest = nil
			
			self.setEditing(false, animated: false)
			reloadAllSections()
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
			tableView.reloadSections([1], with: .automatic)
			return false
		}
	}
	
	private func canHandle(_ p: GTPart.Type) -> Bool {
		return p is T.Exercize.Type
	}
	
	@objc private func newChoose() {
		let choose = UIAlertController(title: GTLocalizedString("ADD_CHOOSE", comment: "Choose"), message: nil, preferredStyle: .actionSheet)
		
		for (n, t) in [("CIRCUIT", GTCircuit.self), ("CHOICE", GTChoice.self), ("EXERCIZE", GTSimpleSetsExercize.self), ("REST", GTRest.self)] {
			choose.addAction(UIAlertAction(title: GTLocalizedString(n, comment: "Type"), style: .default) { _ in
				self.newPart(of: t)
			})
		}
		
		choose.addAction(UIAlertAction(title: GTLocalizedString("CANCEL", comment: "Cancel"), style: .cancel))
		
		self.present(choose, animated: true)
	}
	
	@objc private func newExercize() {
		newPart(of: GTSimpleSetsExercize.self)
	}
	
	private func newPart(of type: GTPart.Type) {
		guard editMode, canHandle(type) else {
			return
		}
		
		tableView.beginUpdates()
		if collection.exercizes.isEmpty {
			tableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
		}
		
		let p = appDelegate.dataManager.newPart(type) as! T.Exercize
		collection.add(parts: p)
		if let e = p as? GTSimpleSetsExercize {
			e.set(name: "")
		} else if let r = p as? GTRest {
			r.set(rest: 4 * 60)
		}
		
		tableView.insertRows(at: [IndexPath(row: Int(p.order), section: 1)], with: .automatic)
		tableView.endUpdates()
		openExercize(p)
		updateValidityAndButtons(doUpdateTable: false)
	}
	
	func exercizeUpdated(_ e: GTPart) {
		guard let p = e as? T.Exercize, collection.exercizes.contains(p) else {
			return
		}
		
		addDeletedEntities(p.purge())
		if p.shouldBePurged {
			removeExercize(p)
		}

		DispatchQueue.main.async {
			self.updateValidityAndButtons()
		}
	}
	
	private func removeExercize(_ e: T.Exercize) {
		let index = IndexPath(row: Int(e.order), section: 1)
		addDeletedEntities([e])
		collection.remove(part: e)
		
		tableView.beginUpdates()
		tableView.deleteRows(at: [index], with: .automatic)
		
		if collection.exercizes.isEmpty {
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
		
		return collection.exercizeList[row] is GTRest ? .rest : .exercize
	}
	
	private func exercizeCellIndexPath(for e: T.Exercize) -> IndexPath {
		var i = IndexPath(row: Int(e.order), section: 1)
		
		if let r = editRest, r < i.row {
			i.row += 1
		}
		
		return i
	}
	
	func endEditRest() {
		if let rest = editRest {
			//Simulate tap on rest row to hide picker
			self.tableView(tableView, didSelectRowAt: IndexPath(row: rest, section: 1))
		}
	}
	
	private func editRest(at indexPath: IndexPath) {
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
		return Int(ceil(GTRest.maxRest / GTRest.restStep))
	}
	
	func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
		let color = UILabel.appearance().textColor ?? .black
		let txt = (TimeInterval(row + 1) * GTRest.restStep).getDuration(hideHours: true)
		
		return NSAttributedString(string: txt, attributes: [.foregroundColor : color])
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		guard let exN = editRest, let rest = collection.exercizeList[exN] as? GTRest else {
			return
		}
		
		rest.set(rest: TimeInterval(row + 1) * GTRest.restStep)
		tableView.reloadRows(at: [IndexPath(row: exN, section: 1)], with: .none)
	}
	
	// MARK: - Delete exercizes
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return editMode && indexPath.section == 1 && !collection.exercizes.isEmpty && exercizeCellType(for: indexPath) != .picker
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		guard editingStyle == .delete else {
			return
		}

		let exN = exercizeNumber(for: indexPath)
		guard let p = collection[Int32(exN)] else {
			return
		}

		removeExercize(p)
	}
	
	// MARK: - Reorder exercizes
	
	@objc private func updateReorderMode() {
		guard editMode, !collection.exercizes.isEmpty || self.isEditing else {
			return
		}

		endEditRest()

		self.setEditing(!self.isEditing, animated: true)
		reorderBtn.title = self.isEditing ? doneReorderLbl : reorderLbl
	}

	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		return editMode && indexPath.section == 1 && !collection.exercizes.isEmpty && exercizeCellType(for: indexPath) != .picker
	}

	override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
		if proposedDestinationIndexPath.section < 1 {
			return IndexPath(row: 0, section: 1)
		} else if proposedDestinationIndexPath.section > 1 {
			return IndexPath(row: collection.exercizes.count - 1, section: 1)
		}

		return proposedDestinationIndexPath
	}

	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		guard editMode && fromIndexPath.section == 1 && to.section == 1 && !collection.exercizes.isEmpty else {
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
		
		if isNew {
			self.dismiss(animated: animated, completion: animationCompletion)
		} else {
			exitEdit()
		}
	}
	
	func openExercize(_ p: T.Exercize) {
		if let e = p as? GTSimpleSetsExercize {
			let dest = ExercizeTableViewController.instanciate()
			
			dest.exercize = e
			dest.editMode = self.editMode
			dest.delegate = self
			self.exercizeController = dest
			
			navigationController?.pushViewController(dest, animated: true)
		} else if p is GTRest {
			// No need to push something else, edit is in place
		} else {
			fatalError("Implement me")
		}
	}

}
