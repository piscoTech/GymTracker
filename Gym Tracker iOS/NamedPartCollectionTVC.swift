//
//  NamedPartCollectionTableViewController.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 20/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import GymTrackerCore
import UIKit

class NamedPartCollectionTableViewController<T: GTDataObject>: PartCollectionTableViewController<T>, UITextFieldDelegate where T: NamedExercizeCollection {
	
	private let titleId: CellInfo = ("TitleCell", "title")
	private let editTitleId: CellInfo = ("EditTitleCell", "editTitle")
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		for (n, i) in [titleId, editTitleId] {
			tableView.register(UINib(nibName: n, bundle: Bundle.main), forCellReuseIdentifier: i)
		}
	}
	
	// MARK: - Table view data source
	
	override var mainSectionIndex: Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 && indexPath.row == 0 && !editMode {
			return UITableView.automaticDimension
		}
		
		return super.tableView(tableView, heightForRowAt: indexPath)
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return super.tableView(tableView, numberOfRowsInSection: section) + (section == 0 ? 1 : 0)
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let forwardIndexPath: IndexPath
		
		if indexPath.section == 0 {
			if indexPath.row == 0 {
				if editMode {
					let cell = tableView.dequeueReusableCell(withIdentifier: editTitleId.identifier, for: indexPath) as! SingleFieldCell
					cell.textField.text = collection.name
					cell.textField.delegate = self
					cell.textField.addTarget(self, action: #selector(nameChanged(_:)), for: .editingChanged)
					
					return cell
				} else {
					let cell = tableView.dequeueReusableCell(withIdentifier: titleId.identifier, for: indexPath) as! MultilineCell
					cell.isUserInteractionEnabled = false
					cell.label.text = collection.name
					return cell
				}
			} else {
				forwardIndexPath = IndexPath(row: indexPath.row - 1, section: 0)
			}
		} else {
			forwardIndexPath = indexPath
		}
		
		return super.tableView(tableView, cellForRowAt: forwardIndexPath)
	}
	
	// MARK: - Edit name
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}
	
	@objc func nameChanged(_ sender: UITextField) {
		collection.set(name: sender.text ?? "")
		updateValidityAndButtons(doUpdateTable: false)
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		textField.text = collection.name
		updateValidityAndButtons(doUpdateTable: false)
	}
	
}
