//
//  UpdateWeightViewController.swift
//  Gym Tracker
//
//  Created by Marco Boschi on 16/04/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit

class UpdateWeightViewController: UIViewController {
	
	var weightData: UpdateWeightData!
	let backgroundColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
	
	private weak var delegate: ExecuteWorkoutController!
	private var set: RepsSet!
	
	private var sum = 0.0
	
	@IBOutlet weak var base: UILabel!
	@IBOutlet weak var plus: UILabel!
	@IBOutlet weak var minus: UILabel!
	@IBOutlet weak var add: UILabel!
	
	@IBOutlet var buttons: [UIButton]!

    override func viewDidLoad() {
        super.viewDidLoad()

		guard let data = weightData else {
			DispatchQueue.main.async {
				self.dismiss(animated: true)
			}
			
			return
		}
		
		self.view.backgroundColor = .clear
		for b in buttons {
			b.clipsToBounds = true
			b.layer.cornerRadius = 5
		}
		
		self.delegate = data.workoutController
		self.set = data.set
		self.sum = delegate.weightChange(for: set)
		
		base.text = set.weight.toString()
		updateView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func addWeight(_ w: Double) {
		sum += w
		sum = sum < 0 ? max(sum, -set.weight) : sum
		updateView()
	}
	
	private func updateView() {
		if sum >= 0 {
			plus.isHidden = false
			minus.isHidden = true
		} else {
			plus.isHidden = true
			minus.isHidden = false
		}
		add.text = abs(sum).toString()
	}
	
	@IBAction func done() {
		delegate.setWeightChange(sum, for: set)
		self.dismiss(animated: true)
	}
	
	@IBAction func addHalf() {
		addWeight(0.5)
	}
	
	@IBAction func addOne() {
		addWeight(1)
	}
	
	@IBAction func addFive() {
		addWeight(5)
	}
	
	@IBAction func addTen() {
		addWeight(10)
	}
	
	@IBAction func minusHalf() {
		addWeight(-0.5)
	}
	
	@IBAction func minusOne() {
		addWeight(-1)
	}
	
	@IBAction func minusFive() {
		addWeight(-5)
	}
	
	@IBAction func minusTen() {
		addWeight(-10)
	}

}
