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

class BookViewController: UIViewController {
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var cameraViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var cameraViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var contentLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet var contentLabelTraillingConstraint: NSLayoutConstraint!
    
    @IBOutlet var pdfWebView: WKWebView!
    @IBOutlet var pdfWebViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var pdfWebViewBottomConstraint: NSLayoutConstraint!
    
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
        
        //loadPdf()
        
        self.pdfWebView.isHidden = true
        
        self.contentLabel.isHidden = false
        self.contentLabel.text = "A lion was very angry with a gnat that kept flying and buzzing around his head. The gnat would not quit bothering the lion. “Do you think that you, the great king of all the animals, can make me scared?” the gnat said to the poor lion. The lion just kept trying to hit the gnat with his big paw. All he did was scratch himself with his great claws. The gnat laughed and flew between the big paws and stung the lion on the nose. He then buzzed away laughing at how he had stung the great lion. However, he was so busy thinking of how he would boast that he did not see the spider web. He got stuck in the web of a little spider and that was the end of him."
        
        cameraView.isHidden = true
        
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
                                self.moveContentLabel(x: CGFloat(point.x), y: CGFloat(point.y), boundingBox: faceBoundingBox)
                                //self.movePdfWebView(x: CGFloat(point.x), y: CGFloat(point.y), boundingBox: faceBoundingBox)
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
    
    private func updateContentLabelBottomConstraint(_ pointY: CGFloat, speed: CGFloat) {
        contentLabelBottomConstraint.constant = pointY * speed
        lastY = pointY
    }
    
    private func updateContentLabekTraillingConstraint(_ pointX: CGFloat, speed: CGFloat) {
        contentLabelTraillingConstraint.constant = pointX * speed
        lastX = pointX
    }
    
    func moveContentLabel(x: CGFloat, y: CGFloat, boundingBox: CGRect) {
        
        let pointX = x + boundingBox.origin.x
        let pointY = y + boundingBox.origin.y
        
        let userHasStoppedMovingHisHead = !hasMovedVertically(point: pointY) && !hasMovedHorizontally(point: pointX)
        
        if userHasStoppedMovingHisHead {
            return
        } else {
            updateContentLabelBottomConstraint(pointY, speed: 0.2)
            updateContentLabekTraillingConstraint(pointX, speed: 0.25)
        }
        
//        if hasMovedVertically(point: pointY) {
//            updateContentLabelBottomConstraint(pointY, speed: 0.2)
//        }
//
//        if hasMovedHorizontally(point: pointX) {
//            updateContentLabekTraillingConstraint(pointX, speed: 0.3)
//        }
    }
    
    func movePdfWebView(x: CGFloat, y: CGFloat, boundingBox: CGRect) {
        
        let pointX = x + boundingBox.origin.x
        let pointY = y + boundingBox.origin.y
        
//        print("X: \(pointX)")
//        print("Y: \(pointY)")
        
        if hasMovedHorizontally(point: pointX) || hasMovedVertically(point: pointY) {
            pdfWebViewTrailingConstraint.constant = pointX * 0.47
            pdfWebViewBottomConstraint.constant = pointY * 0.3
            lastX = pointX
            lastY = pointY
        }
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
    
    func hasStopped() {
        
    }
    
    func getTime() ->NSDate {
        
        let timestamp = NSDate().timeIntervalSince1970
        let myTimeInterval = TimeInterval(timestamp)
        let time = NSDate(timeIntervalSince1970: TimeInterval(myTimeInterval))
        
        return time
    }
    
    func loadPdf() {
        
        if let pdf = Bundle.main.url(forResource: "Norman_AffordanceConventionsAndDesign", withExtension: "pdf", subdirectory: "Files")  {
            let request = NSURLRequest(url: pdf)
            pdfWebView.load(request as URLRequest)
        }
    }
    
    @IBAction func showOrHideCameraView(_ sender: Any) {
        
        if cameraView.isHidden {
            cameraView.isHidden = false
        } else {
            cameraView.isHidden = true
        }
    }
    
}

extension BookViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
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


