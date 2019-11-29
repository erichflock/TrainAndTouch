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
    
    //MARK: Touch Task UI Elements
    @IBOutlet var touchTaskTrackingSwitch: UISwitch!
    @IBOutlet var touchTaskWindowSizeSmall: UIButton!
    @IBOutlet var touchTaskWindowSizeLarge: UIButton!
    
    //MARK: Reading Task Actions
    
    @IBAction func readingTaskTrackingSwitchToggleAction(_ sender: Any) {
        
        if readingTaskTrackingSwitch.isOn {
            print("Enable Tracking on Reading Task")
        } else {
            print("Disable Tracking on Reading Task")
        }
    }
    
    @IBAction func readingTaskWindowSizeSmallAction(_ sender: Any) {
        
        print("Change Window Size to Small on Reading Task")
    }
    
    @IBAction func readingTaskWindowSizeLargeAction(_ sender: Any) {
        
        print("Change Window Size to Large on Reading Task")
    }
    
    @IBAction func readingTaskFirstTextAction(_ sender: Any) {
        
        print("Change to First Text on Reading Task")
    }
    
    @IBAction func readingTaskSecondTextAction(_ sender: Any) {
        
        print("Change to Second Text on Reading Task")
    }
    
    @IBAction func readingTaskThirdTextAction(_ sender: Any) {
        
        print("Change to Third Text on Reading Task")
    }
    
    //MARK: Touch Task Actions
    
    @IBAction func touchTaskTrackingSwitchToggleAction(_ sender: Any) {
        
        if touchTaskTrackingSwitch.isOn {
            print("Enable Tracking on Touch Task")
        } else {
            print("Disable Tracking on Touch Task")
        }
    }
    
    @IBAction func touchTaskWindowSizeSmallAction(_ sender: Any) {
        
        print("Change Window Size to Small on Touch Task")
    }
    
    @IBAction func touchTaskWindowSizeLargeAction(_ sender: Any) {
        
        print("Change Window Size to Small on Touch Task")
    }
    
}
