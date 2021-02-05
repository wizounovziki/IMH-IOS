//
//  RegistrationViewController.swift
//  IMH
//
//  Created by admin user on 21/12/20.
//

import UIKit

// MARK: - View controller for displaying registration form
class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var box: UIView!
    var delegate: RegistrationDelegate!
    
    // MARK: - text fields for filling in patient name and nric
    @IBOutlet weak var fullname: UITextField!
    @IBOutlet weak var nric: UITextField!
    
    // MARK: - Pickers for ward and gender
    @IBOutlet weak var wardPicker: UIPickerView!
    @IBOutlet weak var genderPicker: UIPickerView!
    
    // MARK: - Array for saving list of wards and genders
    private var wards : [Ward] = []
    private let genders = ["Male", "Female"]

    // MARK: - Clear all the images when the user return from RegistrationViewController to ViewController
    private let decoder = JSONDecoder()
    // MARK: - Generate a unqiue string for every POST request
    private let boundary = UUID().uuidString
    // MARK: - URL to submit the form data
    private let url = URL(string: "http://172.29.57.17:5432/register")
    
    var images: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        genderPicker.delegate = self
        genderPicker.dataSource = self
        wardPicker.delegate = self
        wardPicker.dataSource = self
        // call the 'keyboardWillShow' function when the view controller receive the notification that a keyboard is going to be shown
            NotificationCenter.default.addObserver(self, selector: #selector(RegistrationViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
          
              // call the 'keyboardWillHide' function when the view controlelr receive notification that keyboard is going to be hidden
            NotificationCenter.default.addObserver(self, selector: #selector(RegistrationViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

        //Looks for single or multiple taps.
             let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))

            //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
            //tap.cancelsTouchesInView = false

            view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.lightGray
        box.layer.shadowColor = UIColor.gray.cgColor
        box.layer.shadowRadius = 10
        box.layer.shadowOpacity = 1
        box.layer.shadowOffset = .zero
        box.backgroundColor = UIColor.white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getWardIDs()
        if let del = delegate{
            self.images = del.receiveImages()
            print("Total \(images.count)")
        }
    }

    // MARK: - Handling user action on cancel button
    @IBAction func cancel(_ sender: UIButton) {
        
        if let del = delegate{
            del.clearCapturedImages()
            del.clearCapturedAngles()
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: - Handling user action on register button
    @IBAction func register(_ sender: UIButton) {
        
            let dialog = self.buildAlertDialog()
            self.present(dialog, animated: true, completion: nil)
        
    }
    
    // MARK: - Send the form data in a POST request to the server
    private func submitData(){
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
                 print("<<DEBUG>> Debugging to view returned data")
                 print("data is \(stringData)")
                
                let decodedData = self.decodeFromJSON(data: data)
                let message = "Registration \(decodedData["status"]!). \(decodedData["msg"]!)"
                if let del = self.delegate{
                    del.clearCapturedImages()
                    del.clearCapturedAngles()
                }
                DispatchQueue.main.async {
                    self.delegate.setToastMessage(message: message)
                    self.dismiss(animated: true, completion: nil)
                }
               }
             }
           }
         }
         
         // Step 5 - Start / resume the task
         task.resume()
    }
    
    private func decodeFromJSON(data: Data) -> [String: String]{
        let dataDict : [String: String] = [:]
        
        if let decodedData = try? decoder.decode([String:String].self, from: data){
            return decodedData
        }
        return dataDict
    }
    
    private func gatherData() -> [String: Any]{

        var name = "Test User"
        var nric = "testic"
        var ward = "test ward"
        var dataDict : [String: Any] = [:]

        if let fullname = fullname.text{
            name = fullname
        }
        if let ic = self.nric.text{
            nric = ic
        }
        
        let selectedRow = wardPicker.selectedRow(inComponent: 0)
        
        let selectedWardID = wards[selectedRow].ward_id
        
        dataDict["name"] = name
        dataDict["nric"] = nric
        dataDict["ward"] = selectedWardID
        
        return dataDict

    }
//
    // MARK: - Wrap up the data needed for POST request
    func wrapUpData() -> Data{

        // Set the URLRequest to POST and to the specified URL

       var data = Data()
        let patientData = self.gatherData()
        var trailingNum = 0
        
        //Append patient name to data object
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(patientData["name"]!)".data(using: .utf8)!)
        
        //Append ward id to data object
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"ward_id\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(patientData["ward"]!)".data(using: .utf8)!)
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"NRIC\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(patientData["nric"]!)".data(using: .utf8)!)

        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"profile\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(6)".data(using: .utf8)!)
        
        for img in images{
            
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(trailingNum)\"; filename=\"\(patientData["name"]!)\(trailingNum)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            data.append(img.jpegData(compressionQuality: 1.0)!)
            trailingNum += 1

        }
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return data
        
    }
    @objc func keyboardWillShow(notification: NSNotification) {
            
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           // if keyboard size is not available for some reason, dont do anything
           return
        }
      
      // move the root view up by the distance of keyboard height
      self.view.frame.origin.y = 0 - keyboardSize.height
    }

    @objc func keyboardWillHide(notification: NSNotification) {
      // move back the root view origin to zero
      self.view.frame.origin.y = 0
    }
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    private func buildAlertDialog() -> UIAlertController{
        
        let wardName = wards[wardPicker.selectedRow(inComponent: 0)].name
        
        let alert = UIAlertController(title: "Confirmation", message: "Name: \(fullname.text!) \nNRIC: \(nric.text!) \nWard: \(wardName)", preferredStyle: .alert)
        
        let noAction = UIAlertAction(title: "No", style: .default, handler: {(action: UIAlertAction) in print("Dismissed")})
        
        let yesAction = UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction) in self.submitData()})
        
        alert.addAction(yesAction)
        alert.addAction(noAction)
        
        return alert
    }
    
    // MARK: - Send a GET request to get ward data
    private func getWardIDs() {
        guard let url = URL(string: "http://172.29.57.17:5432/ward") else {
           return
         }
         
         // Step 2 - Create a URLRequest object
         var request = URLRequest(url:url)
        
         request.httpMethod = "GET"


         // Step 3 - Create a URLSession object
         let session = URLSession.shared
         
         // Step 4 - Create a URLSessionDataTask object
        let task = session.dataTask(with: request) { [self] (data, response, error) in
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
                
                let wards = decodeFromWardJSON(data: data)
                
                self.wards = wards
                
                DispatchQueue.main.async {
                    wardPicker.reloadAllComponents()
                }
                
               }
             }
           }
         }
         
         // Step 5 - Start / resume the task
         task.resume()
    }
    
    private func decodeFromWardJSON(data: Data) -> [Ward]{
        let dataList : [Ward] = []
        
        if let decodedData = try? decoder.decode([Ward].self, from: data){
            print("decode success")
            return decodedData
        }
        print("decode failed")
        return dataList
    }
    
}

extension RegistrationViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.isEqual(self.genderPicker){
            return genders.count
        }
        else{
            return wards.count
        }
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.isEqual(self.genderPicker){
            return genders[row]
        }
        else{
            return wards[row].name
        }
    }
    
}

    

