//
//  UIViewController+Notification.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 05.12.19.
//  Copyright © 2019 flock. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func registerForNotification(name aName: NSNotification.Name) {
        let center = NotificationCenter.default
        let selector = #selector(receivedNotification(_:))
        
        center.addObserver(self, selector: selector, name: aName, object: nil)
    }
    
    func deregisterForNotification(name aName: NSNotification.Name) {
        let center = NotificationCenter.default
        
        center.removeObserver(self, name: aName, object: nil)
        
    }
    
    func deregisterForNotification() {
        let center = NotificationCenter.default
        
        center.removeObserver(self)
    }
    
    @objc func receivedNotification(_ notification: Notification) { }
}
