//
//  ViewController.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 27.05.19.
//  Copyright © 2019 flock. All rights reserved.
//
// Based on https://medium.com/@saqibomer.cs/apple-vision-framework-and-facial-features-detection-1bc3f9f24ed8, https://www.youtube.com/watch?v=d0U5j89M6aI&t=903s
//

import UIKit
import AVFoundation
import Vision
import WebKit

class ReadingTaskViewController: UIViewController {
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var contentView: UIView!
    @IBOutlet var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var contentViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var contetViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet var contentViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var contentViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var pageCountLabel: UILabel!
    @IBOutlet var timerLabel: UILabel!
    
    var faceTrackingHelper: FaceTrackingHelper?
    var avSession: AVCaptureSession?
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    
    let shapeLayer = CAShapeLayer()
    
    var lastX: CGFloat?
    var lastY: CGFloat?
    let variationThreshold: CGFloat = 20
    var applyVariationThreshold = true
    
    var actualTextPage = 0
    var textSplited: [String] = []
    
    var actualWindowSize: Size = .small
    var actualText = ""
    
    var timer: Timer?
    var startTime: Double = 0
    var time: Double = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        deregisterForNotification()
        
        registerForNotification(name: .didEnableTrackingOnReadingTask)
        registerForNotification(name: .didDisableTrackingOnReadingTask)
        registerForNotification(name: .didChangeWindowSizeToSmallOnReadingTask)
        registerForNotification(name: .didChangeWindowSizeToLargeOnReadingTask)
        registerForNotification(name: .didChangeToFirstTextOnReadingTask)
        registerForNotification(name: .didChangeToSecondTextOnReadingTask)
        registerForNotification(name: .didChangeToThirdTextOnReadingTask)
        registerForNotification(name: .showHeadTrackingOnReadingTask)
        registerForNotification(name: .hideHeadTrackingOnReadingTask)
        
        cameraView.isHidden = true
        
