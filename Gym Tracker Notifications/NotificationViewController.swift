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

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet weak var titleLbl: UILabel!
	@IBOutlet weak var bodyLbl: UILabel!
	
	@IBOutlet weak var mainView: UIStackView!
	@IBOutlet var updateWeightView: UIStackView!
	
	private var viewInApp: UNNotificationAction!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
		
		updateWeightView.removeFromSuperview()
		viewInApp = UNNotificationAction(identifier: GTNotification.Action.endSetWeight.rawValue, title: NSLocalizedString("NOTIF_INTERACTIVE_WEIGHT_IN_APP", comment: "Open in App"), options: [.foreground])
    }
    
    func didReceive(_ notification: UNNotification) {
		titleLbl.text = notification.request.content.title
        bodyLbl?.text = notification.request.content.body
    }
	
	@IBAction func saveWeight(_ sender: AnyObject) {
		print("Button tapped")
	}
	
	func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
		if response.actionIdentifier == GTNotification.Action.endSetWeight.rawValue {
			mainView.addArrangedSubview(updateWeightView)
			extensionContext?.notificationActions = [viewInApp]
			
			completion(.doNotDismiss)
		} else {
			completion(.dismissAndForwardAction)
		}
	}

}
