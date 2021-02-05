//
//  RecognitionViewController.swift
//  IMH
//
//  Created by admin user on 7/1/21.
//

import UIKit
import AVFoundation
import Vision
import CoreML

class RecognitionResult: Codable {
    var name: String!
    var score: Double!
    var nric: String!
    
    init(name: String, score: String, nric: String) {
        self.name = name
        self.score = Double(score)
        self.nric = nric
    }
}

class RecognitionResultAngle: Encodable {
    var angle: Int!
    var name: String!
    var score: Double!
    var uuid : String!
    var nric : String!
    
    init(name: String, score: Double, angle: Int, uuid: String, nric: String){
        self.angle = angle
        self.name = name
        self.score = score
        self.uuid = uuid
        self.nric = nric
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

class RecognitionFinalResult: Encodable {
    var data: [RecognitionResultAngle]
    var uuid: String
    
    init(data: [RecognitionResultAngle], uuid: String) {
        self.data = data
        self.uuid = uuid
    }
}
// MARK: - ViewController for recognizing registered patients
class RecognitionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, RecognitionDelegate {
    
    
    // MARK: - Generate the unqiue string for recognition
    private var boundary = UUID().uuidString
    private let url = URL(string: "http://172.29.57.17:5432/recognize")
    //Instantiate a session to get data from input devices: camera, mic, etc.
    private let captureSession = AVCaptureSession()

    private let context = CIContext()
    // MARK: - Save the current frame
    private var frame : CMSampleBuffer!
    private var image: UIImage!
    var recognitionResultAngles: [RecognitionResultAngle] = []
    var medicineRecord: MedicineRecord!
    //Preview layer for displaying the camera feed
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)

    private var recognitionResult: RecognitionResult = RecognitionResult(name: "", score: "0.0", nric: "")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    //To handle and control the output data
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let progressBar = ProgressBar(numberOfBars: 5)
    var timer : Timer!
//    var nameList : [String] = []

    //To hold the instances of drawings from detection results
    private var drawings: [CAShapeLayer] = []
     
     // create a request to pass an image into the model
     private lazy var classificationRequest: VNCoreMLRequest = {
       do{
         // instantiate our model
         let model = try VNCoreMLModel(for: mfn().model)
         // instantiate an image analysis request object based on the model
         let request = VNCoreMLRequest(model: model){ request, _ in
           if let classifications = request.results as? [VNCoreMLFeatureValueObservation]{
               //print("Classification results: \(classifications)")
             let obs: VNCoreMLFeatureValueObservation = (classifications.first)!
             let m: MLMultiArray = obs.featureValue.multiArrayValue!
             //print(m)
             //print(m.description)
             let length = m.count
             let doublePtr = m.dataPointer.bindMemory(to: Double.self, capacity: length)
             let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
             let output = Array(doubleBuffer)
             //print(output)
             let stringOutput = output.description
             print(stringOutput)
           }
         }
         // use vision to crop the input image to match what the model expects
         //request.imageCropAndScaleOption = .centerCrop
         return request
       } catch{
         fatalError("Failed to load Vision ML model: \(error)")
       }
     }()

    override func viewDidLoad() {

      super.viewDidLoad()
     //print("\(OpenCVWrapper.openCVVersionString())")
        self.setUpCaptureSession()
        
        let imageName = "whitebar.png"
        let image = UIImage(named: imageName)
        var x = 142
        
        for i in 0...4{
            let bar = UIImageView(image: image!)
            
            bar.frame = CGRect(x:x,y:69,width: 30,height: 20)
            view.addSubview(bar)
            self.view.bringSubviewToFront(bar)
            x = x+25
        }
     }
    
    func setUpCaptureSession(){
        self.addCameraInput()
       
        self.getCameraFrames()
        //Tell the captureSession to start coordinating its input, preview and outputs
       
       self.showCameraFeed()
       self.captureSession.startRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.captureSession.stopRunning()
    }
     
     // function to classify an image with our model
     func classifyImage(_ image: UIImage, _ ciImage: CIImage) {
       // Get the orientation of the image and the CIImage representation
       guard let orientation = CGImagePropertyOrientation(
         rawValue: UInt32(image.imageOrientation.rawValue)) else {
         return
       }
 //      guard let ciImage = CIImage(image: image) else {
 //        fatalError("Unable to create \(CIImage.self) from \(image).")
 //      }
       // Kicks off an asynchronous classification request in a background queue. Create a handler to perform the Vision request, and then schedule the request.
       DispatchQueue.global(qos: .userInitiated).async {
         let handler =
           VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
         do {
           try handler.perform([self.classificationRequest])
         } catch {
           print("Failed to perform classification.\n\(error.localizedDescription)")
         }
       }
     }
     
     //Use discovery session to find available input devices.
     //IMPORTANT - In info.plist, add NSCameraUsageDescription as key and add Required for front camera access as value

     private func addCameraInput() {
     guard let device = AVCaptureDevice.DiscoverySession(
         deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
         mediaType: .video,
         position: .front).devices.first else {
            fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
         }
     //If found, configure input device for session
     let cameraInput = try! AVCaptureDeviceInput(device: device)
     self.captureSession.addInput(cameraInput)
     }

     //Display the camerafeed by adding it as a sublayer of UIView
     private func showCameraFeed() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
     }

