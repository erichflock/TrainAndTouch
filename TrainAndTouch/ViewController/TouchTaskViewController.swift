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

class TouchTaskViewController: UIViewController {

    @IBOutlet var touchAreaView: UIView!
    
    @IBOutlet var touchAreaViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var touchAreaViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraViewHeightConstraint: NSLayoutConstraint!
    
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
    let variationThreshold: CGFloat = 20
    var applyVariationThreshold = true
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        avSession = AVCaptureSession()
        
        activateFaceTracking()
        
        startTouchGame( )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        deactivateFaceTracking()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTouchAreaView()
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
        }
    }
    
    private func deactivateFaceTracking() {
        
        if let avSession = self.avSession {
            avSession.stopRunning()
        }
        
        avSession = nil
        
        faceTrackingHelper = nil
    }
    
    func startTouchGame() {
        
        //Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(callback), userInfo: nil, repeats: true)
        
        addCircleOnTouchAreaView()

    }
    
    @objc func callback() {
        
        addCircleOnTouchAreaView()
        
        print("Circle Added")
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        
        print("Circle touched")
        
        //remove previous circle
        touchAreaView.subviews.forEach({ $0.removeFromSuperview() })
        
        addCircleOnTouchAreaView()
    }

    private func addCircleOnTouchAreaView() {
        
        let xStartPoint: CGFloat = 0
        let yStartPoint: CGFloat = 0
        
        width = getRandomWidth()
        
        let randomX = getRandomPositon(startPoint: xStartPoint, constraint: self.touchAreaView.frame.width)
        let randomY = getRandomPositon(startPoint: yStartPoint, constraint: self.touchAreaView.frame.height)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        
        print("Width: \(width)")
        print("Random X: \(randomX), Random Y: \(randomY)")
        
        let circleView = UIView(frame: CGRect(x: randomX, y: randomY, width: width, height: width))
        
        circleView.layer.cornerRadius = circleView.bounds.size.width / 2 // circle shape
        circleView.backgroundColor = .red
        
        circleView.addGestureRecognizer(tap)
        self.touchAreaView.addSubview(circleView)
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
    
    private func getNextDistance(lastX: CGFloat, lastY: CGFloat) -> CGFloat{
        
        let newX = getRandomPositon(startPoint: 0, constraint: touchAreaView.frame.width)
        let newY = getRandomPositon(startPoint: 0, constraint: touchAreaView.frame.height)

        let diffX = newX - lastX
        let diffY = newY - lastY
        
        let distance = CGFloat(sqrtf(Float(diffX * diffX + diffY * diffY))) - width / 2
        
        return distance
    }
    
    @IBAction func showCameraView(_ sender: Any) {
        
        if cameraView.isHidden {
            cameraView.isHidden = false
        } else {
            cameraView.isHidden = true
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
