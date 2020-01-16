//
//  TouchViewController.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 15.10.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import Vision
import AVFoundation
import MessageUI

class TouchTaskViewController: UIViewController {

    @IBOutlet var touchAreaView: UIView!
    
    @IBOutlet var touchAreaViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var touchAreaViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var touchAreaViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet var touchAreaViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var touchAreaViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var touchAreaViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var sendReportButton: UIButton!
    
    let borderLimitThreshold: CGFloat = 5.0
    
    var width: CGFloat = 0
    var distance: CGFloat = 0
    
    var faceTrackingHelper: FaceTrackingHelper?
    var avSession: AVCaptureSession?
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    
    let shapeLayer = CAShapeLayer()
    
    var lastX: CGFloat?
    var lastY: CGFloat?
    var newX: CGFloat?
    var newY: CGFloat?
    
    var actualWindowSize: Size = .small
    
    var numberOfCirclesAdded = 0
    var numberOfMissedTouches = 0
    var clicks: [Click] = []
    
    var fittsLaw: FittsLaw?
    
    var timeSpentOnTheTask: Date?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraView.isHidden = true
        
        setupTouchAreaView()
        
        deregisterForNotification()
        
        registerForNotification(name: .hideHeadTrackingOnTouchTask)
        registerForNotification(name: .showHeadTrackingOnTouchTask)
        registerForNotification(name: .didEnableTrackingOnTouchTask)
        registerForNotification(name: .didDisableTrackingOnTouchTask)
        registerForNotification(name: .didChangeWindowSizeToLargeOnTouchTask)
        registerForNotification(name: .didChangeWindowSizeToSmallOnTouchTask)
    }
    
    override func receivedNotification(_ notification: Notification) {
        
        switch notification.name {
        case .hideHeadTrackingOnTouchTask:
            
            cameraView.isHidden = true
            
            break
            
        case .showHeadTrackingOnTouchTask:
            
            cameraView.isHidden = false
            
            break
            
        case .didEnableTrackingOnTouchTask:
            
            activateFaceTracking()
            
            break
            
        case .didDisableTrackingOnTouchTask:
            
            centralizeContentView()
            self.view.layoutIfNeeded()
            deactivateFaceTracking()
            
            break
            
        case .didChangeWindowSizeToLargeOnTouchTask:
            
            updateWindowSize(size: .large)
            self.view.layoutIfNeeded()
            startTouchGame()
            
            break
            
        case .didChangeWindowSizeToSmallOnTouchTask:
            
            updateWindowSize(size: .small)
            self.view.layoutIfNeeded()
            startTouchGame()
            
            break
        
        default:
            break
        }
        
        self.view.layoutIfNeeded()
    }
    
    private func setupTouchAreaView() {
        
        self.touchAreaView.layer.borderWidth = 1
        self.touchAreaView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
    }
    
    private func activateFaceTracking() {
        
        avSession = AVCaptureSession()
        
        faceTrackingHelper = FaceTrackingHelper()
        
        if let faceTrackingHelper = faceTrackingHelper {
            
            faceTrackingHelper.initializeCameraSession(avSession: avSession, AVDelegate: self, cameraView: cameraView, widthConstraint: cameraViewWidthConstraint.constant, heightConstraint: cameraViewHeightConstraint.constant, shapeLayer: shapeLayer)
            
            faceTrackingHelper.bottomConstraint = touchAreaViewBottomConstraint
            faceTrackingHelper.traillingConstraint = touchAreaViewTraillingConstraint
            
            faceTrackingHelper.maximumTraillingConstraintValue = getMaximumTraillingConstraintValue()
            faceTrackingHelper.maximumBottomConstraintValue = getMaximumBottomConstraintValue()
            faceTrackingHelper.minimumBottomConstraintValue = 30.0
            faceTrackingHelper.minimumLeadingConstraintValue = 30.0
            
            switch actualWindowSize {
            case .small:
                
                faceTrackingHelper.speed = 0.8
                
                break
                
            case .large:
                
                faceTrackingHelper.speed = 0.5
            }
        }
    }
    
    private func deactivateFaceTracking() {
        
        if let avSession = self.avSession {
            avSession.stopRunning()
        }
        
        avSession = nil
        
        faceTrackingHelper = nil
    }
    
    private func getMaximumTraillingConstraintValue() -> CGFloat {
        
        let viewWidth = self.view.frame.width
        let contentViewWidth = self.touchAreaView.frame.width
        let maximumTraillingConstraintValue = viewWidth - contentViewWidth - self.touchAreaViewLeadingConstraint.constant
        
        return maximumTraillingConstraintValue
    }
    
    private func getMaximumBottomConstraintValue() -> CGFloat {
        
        let viewHeight = self.view.frame.height
        let contentViewHeight = self.touchAreaView.frame.height
        let maximumBottomConstraint = viewHeight - contentViewHeight - self.touchAreaViewTopConstraint.constant
        
        return maximumBottomConstraint
    }
    
    func startTouchGame() {
        
        sendReportButton.isHidden = true
        
        //reset variables
        numberOfCirclesAdded = 0
        numberOfMissedTouches = 0
        clicks = []
        
        prepareVariablesForNextTouchInteraction()
        
        fittsLaw = FittsLaw()
        
        addCircleOnTouchAreaView()
    }

    private func addCircleOnTouchAreaView() {
        
        if !hasReachedThirtyCircles() {
            
            fittsLaw?.start = Date()
            
            numberOfCirclesAdded += 1
            
            //remove previous circle
            touchAreaView.subviews.forEach({ $0.removeFromSuperview() })
            
            let tapOnCircle = UITapGestureRecognizer(target: self, action: #selector(self.userTappedOnCircle(touch:)))
                        
            print("Width: \(width)")
            
            distance = getNextDistance(lastX: lastX ?? 0, lastY: lastY ?? 0, newX: newX ?? 0, newY: newY ?? 0)
            
            print("last X: \(String(describing: lastX)), last Y: \(String(describing: lastY))")
            print("New X: \(newX), New Y: \(newY)")
            print("Distance: \(distance)")
            
            let circleView = UIView(frame: CGRect(x: newX ?? 0, y: newY ?? 0, width: width, height: width))
            
            circleView.layer.cornerRadius = circleView.bounds.size.width / 2 // circle shape
            circleView.backgroundColor = .red
            circleView.addGestureRecognizer(tapOnCircle)
            
            self.touchAreaView.addSubview(circleView)
            
            let tapOnWindow = UITapGestureRecognizer(target: self, action: #selector(self.userMissedCircle(touch:)))
            self.touchAreaView.addGestureRecognizer(tapOnWindow)
            
        } else {
            //remove previous circle
            touchAreaView.subviews.forEach({ $0.removeFromSuperview() })
            
            sendReportButton.isHidden = false
        }
    }
    
    @objc private func userTappedOnCircle(touch: UITapGestureRecognizer) {
        
//        let x = touch.location(in: self.touchAreaView).x
//        let y = touch.location(in: self.touchAreaView).y
        
        // if time is nil, we should initialize it, meaning the first user interaction and the beggining of the task
        
        if timeSpentOnTheTask == nil {
            timeSpentOnTheTask = Date()
        }
        
        if let fittsLaw = self.fittsLaw {
            
            let id = fittsLaw.getId(d: distance, w: width)
            let dt = fittsLaw.getDt()
                    
            let fittsLawElement = FittsLawElement(dT: dt, iD: id)
            fittsLaw.fittsLawElements.append(fittsLawElement)
                
            let meanDt = fittsLaw.getMeanDt()
            let meanId = fittsLaw.getMeanId()
                    
            let b = fittsLaw.getB(meanDt: meanDt, meanId: meanId)
            let a = fittsLaw.getA(meanDT: meanDt, meandID: meanId, b: b)
            
            let movementTime = (a + b) * id
            
            let click = Click(x: newX ?? 0, y: newY ?? 0, lastX: lastX ?? 0, lastY: lastY ?? 0, a: a, b: b, dT: dt, id: id, distance: distance, width: width, movementTime: movementTime, onTarget: true)
            clicks.append(click)
            
            print("userTappedOnCircle: \(click)")
            
            prepareVariablesForNextTouchInteraction()
        }
        
        addCircleOnTouchAreaView()
    }
    
    @objc private func userMissedCircle(touch: UITapGestureRecognizer) {
        
        numberOfMissedTouches += 1
        
        let x = touch.location(in: self.touchAreaView).x
        let y = touch.location(in: self.touchAreaView).y
        
        if let fittsLaw = self.fittsLaw {
            
            let id = fittsLaw.getId(d: distance, w: width)
            let dt = fittsLaw.getDt()
                
            let meanDt = fittsLaw.getMeanDt()
            let meanId = fittsLaw.getMeanId()
                    
            let b = fittsLaw.getB(meanDt: meanDt, meanId: meanId)
            let a = fittsLaw.getA(meanDT: meanDt, meandID: meanId, b: b)
            
            let movementTime = (a + b) * id
            
            let click = Click(x: x, y: y, lastX: lastX ?? 0, lastY: lastY ?? 0, a: a, b: b, dT: dt, id: id, distance: distance, width: width, movementTime: movementTime, onTarget: false)
            clicks.append(click)
            
            print("userMissedCircle: \(click)")
        }
    }
    
    private func prepareVariablesForNextTouchInteraction() {

        width = getRandomWidth()
        lastX = newX
        lastY = newY
        newX = getRandomPositon(startPoint: 0, constraint: touchAreaView.frame.width)
        newY = getRandomPositon(startPoint: 0, constraint: touchAreaView.frame.height)
    }
    
    private func hasReachedThirtyCircles() -> Bool {
        
        if numberOfCirclesAdded == 30 {
            return true
        } else {
            return false
        }
    }
    
    private func getRandomWidth() ->CGFloat {
        return CGFloat.random(between: 44, and: 200)
    }
    
    private func getRandomPositon(startPoint: CGFloat, constraint: CGFloat) ->CGFloat {
        
        var randomPosition = CGFloat.random(between: startPoint, and: constraint)
        
        let borderLimit = constraint
        
        while (randomPosition + width) > borderLimit {
            randomPosition = borderLimit - width - borderLimitThreshold
        }
        
        return randomPosition
    }
    
    private func getNextDistance(lastX: CGFloat, lastY: CGFloat, newX: CGFloat, newY: CGFloat) -> CGFloat{

        let diffX = newX - lastX
        let diffY = newY - lastY
        
        let distance = CGFloat(sqrtf(Float(diffX * diffX + diffY * diffY))) - width / 2
        
        return distance
    }
    
    private func updateWindowSize(size: Size) {
        
        switch size {
        case .small:
            
            let width: CGFloat = 600
            let height: CGFloat = 450 // porportion of (self.view.frame.height / self.view.frame.width)
            
            self.touchAreaViewWidthConstraint.constant = width
            self.touchAreaViewHeightConstraint.constant = height
            
            actualWindowSize = .small
            
            self.view.layoutIfNeeded()
            
            if faceTrackingHelper != nil {
                restartFaceTracking()
            } else {
                centralizeContentView()
            }
            
            break
            
        case .large:
            
            let width: CGFloat = 850
            let height: CGFloat = 637.5 // porportion of (self.view.frame.height / self.view.frame.width)
            
            self.touchAreaViewWidthConstraint.constant = width
            self.touchAreaViewHeightConstraint.constant = height
            
            actualWindowSize = .large
            
            self.view.layoutIfNeeded()
            
            if faceTrackingHelper != nil {
                restartFaceTracking()
            } else {
                centralizeContentView()
            }
            
            break
        }
    }
    
    private func restartFaceTracking() {
        
        deactivateFaceTracking()
        activateFaceTracking()
    }
    
    private func centralizeContentView() {
        
        switch actualWindowSize {
        case .small:
            
            touchAreaViewBottomConstraint.constant = 150
            touchAreaViewTraillingConstraint.constant = 210
            
            break
            
        case .large:
            
            touchAreaViewBottomConstraint.constant = 75
            touchAreaViewTraillingConstraint.constant = 125
        }
    }
    
    private func getReport() -> String {
        
        let timeDuration = (timeSpentOnTheTask?.timeIntervalSinceNow ?? 0) * -1
        
        var headTrackingEnabled = false
        
        if faceTrackingHelper != nil {
            headTrackingEnabled = true
        }
        
        let taskSetup = "Screen Size: \(actualWindowSize), Head Tracking Enabled: \(headTrackingEnabled)"
        let taskResults = "Number of touched circles: \(numberOfCirclesAdded) \n\nNumber of missed clicks: \(numberOfMissedTouches)\n\nTime spent on the task: \(timeDuration)\n\nClicks: \n\n\(clicks)"
        
        return "Task Setup: \(taskSetup) \n\n Task Results: \(taskResults)"
    }
    
    @IBAction func sendReportByEmail(_ sender: Any) {
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["flock91@gmail.com"])
            mail.setSubject("Train & Touch - User Study")
            mail.setMessageBody(getReport(), isHTML: true)

            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
}

public extension CGFloat {
    
    static var random: CGFloat { return CGFloat(arc4random()) / CGFloat(UInt32.max) }

    static func random(between x: CGFloat, and y: CGFloat) -> CGFloat {
        let (start, end) = x < y ? (x, y) : (y, x)
        return start + CGFloat.random * (end - start)
    }
}

public extension CGRect {
    
    var randomPoint: CGPoint {
        var point = CGPoint()

        point.x = CGFloat.random(between: origin.x, and: origin.x + width)
        point.y = CGFloat.random(between: origin.y, and: origin.y + height)

        return point
    }
}

public enum DispatchLevel {
    case main, userInteractive, userInitiated, utility, background
    var dispatchQueue: DispatchQueue {
        switch self {
        case .main:                 return DispatchQueue.main
        case .userInteractive:      return DispatchQueue.global(qos: .userInteractive)
        case .userInitiated:        return DispatchQueue.global(qos: .userInitiated)
        case .utility:              return DispatchQueue.global(qos: .utility)
        case .background:           return DispatchQueue.global(qos: .background)
        }
    }
}

extension TouchTaskViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)    {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [CIImageOption : Any]?)
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.right.rawValue))
        
        if let faceTrackingHelper = faceTrackingHelper {
                
            DispatchQueue.main.async {
                
                faceTrackingHelper.detectFace(on: ciImageWithOrientation, faceDetectionRequest: self.faceDetectionRequest, faceDetection: self.faceDetection, faceLandmarks: self.faceLandmarks, view: self.view, shapeLayer: self.shapeLayer, cameraView: self.cameraView)
            }
        }
    }
}

extension TouchTaskViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

struct Click {
    let x: CGFloat
    let y: CGFloat
    let lastX: CGFloat
    let lastY: CGFloat
    let a: CGFloat
    let b: CGFloat
    let dT: TimeInterval
    let id: CGFloat
    let distance: CGFloat
    let width: CGFloat
    let movementTime: CGFloat
    let onTarget: Bool
}