        setupContentView()
        actualText = getFirstText()
        setupContentLabel(text: actualText)
    }
    
    override func receivedNotification(_ notification: Notification) {
        
        switch notification.name {
        case .didEnableTrackingOnReadingTask:
            
            activateFaceTracking()
            
            break
            
        case .didDisableTrackingOnReadingTask:
            
            deactivateFaceTracking()
            
            centralizeContentView()
            self.view.layoutIfNeeded()
            setupContentLabel(text: actualText)
            
            break
            
        case .didChangeWindowSizeToSmallOnReadingTask:
            
            updateWindowSize(size: .small)
            self.view.layoutIfNeeded()
            setupContentLabel(text: actualText)
            
            break
            
        case .didChangeWindowSizeToLargeOnReadingTask:
            
            updateWindowSize(size: .large)
            self.view.layoutIfNeeded()
            setupContentLabel(text: actualText)
            
            break
            
        case .didChangeToFirstTextOnReadingTask:
            
            actualText = getFirstText()
            self.view.layoutIfNeeded()
            setupContentLabel(text: actualText)
            
            break
            
        case .didChangeToSecondTextOnReadingTask:
            
            actualText = getSecondText()
            self.view.layoutIfNeeded()
            setupContentLabel(text: actualText)
            
            break
            
        case .didChangeToThirdTextOnReadingTask:
            
            actualText = getThirdText()
            self.view.layoutIfNeeded()
            setupContentLabel(text: actualText)
            
            break
            
        case .showHeadTrackingOnReadingTask:
            
            cameraView.isHidden = false
            
            break
            
        case .hideHeadTrackingOnReadingTask:
            
            cameraView.isHidden = true
            
            break
            
        default:
            break
        }
        
        self.view.layoutIfNeeded()
    }
    
    private func centralizeContentView() {
        
        switch actualWindowSize {
        case .small:
            
            contentViewBottomConstraint.constant = 150
            contetViewTraillingConstraint.constant = 210
            
            break
            
        case .large:
            
            contentViewBottomConstraint.constant = 75
            contetViewTraillingConstraint.constant = 125
        }
    }
    
    private func setupContentView() {
        
        centralizeContentView()
        contentView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        self.contentView.layer.borderWidth = 1
    }
    
    private func setupContentLabel(text: String) {
        
        let necessaryLabelHeight = heightForView(text: text, font: UIFont.systemFont(ofSize: 30), width: contentView.frame.width)
        
        let proportion = contentLabel.frame.height/necessaryLabelHeight
        
        textSplited = getTextToDisplay(text: text, proportion: proportion)
        
        self.contentLabel.isHidden = false
        self.contentLabel.text = textSplited[0]
        
        actualTextPage = 0
        
        updatePageCountLabel()
    }
    
    private func updatePageCountLabel() {
        pageCountLabel.text = "Page \(actualTextPage + 1) of \(textSplited.count)"
    }
    
    private func getTextToDisplay(text: String, proportion: CGFloat) -> [String] {
        
        var textDivided: [String] = []
            
        let parts = Int(ceil(1.0 / proportion))
        //let parts = Int(round(1.0 / proportion))
        
        if parts > 1 {
            
            let restOfDivision = text.count % parts
            let lengthOfEachPartOfTheText = text.count / parts
//            print("lengthOfEachPartOfTheText: \(lengthOfEachPartOfTheText)")
            
            textDivided = text.splitByLength(lengthOfEachPartOfTheText + restOfDivision)
        } else {
            textDivided = [text]
        }
        
        print("Parts: \(parts)")
        print("Text Divided: \(textDivided)")
        
        return textDivided
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat {
        
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text

        label.sizeToFit()
        
        return label.frame.height
    }
    
    private func activateFaceTracking() {
        
        avSession = AVCaptureSession()
        
        faceTrackingHelper = FaceTrackingHelper()
        
        if let faceTrackingHelper = faceTrackingHelper {
            
            faceTrackingHelper.initializeCameraSession(avSession: avSession, AVDelegate: self, cameraView: cameraView, widthConstraint: cameraViewWidthConstraint.constant, heightConstraint: cameraViewHeightConstraint.constant, shapeLayer: shapeLayer)
    
            faceTrackingHelper.bottomConstraint = contentViewBottomConstraint
            faceTrackingHelper.traillingConstraint = contetViewTraillingConstraint
                
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
        let contentViewWidth = self.contentView.frame.width
        let maximumTraillingConstraintValue = viewWidth - contentViewWidth - self.contentViewLeadingConstraint.constant
        
        return maximumTraillingConstraintValue
    }
    
    private func getMaximumBottomConstraintValue() -> CGFloat {
        
        let viewHeight = self.view.frame.height
        let contentViewHeight = self.contentView.frame.height
        let maximumBottomConstraint = viewHeight - contentViewHeight - self.contentViewTopConstraint.constant
        
        return maximumBottomConstraint
    }
    
    private func restartFaceTracking() {
        
        deactivateFaceTracking()
        activateFaceTracking()
    }
    
    private func updateWindowSize(size: Size) {
        
        switch size {
        case .small:
            
            let width: CGFloat = 600
            let height: CGFloat = 450 // porportion of (self.view.frame.height / self.view.frame.width)
            
            self.contentViewWidthConstraint.constant = width
            self.contentViewHeightConstraint.constant = height
            
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
            
            self.contentViewWidthConstraint.constant = width
            self.contentViewHeightConstraint.constant = height
            
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
    
    func getTime() ->NSDate {
        
        let timestamp = NSDate().timeIntervalSince1970
        let myTimeInterval = TimeInterval(timestamp)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        
        return time
    }
    
    private func updateLabelText(pageNumber: Int) {
        
        if pageNumber >= 0 && pageNumber < textSplited.count {
            actualTextPage = pageNumber
            contentLabel.text = textSplited[pageNumber]
            updatePageCountLabel()
            view.layoutIfNeeded()
        }
    }
    
    private func getFirstText() -> String {
        
        return "The Crow & the Pitcher \n\nIn a spell of dry weather, when the Birds could find very little to drink, a thirsty Crow found a pitcher with a little water in it. But the pitcher was high and had a narrow neck, and no matter how he tried, the Crow could not reach the water. The poor thing felt as if he must die of thirst. Then an idea came to him. Picking up some small pebbles, he dropped them into the pitcher one by one. With each pebble the water rose a little higher until at last it was near enough so he could drink."
    }
    
    private func getSecondText() -> String {
        
        return "The Plane Tree \n\nTwo Travellers, walking in the noonday sun, sought the shade of a widespreading tree to rest. As they lay looking up among the pleasant leaves, they saw that it was a Plane Tree. \"How useless is the Plane!\" said one of them. \"It bears no fruit whatever, and only serves to litter the ground with leaves.\" \n\"Ungrateful creatures!\" said a voice from the Plane Tree. \"You lie here in my cooling shade, and yet you say I am useless! Thus ungratefully, O Jupiter, do men receive their blessings!\""
        
    }
    
    private func getThirdText() -> String {
        
        return "TEXTO 3: A cigarra e a formiga \n\nA Wolf had been feasting too greedily, and a bone had stuck crosswise in his throat. He could get it neither up nor down, and of course he could not eat a thing. Naturally that was an awful state of affairs for a greedy Wolf. So away he hurried to the Crane. He was sure that she, with her long neck and bill, would easily be able to reach the bone and pull it out. \"I will reward you very handsomely,\" said the Wolf, \"if you pull that bone out for me.\" The Crane, as you can imagine, was very uneasy about putting her head in a Wolf's throat. But she was grasping in nature, so she did what the Wolf asked her to do. When the Wolf felt that the bone was gone, he started to walk away. \"But what about my reward!\" called the Crane anxiously. \"What!\" snarled the Wolf, whirling around. \"Haven't you got it? Isn't it enough that I let you take your head out of my mouth without snapping it off?\""
    }
    
    private func startTimer() {
        
        startTime = Date().timeIntervalSinceReferenceDate
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func updateTimer() {
        
        time = Date().timeIntervalSinceReferenceDate - startTime
        
        let minutes = UInt8(time / 60.0)
        time -= (TimeInterval(minutes) * 60)
        
        let seconds = UInt8(time)
        time -= TimeInterval(seconds)
        
        //let milliseconds = UInt8(time * 100)
        
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        //let strMilliseconds = String(format: "%02d", milliseconds)
        
        timerLabel?.text = "\(strMinutes):\(strSeconds)"
    }
    
    @IBAction func goToNextPageAction(_ sender: Any) {
        print("goToNextPage")
        updateLabelText(pageNumber: actualTextPage + 1)
    }
    
    @IBAction func goToPreviousPageAction(_ sender: Any) {
        
        print("goToPreviousPage")
        updateLabelText(pageNumber: actualTextPage - 1)
    }
    
    @IBAction func startOrStopTimerAction(_ sender: Any) {
        
        if self.timer == nil {
            
            startTimer()
            
        } else {
            
            stopTimer()
        }
    }
    
}

extension ReadingTaskViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)    {
        
        //print("Frame captured at \(getTime())")
        
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

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}

enum Size {
    case small
    case large
}

