//
//  ViewController.swift
//  IMH
//
//  Created by admin user on 30/11/20.
//

import UIKit
import Photos
import Vision
import AVFoundation

// MARK: - View controller for registering face images with progress bars
class ViewController : UIViewController, RegistrationDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    private let progressBar = ProgressBar(numberOfBars: 15)
    // MARK: - Instantiate a session to get data from input devices: camera, mic, etc.
   private let captureSession = AVCaptureSession()
    
    private var usingFrontCamera = false
    var currentCaptureDevice: AVCaptureDevice?
    
    var stillImageOutput: AVCaptureStillImageOutput?
    
    var registerationImages : [UIImage] = []
    var image: UIImage!
    private var toastMessage = ""
    // MARK: - Preview layer for displaying the camera feed
   private lazy var previewLayerVideo = AVCaptureVideoPreviewLayer(session: self.captureSession)
    
    // MARK: - To save the current frame
    private var frame : CMSampleBuffer!
    // MARK: - To handle and control the output data
   private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let context = CIContext()
    
    // MARK: - To hold the instances of drawings from detection results
   private var drawings: [CAShapeLayer] = []
    
   override func viewDidLoad() {

     super.viewDidLoad()
     self.addCameraInput()
//
     self.getCameraFrames()
//    // MARK: - Tell the captureSession to start coordinating its input, preview and outputs
//
    self.showCameraFeed()
    self.captureSession.startRunning()
    // MARK: - Initalize all the bars
    let imageName = "whitebar.png"
    let imageUiBar = "uiBar.png"
    let image = UIImage(named: imageName)
    let imageBar = UIImage(named: imageUiBar)
    let leftBar1 = UIImageView(image: image!)
    let leftBar2 = UIImageView(image: image!)
    let leftBar3 = UIImageView(image: image!)
    let leftMidBar1 = UIImageView(image: image!)
    let leftMidBar2 = UIImageView(image: image!)
    let leftMidBar3 = UIImageView(image: image!)
    let midBar1 = UIImageView(image: image!)
    let midBar2 = UIImageView(image: image!)
    let midBar3 = UIImageView(image: image!)
    let rightMidBar1 = UIImageView(image: image!)
    let rightMidBar2 = UIImageView(image: image!)
    let rightMidBar3 = UIImageView(image: image!)
    let rightBar1 = UIImageView(image: image!)
    let rightBar2 = UIImageView(image: image!)
    let rightBar3 = UIImageView(image: image!)
    let uiBar = UIImageView(image: imageBar!)
    //Add bars to camera view
    view.addSubview(leftBar1)
    view.addSubview(leftBar2)
    view.addSubview(leftBar3)
    view.addSubview(leftMidBar1)
    view.addSubview(leftMidBar2)
    view.addSubview(leftMidBar3)
    view.addSubview(midBar1)
    view.addSubview(midBar2)
    view.addSubview(midBar3)
    view.addSubview(rightMidBar1)
    view.addSubview(rightMidBar2)
    view.addSubview(rightMidBar3)
    view.addSubview(rightBar1)
    view.addSubview(rightBar2)
    view.addSubview(rightBar3)
    view.addSubview(uiBar)
    //Set bar positions
    leftBar1.frame = CGRect(x:17,y:69,width: 30,height: 20)
    leftBar2.frame = CGRect(x:42,y:69,width: 30,height: 20)
    leftBar3.frame = CGRect(x:67,y:69,width: 30,height: 20)
    leftMidBar1.frame = CGRect(x:92,y:69,width: 30,height: 20)
    leftMidBar2.frame = CGRect(x:117,y:69,width: 30,height: 20)
    leftMidBar3.frame = CGRect(x:142,y:69,width: 30,height: 20)
    midBar1.frame = CGRect(x:167,y:69,width: 30,height: 20)
    midBar2.frame = CGRect(x:192,y:69,width: 30,height: 20)
    midBar3.frame = CGRect(x:217,y:69,width: 30,height: 20)
    rightMidBar1.frame = CGRect(x:242,y:69,width: 30,height: 20)
    rightMidBar2.frame = CGRect(x:267,y:69,width: 30,height: 20)
    rightMidBar3.frame = CGRect(x:292,y:69,width: 30,height: 20)
    rightBar1.frame = CGRect(x:317,y:69,width: 30,height: 20)
    rightBar2.frame = CGRect(x:342,y:69,width: 30,height: 20)
    rightBar3.frame = CGRect(x:367,y:69,width: 30,height: 20)
    uiBar.frame = CGRect(x: 45, y: 92, width: 328, height: 31)
    //Bring them all to the front of camera view
    self.view.bringSubviewToFront(leftBar1)
    self.view.bringSubviewToFront(leftBar2)
    self.view.bringSubviewToFront(leftBar3)
    self.view.bringSubviewToFront(leftMidBar1)
    self.view.bringSubviewToFront(leftMidBar2)
    self.view.bringSubviewToFront(leftMidBar3)
    self.view.bringSubviewToFront(midBar1)
    self.view.bringSubviewToFront(midBar2)
    self.view.bringSubviewToFront(midBar3)
    self.view.bringSubviewToFront(rightMidBar1)
    self.view.bringSubviewToFront(rightMidBar2)
    self.view.bringSubviewToFront(rightMidBar3)
    self.view.bringSubviewToFront(rightBar1)
    self.view.bringSubviewToFront(rightBar2)
    self.view.bringSubviewToFront(rightBar3)
    self.view.bringSubviewToFront(uiBar)
    
//    // MARK: - Set up button to change back / front camera
//    let button = UIButton(frame: CGRect(x: 185, y: 730, width: 80, height: 80))
//    button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
//    button.setImage(UIImage(named: "cameraflipblack"), for: .normal)
//    self.view.addSubview(button)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print(#function)
        // MARK: - present the toast message to show whether registration failed or successful
        self.showToast(message: self.toastMessage, font: .systemFont(ofSize: 12.0))
        self.captureSession.startRunning()
        //setUpCaptureSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        DispatchQueue.main.async {
            
            // MARK: - Set the string message of the toast
            self.showToast(message: "Registration successful", font: .systemFont(ofSize: 12.0))
        }
        self.captureSession.stopRunning()
    }
    //Use discovery session to find available input devices.
    //IMPORTANT - In info.plist, add NSCameraUsageDescription as key and add Required for front camera access as value

    private func addCameraInput() {
        // MARK: - Discover whether the device supports dual camera and set the camera postition and set the type of media to be captured
    guard let device = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .front).devices.first else {
           fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        
        
    //MARK: - If found, configure input device for session
    let cameraInput = try! AVCaptureDeviceInput(device: device)
    self.captureSession.addInput(cameraInput)
    }
    
    //
