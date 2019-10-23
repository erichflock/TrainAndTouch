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

class TouchViewController: UIViewController {

    @IBOutlet var touchAreaView: UIView!
    
    @IBOutlet var touchAreaViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var touchAreaViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraViewHeightConstraint: NSLayoutConstraint!
    
    let borderLimitThreshold: CGFloat = 5.0
    
    var width: CGFloat = 0
    var distance: CGFloat = 0
    
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
        
        initializeCameraSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let avSession = self.avSession {
            avSession.stopRunning()
        }
        
        avSession = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.touchAreaView.layer.borderWidth = 1
        self.touchAreaView.layer.borderColor = UIColor(red:222/255, green:225/255, blue:227/255, alpha: 1).cgColor
        
        startTouchGame( )
    }

    func initializeCameraSession() {
        
        avSession = AVCaptureSession()
        
        if let avSession = avSession {
        
            // Get camera devices
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices
            
            // Select a capture device
            do {
                if let captureDevice = devices.first {
                    let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                    avSession.addInput(captureDeviceInput)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            // Show output on a preview layer
            let captureOutput = AVCaptureVideoDataOutput()
            captureOutput.setSampleBufferDelegate(self, queue:
                DispatchQueue(label: "videoQueue"))
            avSession.addOutput(captureOutput)
            
            let layer = AVCaptureVideoPreviewLayer(session: avSession)
            
            let frameWidth = cameraViewWidthConstraint.constant
            let frameHeight = cameraViewHeightConstraint.constant
            
            layer.frame = CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight)
            layer.connection?.videoOrientation = .landscapeRight
            cameraView.layer.addSublayer(layer)
            
            shapeLayer.frame = cameraView.bounds
            
            //needs to filp coordinate system for Vision
            shapeLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
            
            cameraView.layer.addSublayer(shapeLayer)
            
            avSession.startRunning()
        }
    }

    func detectFace(on image: CIImage) {
        
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                //print("Face Detected")
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                }
            }
        }
    }
    
    func detectLandmarks(on image: CIImage) {
        
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                DispatchQueue.main.async {
                    
                    if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        
                        //As we are going to move the content in the whole screen, we have to scale the bounding box to the view size. Plus, we have to use its dimension to compute the exact position to move the content.
                        let faceBoundingBox = boundingBox.scaled(to: self.view.bounds.size)
                        
                        if let leftPupilLandmarkPoint = observation.landmarks?.leftPupil {
                            if let point = leftPupilLandmarkPoint.normalizedPoints.first {
                                self.moveTouchAreaView(x: CGFloat(point.x), y: CGFloat(point.y), boundingBox: faceBoundingBox)
                            }
                        }
                    }
                    
                    //Uncomment the following lines to draw the face contour
                    if let boundingBox =    self.faceLandmarks.inputFaceObservations?.first?.boundingBox {

                        let faceBoundingBox = boundingBox.scaled(to: self.cameraView.bounds.size)
                        let faceContour = observation.landmarks?.allPoints
                        self.convertPointsForFace(faceContour, faceBoundingBox)
                    }
                }
            }
        }
    }
    
    func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) {
        if let points = landmark?.normalizedPoints{
            
            //Use faceLandmarkVertices to move the content
            let faceLandmarkVertices = points.map { (point: (CGPoint)) -> Vertex in
                let pointX = point.x * boundingBox.width + boundingBox.origin.x
                let pointY = point.y * boundingBox.height + boundingBox.origin.y
                
                return Vertex(x: Double(pointX), y: Double(pointY))
            }
            
            DispatchQueue.main.async {
                self.draw(vertices: faceLandmarkVertices, boundingBox: boundingBox)
            }
        }
    }
    
    func draw(vertices: [Vertex], boundingBox: CGRect) {
        
        let triangles = Delaunay().triangulate(vertices)
        
        for triangle in triangles {
            let triangleLayer = CAShapeLayer()
            
            triangleLayer.path = triangle.toPath()
            triangleLayer.strokeColor = UIColor.blue.cgColor
            triangleLayer.lineWidth = 1.0
            triangleLayer.fillColor = UIColor.clear.cgColor
            triangleLayer.backgroundColor = UIColor.clear.cgColor
            shapeLayer.addSublayer(triangleLayer)
        }
    }
    
    func moveTouchAreaView(x: CGFloat, y: CGFloat, boundingBox: CGRect) {
        
        let pointX = x + boundingBox.origin.x
        let pointY = y + boundingBox.origin.y
        
        let userHasStoppedMovingHisHead = !hasMovedVertically(point: pointY) && !hasMovedHorizontally(point: pointX)
        
        if userHasStoppedMovingHisHead {
            return
        } else {
            updateTouchAreaViewBottomConstraint(pointY, speed: 0.3)
            updateTouchAreaViewTraillingConstraint(pointX, speed: 0.4 )
        }
    }
    
    private func updateTouchAreaViewBottomConstraint(_ pointY: CGFloat, speed: CGFloat) {
        touchAreaViewBottomConstraint.constant = pointY * speed
        lastY = pointY
    }
    
    private func updateTouchAreaViewTraillingConstraint(_ pointX: CGFloat, speed: CGFloat) {
        touchAreaViewTraillingConstraint.constant = pointX * speed
        lastX = pointX
    }
    
    //MARK: AUX Functions
    
    func hasMovedHorizontally(point: CGFloat) ->Bool {
        
        guard let lastX = lastX else {
            return true
        }
        
        let difference = point - lastX
        
        if difference > variationThreshold || difference < -variationThreshold {
            return true
        }
        
        return false
    }
    
    func hasMovedVertically(point: CGFloat) ->Bool {
        
        guard let lastY = lastY else {
            return true
        }
        
        let difference = point - lastY
        
        if difference > variationThreshold || difference < -variationThreshold {
            return true
        }
        
        return false
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

extension TouchViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)    {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [CIImageOption : Any]?)
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.right.rawValue))
        detectFace(on: ciImageWithOrientation)
    }
}
