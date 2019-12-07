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
        setupContentLabel()
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
            setupContentLabel()
            
            break
            
        case .didChangeWindowSizeToSmallOnReadingTask:
            
            updateWindowSize(size: .small)
            self.view.layoutIfNeeded()
            setupContentLabel()
            
            break
            
        case .didChangeWindowSizeToLargeOnReadingTask:
            
            updateWindowSize(size: .large)
            self.view.layoutIfNeeded()
            setupContentLabel()
            
            break
            
        case .didChangeToFirstTextOnReadingTask:
            break
            
        case .didChangeToSecondTextOnReadingTask:
            break
            
        case .didChangeToThirdTextOnReadingTask:
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
    
    private func setupContentLabel() {
        
        let text = "A lion was very angry with a gnat that kept flying and buzzing around his head. The gnat would not quit bothering the lion. “Do you think that you, the great king of all the animals, can make me scared?” the gnat said to the poor lion. The lion just kept trying to hit the gnat with his big paw. All he did was scratch himself with his great claws. The gnat laughed and flew between the big paws and stung the lion on the nose. He then buzzed away laughing at how he had stung the great lion. However, he was so busy thinking of how he would boast that he did not see the spider web. He got stuck in the web of a little spider and that was the end of him.A lion was very angry with a gnat that kept flying and buzzing around his head. The gnat would not quit bothering the lion. “Do you think that you, the great king of all the animals, can make me scared?” the gnat said to the poor lion. The lion just kept trying to hit the gnat with his big paw. All he did was scratch himself with his great claws. The gnat laughed and flew between the big paws and stung the lion on the nose. He then buzzed away laughing at how he had stung the great lion. However, he was so busy thinking of how he would boast that he did not see the spider web. He got stuck in the web of a little spider and that was the end of him.A lion was very angry with a gnat that kept flying and buzzing around his head. The gnat would not quit bothering the lion. “Do you think that you, the great king of all the animals, can make me scared?” the gnat said to the poor lion. The lion just kept trying to hit the gnat with his big paw. All he did was scratch himself with his great claws. The gnat laughed and flew between the big paws and stung the lion on the nose. He then buzzed away laughing at how he had stung the great lion. However, he was so busy thinking of how he would boast that he did not see the spider web. He got stuck in the web of a little spider and that was the end of him."
        
        let necessaryLabelHeight = heightForView(text: text, font: UIFont.systemFont(ofSize: 30), width: contentView.frame.width)
        
        let proportion = contentLabel.frame.height/necessaryLabelHeight
        
        textSplited = getTextToDisplay(text: text, proportion: proportion)
        
        self.contentLabel.isHidden = false
        self.contentLabel.text = textSplited[0]
        
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
            let height: CGFloat = width * 0.75 // porportion of (self.view.frame.height / self.view.frame.width)
            
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
            let height: CGFloat = width * 0.75 // porportion of (self.view.frame.height / self.view.frame.width)
            
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
    
    @IBAction func goToNextPageAction(_ sender: Any) {
        print("goToNextPage")
        updateLabelText(pageNumber: actualTextPage + 1)
    }
    
    @IBAction func goToPreviousPageAction(_ sender: Any) {
        
        print("goToPreviousPage")
        updateLabelText(pageNumber: actualTextPage - 1)
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

