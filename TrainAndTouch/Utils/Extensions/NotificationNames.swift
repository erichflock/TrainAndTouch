//
//  NotificationNames.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 29.11.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation

extension Notification.Name {

    //MARK: Notifications used to trigger actions on BookViewController
    
    static let didEnableTrackingOnReadingTask = Notification.Name("didEnableTrackingOnReadingTask")
    
    static let didDisableTrackingOnReadingTask = Notification.Name("didDisableTrackingOnReadingTask")
    
    static let didChangeWindowSizeToSmallOnReadingTask = Notification.Name("didChangeWindowSizeToSmallOnReadingTask")

    static let didChangeWindowSizeToLargeOnReadingTask = Notification.Name("didChangeWindowSizeToLargeOnReadingTask")
    
    static let didChangeToFirstTextOnReadingTask = Notification.Name("didChangeToFirstTextOnReadingTask")

    static let didChangeToSecondTextOnReadingTask = Notification.Name("didChangeToSecondTextOnReadingTask")

    static let didChangeToThirdTextOnReadingTask = Notification.Name("didChangeToThirdTextOnReadingTask")
    
    static let showHeadTrackingOnReadingTask = Notification.Name("showHeadTrackingOnReadingTask")
    
    static let hideHeadTrackingOnReadingTask = Notification.Name("hideHeadTrackingOnReadingTask")
    
    //MARK: Notifications used to trigger actions on TouchViewController
    
    static let didEnableTrackingOnTouchTask = Notification.Name("didEnableTrackingOnTouchTask")
    
    static let didDisableTrackingOnTouchTask = Notification.Name("didDisableTrackingOnTouchTask")
    
    static let didChangeWindowSizeToSmallOnTouchTask = Notification.Name("didChangeWindowSizeToSmallOnTouchTask")

    static let didChangeWindowSizeToLargeOnTouchTask = Notification.Name("didChangeWindowSizeToLargeOnTouchTask")
    
    static let showHeadTrackingOnTouchTask = Notification.Name("showHeadTrackingOnTouchTask")
    
    static let hideHeadTrackingOnTouchTask = Notification.Name("hideHeadTrackingOnTouchTask")
}
