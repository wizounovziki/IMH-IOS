//
//  PatientInfoViewController.swift
//  IMH
//
//  Created by admin user on 20/1/21.
//

import UIKit

// MARK: - View controller for displaying information of a one patient
class PatientInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{
    // MARK: - Image view to display patient image
    @IBOutlet weak var outPatientImage: UIImageView!
    
    // MARK: - Image view to display the barcode generated from patient NRIC
    @IBOutlet weak var outICBarcode: UIImageView!
    
    @IBOutlet weak var outTableView: UITableView!
    
    var delegate: PatientInfoDelegate!
    
    // MARK: - Labels to display patient name, nric and ward
    @IBOutlet weak var outLabelName: UILabel!
    
    @IBOutlet weak var outLabelNRIC: UILabel!
    
    @IBOutlet weak var outLabelWard: UILabel!
    
    private let decoder = JSONDecoder()
    
    var patientProfile = TempPatient(ic: "", id: 0, name: "", ward: Ward(name: "", ward_id: 0), profile: "")
    
    // MARK: - To save the array of medicine dispense/reject history
    var patientHistory : Logs = Logs(logs: [History]())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        outTableView.dataSource = self
        outTableView.delegate = self

        // MARK: - Display the data of the selected patient
        if let delegate = self.delegate {
            let patientInfo = delegate.passData()
            outLabelName.text = patientInfo.name
            outLabelNRIC.text = patientInfo.NRIC
            outLabelWard.text = "Ward : \(patientInfo.ward.name)"
        }
        // MARK: - Retrieve the patient and the corresponding medicine dispense/reject history
        getPatient()
        getHistory()
        
    }

    // MARK: - Configure the tableview
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return patientHistory.logs.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PatientHistoryTableViewCell
        cell.outTimeDate.text = patientHistory.logs[indexPath.row].time_date
        cell.outTimeClock.text = patientHistory.logs[indexPath.row].time_clock
        cell.outStatus.text = patientHistory.logs[indexPath.row].status
        
        return cell
    }
    
    // MARK: - Retrieve patient by id
    private func getPatient(){
        
        guard let delegate = self.delegate else {
            return
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "172.29.57.17"
        urlComponents.port = 5432
        urlComponents.path = "/register"
        
        
        let patientInfo = delegate.passData()
        let query = URLQueryItem(name: "id", value: String(patientInfo.id))
        
        urlComponents.queryItems = [query]
        
        guard let url = urlComponents.url else {
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
                 //print("data is \(stringData)")
                
                self.patientProfile = self.decodeFromJSON(data: data)
                
                // MARK: - Decode Base64 to Image
                let imageDecode : Data = Data(base64Encoded: patientProfile.profile, options: .ignoreUnknownCharacters)!
                let decodedImage = UIImage(data: imageDecode)
                let barcode = self.generateBarcode(from: self.patientProfile.NRIC)
                
                DispatchQueue.main.async {
                    self.outPatientImage.image = decodedImage
                    self.outICBarcode.image = barcode
                }
               }
             }
           }
         }
         
         // Step 5 - Start / resume the task
         task.resume()
        
    }
    
    private func decodeFromJSON(data: Data) -> TempPatient{
        let patient = TempPatient(ic: "", id: 0, name: "", ward: Ward(name: "", ward_id: 0), profile: "")
        
        if let decodedData = try? decoder.decode(TempPatient.self, from: data){
            print("decode success")
            return decodedData
        }
        print("decode failed")
        return patient
    }
    // MARK: - Decode the list of medicine dispense/reject history
    private func decodeFromHistoryJSON(data: Data) -> Logs{
        let patientHistory : Logs = Logs(logs: [History]())
        do{
            let decodedData = try decoder.decode(Logs.self, from: data)
            return decodedData
        }catch{
            print(error)
        }
//        if let decodedData = try decoder.decode(Logs.self, from: data){
//            print("decode success")
//            return decodedData
//        }
        //print("decode failed")
        return patientHistory
    }
    
    private func getHistory(){
        
        guard let delegate = self.delegate else {
            return
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "172.29.57.17"
        urlComponents.port = 5432
        urlComponents.path = "/history"
        
        
        let patientInfo = delegate.passData()
        let query = URLQueryItem(name: "nric", value: patientInfo.NRIC)
        
        urlComponents.queryItems = [query]
        
        guard let url = urlComponents.url else {
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
                
                self.patientHistory = self.decodeFromHistoryJSON(data: data)
                
                DispatchQueue.main.async {
                    self.outTableView.reloadData()
                }
               }
             }
           }
         }
         
         // Step 5 - Start / resume the task
         task.resume()
        
    }

    // MARK: - Generates the barcode
    func generateBarcode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
