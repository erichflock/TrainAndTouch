//
//  SettingsViewController.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 25.06.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation
import UIKit


class SettingsViewController : UITableViewController {
    
    //MARK: Reading Task UI Elements
    @IBOutlet var readingTaskTrackingSwitch: UISwitch!
    @IBOutlet var readingTaskWindowSizeSmallButton: UIButton!
    @IBOutlet var readingTaskWindowSizeLargeButton: UIButton!
    @IBOutlet var readingTaskFirstTextButton: UIButton!
    @IBOutlet var readingTaskSecondTextButton: UIButton!
    @IBOutlet var readingTaskThirdTextButton: UIButton!
    @IBOutlet var readingTaskShowHeadTrackingSwitch: UISwitch!
    
    //MARK: Touch Task UI Elements
    @IBOutlet var touchTaskTrackingSwitch: UISwitch!
    @IBOutlet var touchTaskWindowSizeSmallButton: UIButton!
    @IBOutlet var touchTaskWindowSizeLargeButton: UIButton!
    @IBOutlet var touchTaskShowHeadTrackingSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    private func setupView() {
        
        self.tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        
        self.readingTaskWindowSizeSmallButton.isSelected = true
        self.readingTaskFirstTextButton.isSelected = true
        self.touchTaskWindowSizeSmallButton.isSelected = true
    }
    
    //MARK: Reading Task Actions
    
    @IBAction func readingTaskTrackingSwitchToggleAction(_ sender: Any) {
        
        if readingTaskTrackingSwitch.isOn {
            
            NotificationCenter.default.post(Notification(name: .didEnableTrackingOnReadingTask))
            print("Enable Tracking on Reading Task")
            
        } else {
            
            NotificationCenter.default.post(Notification(name: .didDisableTrackingOnReadingTask))
            print("Disable Tracking on Reading Task")
        }
    }
    
    @IBAction func readingTaskWindowSizeSmallAction(_ sender: Any) {
        
        NotificationCenter.default.post(Notification(name: .didChangeWindowSizeToSmallOnReadingTask))
        print("Change Window Size to Small on Reading Task")
    }
    
    @IBAction func readingTaskWindowSizeLargeAction(_ sender: Any) {
        
        NotificationCenter.default.post(Notification(name: .didChangeWindowSizeToLargeOnReadingTask))
        print("Change Window Size to Large on Reading Task")
    }
    
    @IBAction func readingTaskFirstTextAction(_ sender: Any) {
        
        NotificationCenter.default.post(Notification(name: .didChangeToFirstTextOnReadingTask))
        print("Change to First Text on Reading Task")
    }
    
    @IBAction func readingTaskSecondTextAction(_ sender: Any) {
        
        NotificationCenter.default.post(Notification(name: .didChangeToSecondTextOnReadingTask))
        print("Change to Second Text on Reading Task")
    }
    
    @IBAction func readingTaskThirdTextAction(_ sender: Any) {
        
        NotificationCenter.default.post(Notification(name: .didChangeToThirdTextOnReadingTask))
        print("Change to Third Text on Reading Task")
    }
    
    @IBAction func readingTaskShowHeadTrackingSwitchToggleAction(_ sender: Any) {
        
        if readingTaskShowHeadTrackingSwitch.isOn {
            
            let notification = Notification(name: .showHeadTrackingOnReadingTask, userInfo: nil)
            NotificationQueue.default.enqueue(notification, postingStyle: .whenIdle, coalesceMask: .onName, forModes: nil)
            
            //NotificationCenter.default.post(Notification(name: .showHeadTrackingOnReadingTask))
        } else {
            
            let notification = Notification(name: .hideHeadTrackingOnReadingTask, userInfo: nil)
            NotificationQueue.default.enqueue(notification, postingStyle: .whenIdle, coalesceMask: .onName, forModes: nil)
            //NotificationCenter.default.post(Notification(name: .hideHeadTrackingOnReadingTask))
        }
    }
    
    //MARK: Touch Task Actions
    
    @IBAction func touchTaskTrackingSwitchToggleAction(_ sender: Any) {
        
        if touchTaskTrackingSwitch.isOn {
            
            NotificationCenter.default.post(Notification(name: .didEnableTrackingOnTouchTask))
            print("Enable Tracking on Touch Task")
        } else {
            
            NotificationCenter.default.post(Notification(name: .didDisableTrackingOnTouchTask))
            print("Disable Tracking on Touch Task")
        }
    }
    
    @IBAction func touchTaskWindowSizeSmallAction(_ sender: Any) {
        
        NotificationCenter.default.post(Notification(name: .didChangeWindowSizeToSmallOnTouchTask))
        print("Change Window Size to Small on Touch Task")
    }
    
    @IBAction func touchTaskWindowSizeLargeAction(_ sender: Any) {
        
        NotificationCenter.default.post(Notification(name: .didChangeWindowSizeToLargeOnTouchTask))
        print("Change Window Size to Small on Touch Task")
    }
    
    @IBAction func touchTaskShowHeadTrackingSwitchToggleAction(_ sender: Any) {
        
        if touchTaskShowHeadTrackingSwitch.isOn {
            
            NotificationCenter.default.post(Notification(name: .showHeadTrackingOnTouchTask))
        } else {
            NotificationCenter.default.post(Notification(name: .hideHeadTrackingOnTouchTask))
        }
    }
}