//    @objc func buttonAction(sender: UIButton!){
//        usingFrontCamera = !usingFrontCamera
//        loadCamera()
//
//    }
//    func getFrontCamera() -> AVCaptureDevice?{
//        let videoDevices = AVCaptureDevice.devices(for: AVMediaType.video)
//
//
//         for device in videoDevices{
//             let device = device as! AVCaptureDevice
//            if device.position == AVCaptureDevice.Position.front {
//                 return device
//             }
//         }
//         return nil
//     }
//
//     func getBackCamera() -> AVCaptureDevice{
//        return AVCaptureDevice.default(for: AVMediaType.video)!
//     }
//
//
//
//     func loadCamera() {
////         if(captureSession == nil){
////             captureSession = AVCaptureSession()
////             captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
////         }
//         var error: NSError?
//         var input: AVCaptureDeviceInput!
//
//         currentCaptureDevice = (usingFrontCamera ? getFrontCamera() : getBackCamera())
//
//         do {
//            input = try AVCaptureDeviceInput(device: currentCaptureDevice!)
//         } catch let error1 as NSError {
//             error = error1
//             input = nil
//             print(error!.localizedDescription)
//         }
//
//         for i : AVCaptureDeviceInput in (self.captureSession.inputs as! [AVCaptureDeviceInput]){
//             self.captureSession.removeInput(i)
//         }
//         if error == nil && captureSession.canAddInput(input) {
//             captureSession.addInput(input)
//
//             stillImageOutput = AVCaptureStillImageOutput()
//             stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
//            if captureSession.canAddOutput(stillImageOutput!) {
//                 captureSession.addOutput(stillImageOutput!)
//                 previewLayerVideo = AVCaptureVideoPreviewLayer(session: captureSession)
//                previewLayerVideo.videoGravity = AVLayerVideoGravity.resizeAspectFill
//                previewLayerVideo.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
//                 self.view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
//                 self.view.layer.addSublayer(previewLayerVideo)
//                 DispatchQueue.main.async {
//                     self.captureSession.startRunning()
//                    print("input added")
//                 }
//
//
//             }
//         }
//
//
//
//     }

    // MARK: - Add videodataOutput as an output for captureSession
    private func getCameraFrames() {
       self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
       self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
       self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
       self.captureSession.addOutput(self.videoDataOutput)
        self.captureSession.addOutput(AVCapturePhotoOutput())
       guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),connection.isVideoOrientationSupported else { return }
       connection.videoOrientation = .portrait
    }

    //MARK: - Display the camerafeed by adding it as a sublayer of UIView
    private func showCameraFeed() {
       self.previewLayerVideo.videoGravity = .resizeAspectFill
       self.view.layer.addSublayer(self.previewLayerVideo)
    }

    //MARK: - To fit in the preview layer's frame within the UIView's frame
    override func viewDidLayoutSubviews() {
       super.viewDidLayoutSubviews()
        self.previewLayerVideo.frame = self.view.frame
    }
        //MARK: - Receive frames from videoDataOutput
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        self.frame = sampleBuffer
        self.detectFace(in: frame)
    }
    

    // MARK: - Draw green box around the detected face
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation], _ frame: CVPixelBuffer) {
        self.clearDrawings()
        
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
        let faceBoundingBoxOnScreen = self.previewLayerVideo.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
        let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
        let faceBoundingBoxShape = CAShapeLayer()
        faceBoundingBoxShape.path = faceBoundingBoxPath
        faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
        faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            
        var newDrawings = [CAShapeLayer]()
            
            var maximumPic = 1
            
            
        newDrawings.append(faceBoundingBoxShape)
            let yaw = observedFace.yaw
            
            if let yawvalue = yaw?.floatValue{
                let items = progressBar.progressItems15[yawvalue]
                if items![0].isCaptured == false || items![1].isCaptured == false || items![2].isCaptured == false{
                    
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ timer in
                        if maximumPic != 4 {
                            //let croppedCIImage = CIImage(cgImage: croppedCGImage!)
                            
                            self.image = self.imageFromSampleBuffer(samepleBuffer: self.frame)
                            
                            if let img = self.image{
                                self.registerationImages.append(img)
                                let img = items![maximumPic-1].image
                                self.view.addSubview(img)
                                self.view.bringSubviewToFront(img)
                                
                            }
                            
                            print("Marked " + String(maximumPic))
                            maximumPic += 1
                        } else {
                            timer.invalidate()
                            
                        }
                    }
                    self.progressBar.progressItems15[yawvalue]![0].isCaptured = true
                    self.progressBar.progressItems15[yawvalue]![1].isCaptured = true
                    self.progressBar.progressItems15[yawvalue]![2].isCaptured = true
                }
                if registerationImages.count == 15 {
                    performSegue(withIdentifier: "register", sender: self)
                }
            }
        if let landmarks = observedFace.landmarks {
            newDrawings = newDrawings + self.drawFaceFeatures(landmarks, screenBoundingBox: faceBoundingBoxOnScreen)
        }
        return newDrawings
        })
       facesBoundingBoxes.forEach({ faceBoundingBox in self.view.layer.addSublayer(faceBoundingBox) })
       self.drawings = facesBoundingBoxes
   }
    
    
   private func clearDrawings() {
       self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
   }

   //MARK: - Handle the results and draw the box if a face is detected, otherwise clear the drawings.
   private func detectFace(in image: CVPixelBuffer) {
     let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
        DispatchQueue.main.async {
            if let results = request.results as? [VNFaceObservation] {
                self.handleFaceDetectionResults(results, image)
            } else {
                self.clearDrawings()
              }
          }
      })
      let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
      try? imageRequestHandler.perform([faceDetectionRequest])
   }
    
    private func imageFromSampleBuffer(samepleBuffer: CMSampleBuffer) -> UIImage? {

        guard let imageBuffer = CMSampleBufferGetImageBuffer(samepleBuffer) else {
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
   
   //MARK: - Draw face features for the landmarks
    private func drawFaceFeatures(_ landmarks: VNFaceLandmarks2D, screenBoundingBox: CGRect) -> [CAShapeLayer] {
      var faceFeaturesDrawings: [CAShapeLayer] = []
      if let leftEye = landmarks.leftEye {
        let eyeDrawing = self.drawEye(leftEye, screenBoundingBox: screenBoundingBox, landmarks: landmarks)
        faceFeaturesDrawings.append(eyeDrawing)
      }
      if let rightEye = landmarks.rightEye {
        let eyeDrawing = self.drawEye(rightEye, screenBoundingBox: screenBoundingBox, landmarks: landmarks)
        faceFeaturesDrawings.append(eyeDrawing)
      }
      // draw other face features here
      return faceFeaturesDrawings
   }

   //MARK: - Use VNFaceObservation landmarks property to draw the eyes
    private func drawEye(_ eye: VNFaceLandmarkRegion2D, screenBoundingBox: CGRect, landmarks: VNFaceLandmarks2D) -> CAShapeLayer {
      let eyePath = CGMutablePath()
      let eyePathPoints = eye.normalizedPoints.map({ eyePoint in
            CGPoint(
                x: eyePoint.y * screenBoundingBox.height + screenBoundingBox.origin.x,
                y: eyePoint.x * screenBoundingBox.width + screenBoundingBox.origin.y)
         })
      eyePath.addLines(between: eyePathPoints)
      eyePath.closeSubpath()
      let eyeDrawing = CAShapeLayer()
      eyeDrawing.path = eyePath
      eyeDrawing.fillColor = UIColor.clear.cgColor
      eyeDrawing.strokeColor = UIColor.green.cgColor
    
        let rightEye = landmarks.rightEye
        let leftEye = landmarks.leftEye
        
        var rightEyePoints : [CGPoint] = []
        var leftEyePoints : [CGPoint] = []
        
        if let rightPoints = rightEye?.normalizedPoints {
            rightEyePoints = rightPoints
        }
        if let leftPoints = leftEye?.normalizedPoints {
            leftEyePoints = leftPoints
        }
  
        let points = eye.normalizedPoints
    
    return eyeDrawing
    }
    // MARK: - send over the images to RegistrationViewController
    func receiveImages() -> [UIImage] {
        return self.registerationImages
    }
    
    // MARK: - Clear all the images when the user return from RegistrationViewController to ViewController
    func clearCapturedImages() {
        self.registerationImages.removeAll()
    }
    
    // MARK: - Clear all the captured face angles when the user return from RegistrationViewController to ViewController
    func clearCapturedAngles() {
        for angle in progressBar.progressItems15.keys.sorted(){
            for i in 0...2{
                progressBar.progressItems15[angle]![i].isCaptured = false
                DispatchQueue.main.async {
                    self.progressBar.progressItems15[angle]![i].image.removeFromSuperview()
                }
            }
        }
    }
    
    private func showToast(message: String, font: UIFont) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    func setToastMessage(message: String) {
        self.toastMessage = message
    }
    // MARK: - Prepare the necessary data to be sent to the Registration view controller
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier
        
        if identifier == "register"{
            let vc = segue.destination as! RegistrationViewController
            vc.delegate = self
            
        }
    }
}
