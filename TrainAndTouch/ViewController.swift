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

class ViewController: UIViewController {
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var contentLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet var contentLabelTraillingConstant: NSLayoutConstraint!
    
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    
    let shapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraView.isHidden = false
        
        initializeCameraSession()
    }
    
    func initializeCameraSession() {
        
        // Create a new AV Session
        let avSession = AVCaptureSession()
        
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
                        
                        let faceBoundingBox = boundingBox.scaled(to: self.view.bounds.size)
                        
                        if let leftPupilLandmarkPoint = observation.landmarks?.leftPupil {
                            if let point = leftPupilLandmarkPoint.normalizedPoints.first {
                                self.moveContentLabel(x: CGFloat(point.x), y: CGFloat(point.y), boundingBox: faceBoundingBox)
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
            
//            print("Amount of Points: \(points.count)")
//            let x = points.first?.x ?? 0
//            let y = points.first?.y ?? 0
//            print("X: \(x), Y: \(y)")
            
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
    
    func moveContentLabel(x: CGFloat, y: CGFloat, boundingBox: CGRect) {
        
        let pointX = x * boundingBox.width + boundingBox.origin.x
        let pointY = y * boundingBox.height + boundingBox.origin.y

        contentLabelBottomConstraint.constant = pointY
        contentLabelTraillingConstant.constant = pointX
    }
    
    //MARK: AUX Functions
    func getTime() ->NSDate {
        
        let timestamp = NSDate().timeIntervalSince1970
        let myTimeInterval = TimeInterval(timestamp)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        
        return time
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)    {
        
        //print("Frame captured at \(getTime())")
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [CIImageOption : Any]?)
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.right.rawValue))
        detectFace(on: ciImageWithOrientation)
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


