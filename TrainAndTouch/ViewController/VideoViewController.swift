//
//  VideoViewController.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 25.06.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import Vision
import AVFoundation

class VideoViewController : UIViewController {
    
    @IBOutlet var videoWebView: WKWebView!
    @IBOutlet var videoWebViewTraillingConstraint: NSLayoutConstraint!
    @IBOutlet var videoWebViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraViewHeightConstraint: NSLayoutConstraint!
    
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
        
        loadVideo(videoID: "SgYeEor6Q6o")
        
        initializeCameraSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let avSession = self.avSession {
            avSession.stopRunning()
        }
        
        avSession = nil
    }
    
    private func loadVideo(videoID: String) {
        
        guard let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)") else { return }
        
        videoWebView.load( URLRequest(url: youtubeURL) )
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
                                self.moveVideoWebView(x: CGFloat(point.x), y: CGFloat(point.y), boundingBox: faceBoundingBox)
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
    
    func moveVideoWebView(x: CGFloat, y: CGFloat, boundingBox: CGRect) {
        
        let pointX = x + boundingBox.origin.x
        let pointY = y + boundingBox.origin.y
        
        let userHasStoppedMovingHisHead = !hasMovedVertically(point: pointY) && !hasMovedHorizontally(point: pointX)
        
        if userHasStoppedMovingHisHead {
            return
        } else {
            updateContentLabelBottomConstraint(pointY, speed: 0.3)
            updateContentLabekTraillingConstraint(pointX, speed: 0.4 )
        }
    }
    
    private func updateContentLabelBottomConstraint(_ pointY: CGFloat, speed: CGFloat) {
        videoWebViewBottomConstraint.constant = pointY * speed
        lastY = pointY
    }
    
    private func updateContentLabekTraillingConstraint(_ pointX: CGFloat, speed: CGFloat) {
        videoWebViewTraillingConstraint.constant = pointX * speed
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
    
    @IBAction func showCameraView(_ sender: Any) {
        
        if cameraView.isHidden {
            cameraView.isHidden = false
        } else {
            cameraView.isHidden = true
        }
    }
    
}

extension VideoViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)    {
        
        //print("Frame captured at \(getTime())")
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [CIImageOption : Any]?)
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.right.rawValue))
        detectFace(on: ciImageWithOrientation)
    }
}
