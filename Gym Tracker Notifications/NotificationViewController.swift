//
//  NotificationViewController.swift
//  Gym Tracker Notifications
//
//  Created by Marco Boschi on 30/07/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import GymTrackerCore
import MBLibrary

typealias NotificationCompletion = (UNNotificationContentExtensionResponseOption) -> Void

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var titleLbl: UILabel!
	@IBOutlet weak var bodyLbl: UILabel!
	
	@IBOutlet weak var mainView: UIStackView!
	@IBOutlet var updateWeightView: UIStackView!
	
	@IBOutlet weak var base: UILabel!
	@IBOutlet weak var plus: UILabel!
	@IBOutlet weak var minus: UILabel!
	@IBOutlet weak var add: UILabel!
	
	private var viewInApp: UNNotificationAction!
	private var notificationCompletion: NotificationCompletion?
	private var weight = 0.0
	private var sum = 0.0
	
	private var preferences: Preferences!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
		
		preferences = Preferences(for: .application)
		updateWeightView.removeFromSuperview()
		viewInApp = UNNotificationAction(identifier: GTNotification.Action.endSetWeightInApp.rawValue, title: NSLocalizedString("NOTIF_INTERACTIVE_WEIGHT_IN_APP", comment: "Open in App"), options: [.foreground])
		
		let buttons = updateWeightView.arrangedSubviews
			.compactMap { $0 as? UIStackView }
			.flatMap { $0.arrangedSubviews }
			.compactMap { $0 as? UIStackView }
			.flatMap { $0.arrangedSubviews }
			.compactMap { $0 as? UIButton }
		for b in buttons {
			b.clipsToBounds = true
			b.layer.cornerRadius = 5
		}
    }
    
    func didReceive(_ notification: UNNotification) {
		let not = notification.request.content
		titleLbl.text = not.title
        bodyLbl?.text = not.body
		
		weight = max(not.userInfo[GTNotification.UserInfo.setWeight.rawValue] as? Double ?? 0, 0)
		base.text = weight.toString()
		sum = weightChange(for: not.userInfo[GTNotification.UserInfo.setWeightChange.rawValue] as? Double ?? 0)
		
		updateView()
		preferences.clearNotificationData()
    }
	
	private func weightChange(for sum: Double) -> Double {
		return sum < 0 ? max(sum, -weight) : sum
	}
	
	private func addWeight(_ w: Double) {
		sum = weightChange(for: sum + w)
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
	
	@IBAction func saveWeight(_ sender: AnyObject) {
		preferences.weightUpdatedInNotification = true
		preferences.weightChangeFromNotification = sum
		notificationCompletion?(.dismissAndForwardAction)
	}
	
	func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping NotificationCompletion) {
		if response.actionIdentifier == GTNotification.Action.endSetWeight.rawValue {
			mainView.addArrangedSubview(updateWeightView)
			extensionContext?.notificationActions = [viewInApp]
			preferences.setEndedInNotificationTime = Date()
			
			notificationCompletion = completion
		} else {
			completion(.dismissAndForwardAction)
		}
	}

}
