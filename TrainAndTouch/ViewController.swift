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
    
    // Properties
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    
    var leftEyeImageView  : UIImageView!
    var rightEyeImageView : UIImageView!
    
    let shapeLayer = CAShapeLayer()
    
    var session: AVCaptureSession?
    let previewRect = CGRect(x: 10, y: 10, width: 10, height: 10)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeCameraSession()
    }
    
    func initializeCameraSession() {
        
        //1: Create a new AV Session
        let avSession = AVCaptureSession()
        
        // Get camera devices
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .front).devices
        
        //2: Select a capture device
        do {
            if let captureDevice = devices.first {
                let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                avSession.addInput(captureDeviceInput)
            }
        } catch {
            print(error.localizedDescription)
        }
        
        //3: Show output on a preview layer
        let captureOutput = AVCaptureVideoDataOutput()
        captureOutput.setSampleBufferDelegate(self, queue:
            DispatchQueue(label: "videoQueue"))
        avSession.addOutput(captureOutput)
        
        let layer = AVCaptureVideoPreviewLayer(session: avSession)
        
        layer.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        layer.connection?.videoOrientation = .landscapeRight
        cameraView.layer.addSublayer(layer)
        
        shapeLayer.frame = cameraView.bounds
        shapeLayer.strokeColor = UIColor.blue.cgColor
        shapeLayer.lineWidth = 4.0
        
        //needs to filp coordinate system for Vision
        shapeLayer.setAffineTransform(CGAffineTransform(scaleX: -1, y: -1))
        
        cameraView.layer.addSublayer(shapeLayer)
        
        avSession.startRunning()
    }
    
    func detectFace(on image: CIImage) {
        
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                print("Face Detected")
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
        let newLayer = CAShapeLayer()
        newLayer.strokeColor = UIColor.blue.cgColor
        newLayer.lineWidth = 4.0
        var newVertices = vertices
        
        newVertices.remove(at: newVertices.count - 1)
        
        
        let triangles = Delaunay().triangulate(newVertices)
        
        for triangle in triangles {
            let triangleLayer = CAShapeLayer()
            
            triangleLayer.path = triangle.toPath()
            triangleLayer.strokeColor = UIColor.red.cgColor
            triangleLayer.lineWidth = 1.0
            triangleLayer.fillColor = UIColor.clear.cgColor
            triangleLayer.backgroundColor = UIColor.clear.cgColor
            shapeLayer.addSublayer(triangleLayer)
        }
    }
    
    func drawRectangle(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        
        if let viewWithTag = self.cameraView.viewWithTag(100) {
            viewWithTag.removeFromSuperview()
        }
        
        let redView = UIView()
        redView.tag = 100
        redView.backgroundColor = .red
        redView.alpha = 0.20
        redView.frame = CGRect(x: x, y: y, width: width, height: height)
        
        self.cameraView.addSubview(redView)
    }
    
    func convert(_ points: UnsafePointer<vector_float2>, with count: Int) -> [(x: CGFloat, y: CGFloat)] {
        
        var convertedPoints = [(x: CGFloat, y: CGFloat)]()
        
        for i in 0...count {
            convertedPoints.append((CGFloat(points[i].x),  CGFloat(points[i].y)))
        }
        
        return convertedPoints
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
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImage.Orientation.right             .rawValue))
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


