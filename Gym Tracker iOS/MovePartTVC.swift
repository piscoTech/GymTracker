//
//  MovePartTableViewController.swift
//  Gym Tracker iOS
//
//  Created by Marco Boschi on 24/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import GymTrackerCore

enum MovePartInvalidExercize: CustomStringConvertible {
	case notSupported, alreadyPart, isSelf, withParent
	
	var description: String {
		let msg: String
		switch self {
		case .notSupported:
			msg = "MOVE_EX_NOT_SUPPORTED"
		case .alreadyPart:
			msg = "MOVE_EX_ALREADY_PART"
		case .isSelf:
			msg = "MOVE_EX_SELF"
		case .withParent:
			msg = "MOVE_EX_PARENT"
		}
		
		return GTLocalizedString(msg, comment: "Invalid")
	}
}

class MovePartTableViewController<T: GTDataObject>: UITableViewController where T: ExercizeCollection {
	
	class func initialize(currentPart curr: T, completion: @escaping () -> Void) -> UIViewController {
		let mover = MovePartTableViewController(currentPart: curr, completion: completion)
		let navigation = UINavigationController(rootViewController: mover)
		navigation.navigationBar.barStyle = .black
		navigation.navigationBar.isTranslucent = true
		navigation.navigationBar.tintColor = customTint
		
		return navigation
	}
	
	var current: T
	var completion: () -> Void
	
	private typealias TreeComponent = (part: GTExercize, checked: Bool, level: Int, invalid: MovePartInvalidExercize?)
	private var tree: [TreeComponent]!
	private let rowId = "exercize"
	
	private weak var doneBtn: UIBarButtonItem!
	
	init(currentPart curr: T, completion: @escaping () -> Void) {
		self.current = curr
		self.completion = completion
		
		super.init(style: .plain)
		
		var top: CompositeWorkoutLevel = current
		while let p = top.parentLevel {
			top = p
		}
		
		tree = expandCollection(top)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.title = GTLocalizedString("MOVE_EX_CHOOSE", comment: "Choose")
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
		let doneBtn = UIBarButtonItem(title: GTLocalizedString("MOVE_EX_MOVE", comment: "Move"), style: .done, target: self, action: #selector(done))
		self.doneBtn = doneBtn
		navigationItem.rightBarButtonItem = doneBtn
		
		tableView.register(UINib(nibName: "MoveExercize", bundle: Bundle.main), forCellReuseIdentifier: rowId)
		tableView.rowHeight = 44
		
		updateButton()
    }
	
	private func expandCollection(_ coll: CompositeWorkoutLevel, level: Int = 0) -> [TreeComponent] {
		func add(_ p: GTPart) -> [TreeComponent] {
			guard let e = p as? GTExercize else {
				return []
			}
			let invalid: MovePartInvalidExercize?
			
			if e == current {
				invalid = .isSelf
			} else if !(e is T.Exercize) {
				invalid = .notSupported
			} else if current.childrenList.contains(e) {
				invalid = .alreadyPart
			} else {
				invalid = nil
			}
			
			return [(e, false, level, invalid)]
		}
		return coll.childrenList.flatMap { c -> [TreeComponent] in
			if let cC = c as? CompositeWorkoutLevel {
				return add(c) + expandCollection(cC, level: level + 1)
			} else {
				return add(c)
			}
		}
	}
	
	private func updateButton() {
		doneBtn.isEnabled = tree.firstIndex { $0.checked } != nil
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tree.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: rowId, for: indexPath) as! MoveExercizeCell

		let e = tree[indexPath.row]
		cell.name.text = e.part.title
		cell.exercizeInfo.text = e.part.summary
		cell.setLevel(e.level)
		cell.setInvalid(e.invalid, isCollection: e.part is CompositeWorkoutLevel)
		
		cell.accessoryType = e.checked && e.invalid == nil ? .checkmark : .none

        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		let e = tree[indexPath.row]
		guard e.invalid == nil else {
			return
		}
		
		let newVal = !e.checked
		tree[indexPath.row].checked = newVal
		var reaload = Set([indexPath.row])
		let subTree = e.part.subtreeNodes
		for i in 0 ..< tree.count {
			if tree[i].part != e.part, subTree.contains(tree[i].part), tree[i].invalid == nil || tree[i].invalid == .withParent {
				tree[i].invalid = newVal ? .withParent : nil
				reaload.insert(i)
			}
		}
		
		tableView.reloadRows(at: reaload.map { IndexPath(row: $0, section: 0 )}, with: .fade)
		updateButton()
	}

    // MARK: - Navigation

	@objc private func cancel() {
		self.dismiss(animated: true)
	}
	
	@objc private func done() {
		for e in tree {
			if e.checked, e.invalid == nil, let e = e.part as? T.Exercize {
				current.add(parts: e)
			}
		}
		
		completion()
		cancel()
	}

}