     //To fit in the preview layer's frame within the UIView's frame
     override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
     }

     //Add videodataOutput as an output for captureSession
     private func getCameraFrames() {
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
     }
     

     //Receive frames from videoDataOutput
     func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
         guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
             debugPrint("unable to get image from sample buffer")
             return
         }
         // the variable frame is of type CVPixelBuffer. The function detectFace returns a boolean
        self.frame = sampleBuffer
         self.detectFace(in: frame)
     }
     
     //Draw green box around the detected face
     private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation], _ frame: CVPixelBuffer) {
         self.clearDrawings()
         
         let facesBoundingBoxes: [CAShapeLayer] = observedFaces.flatMap({ (observedFace: VNFaceObservation) -> [CAShapeLayer] in
         // faceBoundingBoxOnScreen is a CGRect
         let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
         // crop the image with the CGRect, and pass it into the model
             
         let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
         let faceBoundingBoxShape = CAShapeLayer()
         faceBoundingBoxShape.path = faceBoundingBoxPath
         faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
         faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
         var newDrawings = [CAShapeLayer]()
            
         newDrawings.append(faceBoundingBoxShape)
             let yaw = observedFace.yaw
             
             if let yawvalue = yaw?.floatValue{
                let item = progressBar.progressItems5[yawvalue]
                if item!.isCaptured == false{
                    item!.isCaptured = true
                    // MARK: - Cast the current frame into image only when a face is detected and the angle hasn't been captured
                    self.image = self.imageFromSampleBuffer(samepleBuffer: self.frame)
                    print("Marked")
                    submitData(yaw: yawvalue)
                }
                if self.recognitionResultAngles.count == 5{
                    let resultAngles = self.recognitionResultAngles
                    self.recognitionResultAngles.removeAll()
                    self.submitRawJSONData(resultAngles: resultAngles)
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
    // MARK: - Reset every captured data and unique string after recongition is done
func setCapturedState(isCaptured: Bool) {
    for key in progressBar.progressItems5.keys.sorted(){
        progressBar.progressItems5[key]?.isCaptured = isCaptured
        DispatchQueue.main.async {
            self.progressBar.progressItems5[key]?.image.removeFromSuperview()
        }
    }
    self.boundary = UUID().uuidString
}

    // MARK: - send medicine record to DetailsViewController
func receiveMedicineRecord() -> MedicineRecord{
    return self.medicineRecord
}

    // MARK: - send recognition results to DetailsViewController
    func receiveRecognitionResults() -> RecognitionResult {
        return self.recognitionResult
    }
     
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }

    //Handle the results and draw the box if a face is detected, otherwise clear the drawings.
    private func detectFace(in image: CVPixelBuffer){
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
    
    //Draw face features for the landmarks
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

    //Use VNFaceObservation landmarks property to draw the eyes
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
         for point in points{
             var output = ""
             if rightEyePoints.contains(point){
                 output = "Right eye coordinates"
             }
             else if leftEyePoints.contains(point){
                 output = "Left eye coordinates"
             }
             let coordinates = VNImagePointForFaceLandmarkPoint(vector_float2(Float(point.x), Float(point.y)), screenBoundingBox, Int(screenBoundingBox.width), Int(screenBoundingBox.height))
             output += " \(coordinates)"
             //print(output)
         }
     
     return eyeDrawing
     }
    
    // MARK: - cast the current frame into image
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
   
    
    private func wrapUpData() -> Data{
        var data = Data()
        let key = "img"
        let name = "face"
        let trailingNum = 1
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"uuid\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(boundary)".data(using: .utf8)!)
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(name)\(trailingNum)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        
        if let img = self.image{
            
            data.append(img.jpegData(compressionQuality: 1.0)!)
        }
        
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
    
    private func wrapUpRawJSONData(resultAngles: [RecognitionResultAngle]) -> Data{
        let data = Data()
        
        let dataForFinalResult = RecognitionFinalResult(data: resultAngles, uuid: boundary)
        
        if let encodedData = try? encoder.encode(dataForFinalResult){
            print("encode success \(String(data: encodedData, encoding: .utf8)!)")
            return encodedData
        }
        
        return data
    }
    
    // MARK: - send a form data in a POST request. The data contains {"uuid": "FF45xcVE", "img": "<img byte string>"} and obtain {"name": "<name>", "nric": "<ic>", "score": 0.765}
    private func submitData(yaw: Float){
        // Step 1 - Create a URL object
        guard let url = self.url else {
           return
         }
         
         // Step 2 - Create a URLRequest object
         var request = URLRequest(url:url)
         request.httpMethod = "POST"
         request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let data = wrapUpData()
        //print(data?.base64EncodedData())
        
        request.httpBody = data
        //request.httpBody = bodyData

         // Step 3 - Create a URLSession object
         let session = URLSession.shared
         
         // Step 4 - Create a URLSessionDataTask object
         let task = session.dataTask(with: request) { (data, response, error) in
           // Step 6 - Process the response
           // check that the response status code is 200
           if let httpResponse = response as? HTTPURLResponse {
             // For debugging purposes, we convert the optional Data to a String
             print("<<DEBUG>> Debugging to view status code")
             print("httpResponse.statusCode is \(httpResponse.statusCode)")
             if (httpResponse.statusCode == 200) {
               // For debugging purposes, we convert the optional Data to a String
               // so that it can be printed out in the debug area
               if let data = data, let stringData = String(data: data, encoding: .utf8) {
//                 print("<<DEBUG>> Debugging to view returned data")
                 print("data is \(stringData)")
                // MARK: - cast the JSON data {"name": "<name>", "nric": "<ic>", "score": 0.765} into native class RecongitionResult
                let decodedData = self.decodeFromJSON(data: data)
                self.validateNameAndSetCapturedState(result: decodedData, yaw: yaw)
                
               }
             }
           }
         }
         
         // Step 5 - Start / resume the task
         task.resume()
    }
    
    // MARK: - send raw JSON data in a POST request. The data contains {data: ["uuid": "FF45xcVE", "angle": 0, "name": "<some name>", "nric": <ic>, "score": 0.765}
    private func submitRawJSONData(resultAngles: [RecognitionResultAngle]){
        // Step 1 - Create a URL object
        guard let url = URL(string: "http://172.29.57.17:5432/result") else {
           return
         }
         
         // Step 2 - Create a URLRequest object
         var request = URLRequest(url:url)
         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data = wrapUpRawJSONData(resultAngles: resultAngles)
        //print(data?.base64EncodedData())
        
        request.httpBody = data
        //request.httpBody = bodyData

         // Step 3 - Create a URLSession object
         let session = URLSession.shared
         
         // Step 4 - Create a URLSessionDataTask object
         let task = session.dataTask(with: request) { (data, response, error) in
           // Step 6 - Process the response
           // check that the response status code is 200
           if let httpResponse = response as? HTTPURLResponse {
             // For debugging purposes, we convert the optional Data to a String
             print("<<DEBUG>> Debugging to view status code")
             print("httpResponse.statusCode is \(httpResponse.statusCode)")
             if (httpResponse.statusCode == 200) {
               // For debugging purposes, we convert the optional Data to a String
               // so that it can be printed out in the debug area
               if let data = data, let stringData = String(data: data, encoding: .utf8) {
                 print("<<DEBUG>> Debugging to view returned data")
                 print("data is \(stringData)")
                self.recognitionResult = self.decodeFromJSON(data: data)
                
                if self.recognitionResult.name == "face not detected" || self.recognitionResult.name == "unknown"{
                    self.setCapturedState(isCaptured: false)
                    
                }
                else{
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "details", sender: self)
                    }
                }
                
               }
             }
           }
         }
         
         // Step 5 - Start / resume the task
         task.resume()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier
        
        if identifier == "details"{
            let vc = segue.destination as! DetailsViewController
            vc.delegate = self
        }
    }
    
    func validateNameAndSetCapturedState(result: RecognitionResult, yaw: Float){
        
        let item = progressBar.progressItems5[yaw]
        
        if result.name == "face not detected" || result.name == "unknown"{
            item?.isCaptured = false
            return
        }
        item?.isCaptured = true
        // MARK: - Prepare the medicine record to be sent to DetailsViewController
        self.medicineRecord = MedicineRecord(nric: result.nric, method: "", uuid: boundary)
        
        let resultAngle = RecognitionResultAngle(name: result.name, score: result.score, angle: recognitionResultAngles.count, uuid: boundary, nric: result.nric)
        recognitionResultAngles.append(resultAngle)
        
        // MARK: - turn the green box for every face angle captured
        DispatchQueue.main.async {
            self.view.addSubview(item!.image)
            self.view.bringSubviewToFront(item!.image)
        }
    }

    
    private func decodeFromJSON(data: Data) -> RecognitionResult{
        let result = RecognitionResult(name: "", score: "0.0", nric: "")
        
        if let decodedData = try? decoder.decode(RecognitionResult.self, from: data){
            print("Decode success")
            return decodedData
        }
        return result
    }
    
}
