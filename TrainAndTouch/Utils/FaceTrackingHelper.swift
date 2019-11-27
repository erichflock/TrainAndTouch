//
//  FaceTrackingHelper.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 02.11.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation
import UIKit
import Vision
import AVFoundation

class FaceTrackingHelper: UIViewController {
    
    var lastVerticalPosition: CGFloat = 0
    var lastHorizontalPosition: CGFloat = 0
    let variationThreshold: CGFloat = 20
    
    var bottomConstraint: NSLayoutConstraint?
    var traillingConstraint: NSLayoutConstraint?
    var maximumTraillingConstraintValue: CGFloat?
    var maximumBottomConstraintValue: CGFloat?
    var minimumBottomConstraintValue: CGFloat?
    var minimumLeadingConstraintValue: CGFloat?
    var speed: CGFloat?
    
    public class var sharedInstance: FaceTrackingHelper {
        
        struct Static {
            static let instance : FaceTrackingHelper = FaceTrackingHelper()
        }
        
        return Static.instance
    }
    
    func initializeCameraSession(avSession: AVCaptureSession?, AVDelegate: AVCaptureVideoDataOutputSampleBufferDelegate, cameraView: UIView, widthConstraint: CGFloat, heightConstraint: CGFloat, shapeLayer: CAShapeLayer) {
        
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
            captureOutput.setSampleBufferDelegate(AVDelegate, queue:
                DispatchQueue(label: "videoQueue"))
            avSession.addOutput(captureOutput)
            
            let layer = AVCaptureVideoPreviewLayer(session: avSession)
            
            let frameWidth = widthConstraint
            let frameHeight = heightConstraint
            
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
    
    func detectFace(on image: CIImage, faceDetectionRequest: VNSequenceRequestHandler, faceDetection: VNDetectFaceRectanglesRequest, faceLandmarks: VNDetectFaceLandmarksRequest, view: UIView, shapeLayer: CAShapeLayer, cameraView: UIView) {
        
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                //print("Face Detected")
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image, faceLandmarksDetectionRequest: faceDetectionRequest, faceLandmarks: faceLandmarks, view: view, cameraView: cameraView, shapeLayer: shapeLayer)
                DispatchQueue.main.async {
                    shapeLayer.sublayers?.removeAll()
                }
            }
        }
    }
    
    func detectLandmarks(on image: CIImage, faceLandmarksDetectionRequest: VNSequenceRequestHandler, faceLandmarks: VNDetectFaceLandmarksRequest, view: UIView, cameraView: UIView, shapeLayer: CAShapeLayer) {
        
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                DispatchQueue.main.async {
                    
                    if let boundingBox = faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        
                        //As we are going to move the content in the whole screen, we have to scale the bounding box to the view size. Plus, we have to use its dimension to compute the exact position to move the content.
                        let faceBoundingBox = boundingBox.scaled(to: view.bounds.size)
                        
                        if let leftPupilLandmarkPoint = observation.landmarks?.leftPupil {
                            if let point = leftPupilLandmarkPoint.normalizedPoints.first {

                                self.moveContentLabel(x: CGFloat(point.x), y: CGFloat(point.y), boundingBox: faceBoundingBox)
                            }
                        }
                    }
                    
                    //Uncomment the following lines to draw the face contour
                    if let boundingBox = faceLandmarks.inputFaceObservations?.first?.boundingBox {

                        let faceBoundingBox = boundingBox.scaled(to: cameraView.bounds.size)
                        let faceContour = observation.landmarks?.allPoints
                        self.convertPointsForFace(faceContour, faceBoundingBox, shapeLayer: shapeLayer)
                    }
                }
            }
        }
    }
    
    func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect, shapeLayer: CAShapeLayer) {
        if let points = landmark?.normalizedPoints{
            
            let faceLandmarkVertices = points.map { (point: (CGPoint)) -> Vertex in
                let pointX = point.x * boundingBox.width + boundingBox.origin.x
                let pointY = point.y * boundingBox.height + boundingBox.origin.y
                
                return Vertex(x: Double(pointX), y: Double(pointY))
            }
            
            DispatchQueue.main.async {
                self.draw(vertices: faceLandmarkVertices, boundingBox: boundingBox, shapeLayer: shapeLayer)
            }
        }
    }
    
    func draw(vertices: [Vertex], boundingBox: CGRect, shapeLayer: CAShapeLayer) {
        
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
    
    private func hasReachedLeftBorder(constant: CGFloat) -> Bool {
            
        if let maximumTraillingConstraintValue = self.maximumTraillingConstraintValue {
            
            if constant > maximumTraillingConstraintValue {
                return true
            }
        }
        return false
    }
    
    private func hasReachedRightBorder(constant: CGFloat) -> Bool {
        
        if let minimumLeadingConstraintValue = self.minimumLeadingConstraintValue {
            
            if constant < minimumLeadingConstraintValue {
                return true
            }
        }
        return false
    }
    
    private func hasReachedTopBorder(constant: CGFloat) -> Bool {
            
        if let maximumBottomConstraintValue = self.maximumBottomConstraintValue {
            
            if constant > maximumBottomConstraintValue {
                return true
            }
        }
        return false
    }
    
    private func hasReachedBottomBorder(constant: CGFloat) -> Bool {
            
        if let minimumBottomConstraintValue = self.minimumBottomConstraintValue {
            
            if constant < minimumBottomConstraintValue {
                return true
            }
        }
        return false
    }
    
    private func updateContentConstraint(_ point: CGFloat, speed: CGFloat, constraint: NSLayoutConstraint, movement: Movement) {
        
        let constant = point * speed
        
        switch movement {
            
        case .Horizontal:
            
            if !hasReachedLeftBorder(constant: constant) && !hasReachedRightBorder(constant: constant) {
                constraint.constant = constant
            }
            
            lastHorizontalPosition = point
            
            break
            
        case .Vertical:
            
            if !hasReachedTopBorder(constant: constant) && !hasReachedBottomBorder(constant: constant){
                constraint.constant = constant
            }
            
            lastVerticalPosition = point
            
            break
        }
        
    }
    
    func moveContentLabel(x: CGFloat, y: CGFloat, boundingBox: CGRect) {
        
        let pointX = x + boundingBox.origin.x
        let pointY = y + boundingBox.origin.y
        
        let userHasStoppedMovingHisHead = !hasMovedVertically(point: pointY, lastVerticalPosition: lastVerticalPosition, variationThreshold: variationThreshold) && !hasMovedHorizontally(point: pointX, lastHorizontalPosition: lastHorizontalPosition, variationThreshold: variationThreshold)
        
        if userHasStoppedMovingHisHead {
            return
        } else {
            
            if let traillingConstraint = traillingConstraint {
                updateContentConstraint(pointX, speed: self.speed ?? 0.5, constraint: traillingConstraint, movement: .Horizontal)
            }
            
            if let bottomConstraint = bottomConstraint {
                updateContentConstraint(pointY, speed: self.speed ?? 0.5, constraint: bottomConstraint, movement: .Vertical)
            }
        }
    }
    
    //MARK: AUX Functions
    
    func hasMovedHorizontally(point: CGFloat, lastHorizontalPosition: CGFloat?, variationThreshold: CGFloat) ->Bool {
        
        guard let lastHorizontalPosition = lastHorizontalPosition else {
            return true
        }
        
        let difference = point - lastHorizontalPosition
        
        if difference > variationThreshold || difference < -variationThreshold {
            return true
        }
        
        return false
    }
    
    func hasMovedVertically(point: CGFloat, lastVerticalPosition: CGFloat?, variationThreshold: CGFloat) ->Bool {
        
        guard let lastVerticalPosition = lastVerticalPosition else {
            return true
        }
        
        let difference = point - lastVerticalPosition
        
        if difference > variationThreshold || difference < -variationThreshold {
            return true
        }
        
        return false
    }
}

enum Movement {
    case Vertical
    case Horizontal
}
