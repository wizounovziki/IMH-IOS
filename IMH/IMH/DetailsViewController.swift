//
//  DetailsViewController.swift
//  IMH
//
//  Created by admin user on 30/11/20.
//

import UIKit


class DetailsViewController: UIViewController {
    
    @IBOutlet weak var patientName: UILabel!
    var delegate: RecognitionDelegate!
    
    
    private let url = URL(string: "http://172.29.57.17:5432/dispense")
    private let boundary = UUID().uuidString

    override func viewDidLoad() {
        super.viewDidLoad()
        if let del = delegate{
            let result = del.receiveRecognitionResults()
            patientName.text = "Patient name \(result.name ?? "")"
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func reject(_ sender: UIButton) {
        self.submitMedicineRecord(method: "cancel")
        
    }
    @IBAction func dispense(_ sender: UIButton) {
        self.submitMedicineRecord(method: "dispense")
        
    }
    // MARK: - Submits dispense or cancel
    private func submitMedicineRecord(method: String){
        
            // Step 1 - Create a URL object
            guard let del = delegate else{
                return
            }
        let record = del.receiveMedicineRecord()
        record.method = method
        print("uuid \(record.uuid)")
   
            guard let url = self.url else {
               return
             }
             
             // Step 2 - Create a URLRequest object
             var request = URLRequest(url:url)
             request.httpMethod = "POST"
             request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            let data = wrapUpData(record: record)
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
                    
                    DispatchQueue.main.async {
                        del.setCapturedState(isCaptured: false)
                        self.dismiss(animated: true, completion: nil)
                    }
                   }
                 }
               }
             }
             
             // Step 5 - Start / resume the task
             task.resume()
        
    }
    
    func wrapUpData(record: MedicineRecord) -> Data{

        // Set the URLRequest to POST and to the specified URL

       var data = Data()
        //Append patient name to data object
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"nric\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(record.nric)".data(using: .utf8)!)

        //Append method to data object

        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"method\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(record.method)".data(using: .utf8)!)

        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"uuid\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(record.uuid)".data(using: .utf8)!)

        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)


        return data
        
    }

}
