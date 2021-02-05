//
//  PatientListTableViewController.swift
//  IMH
//
//  Created by admin user on 19/1/21.
//

import UIKit

// MARK: - View controller for displaying list of patients
class PatientListTableViewController: UITableViewController, PatientInfoDelegate {
    
    // MARK: - URL to retireve patient list with a GET request parameter
    private let url = URL(string: "http://172.29.57.17:5432/register")
    
    // MARK: - The decoder to decode the JSON data returned from the backend
    private let decoder = JSONDecoder()
    
    // MARK: - To save the array of patient objects obtained from decoded JSON
    private var patientList : [Patient] = []
    
    var selectedPatientInfo : Patient!
    
    var currToken = ""
    
    var patientDictionary = [String: [Patient]]()
    var patientSectionTitles = [String]()
    
    // MARK: - To generate a unique string for every DELETE request
    private let boundary = UUID().uuidString
    
    var filteredPatientList : [Patient] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.getPatientList()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return patientSectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let patientKey = patientSectionTitles[section]
        if let patientValues = patientDictionary[patientKey]{
            return patientValues.count
        }
        
        return 0
    }

    // MARK: - Sorts the patients and displays them
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PatientListTableViewCell
        let patientKey = patientSectionTitles[indexPath.section]
        if let patientValues = patientDictionary[patientKey]{
            cell.outName.text = patientValues[indexPath.row].name
            cell.outWard.text = patientValues[indexPath.row].ward.name
            cell.outNRIC.text = patientValues[indexPath.row].NRIC
        }
            return cell
    }
    
    // MARK: - Enables the side alphabets to directly skip the the specfic alphabet
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return patientSectionTitles[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return patientSectionTitles
    }
    
    // MARK: - Selects the row to move to the patient page
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSection = indexPath.section
        let selectedRow = indexPath.row
        
        let selectedKey = patientSectionTitles[selectedSection]
        let selectedPatient = patientDictionary[selectedKey]
        selectedPatientInfo = selectedPatient![selectedRow]
        
        performSegue(withIdentifier: "patientInfo", sender: self)
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        print(indexPath.row)
        if editingStyle == .delete{
            let key = patientSectionTitles[indexPath.section]
            guard let deletedPatientID = patientDictionary[key]?[indexPath.row].id else { return }
            self.deletePatient(id: deletedPatientID, indexPath: indexPath)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier
        
        if identifier == "patientInfo"{
            let vc = segue.destination as! PatientInfoViewController
            vc.delegate = self
        }
    }
    
    // MARK: - Passes patient information to PatientInfoDelegate
    func passData() -> Patient {
        return selectedPatientInfo
    }
    
    // MARK: - Send the DELETE request to the server
    private func deletePatient(id: Int, indexPath: IndexPath){
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "172.29.57.17"
        urlComponents.port = 5432
        urlComponents.path = "/register"

        guard let url = urlComponents.url else {
           return
         }

         // Step 2 - Create a URLRequest object
         var request = URLRequest(url:url)

         request.httpMethod = "DELETE"
         request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let data = wrapUpData(id: id)
        //print(data?.base64EncodedData())
        
        request.httpBody = data


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
                let key = patientSectionTitles[indexPath.section]

                patientDictionary[key]?.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
               }
             }
           }
         }

         // Step 5 - Start / resume the task
         task.resume()
//
    }

    // MARK: - Gets patient list details
    private func getPatientList(){

        guard let url = self.url else {
           return
         }

         // Step 2 - Create a URLRequest object
         var request = URLRequest(url:url)

         request.httpMethod = "GET"

        request.addValue(currToken, forHTTPHeaderField: "Authorization")
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
                //print("Data is \(stringData)")
                patientDictionary.removeAll()
                self.patientList = self.decodeFromJSON(data: data)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                for i in patientList {
                    let patientAlphabet = String(i.name.prefix(1))
                    if var patientValue = patientDictionary[patientAlphabet]{
                        patientValue.append(i)
                        patientDictionary[patientAlphabet] = patientValue
                    } else {
                        patientDictionary[patientAlphabet] = [i]
                    }
                }

                patientSectionTitles = [String](patientDictionary.keys)
                patientSectionTitles = patientSectionTitles.sorted(by: {$0 < $1})
               }
             }
           }
         }

         // Step 5 - Start / resume the task
         task.resume()
        
    }
    
    private func decodeFromJSON(data: Data) -> [Patient]{
        let dataList : [Patient] = []
        
        if let decodedData = try? decoder.decode([Patient].self, from: data){
            //print("decode success")
            return decodedData
        }
        //print("decode failed")
        return dataList
    }

    func wrapUpData(id: Int) -> Data{

        // Set the URLRequest to DELETE and to the specified URL
       var data = Data()
        
        //Append id to data object
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"id\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(id)".data(using: .utf8)!)
        
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return data
        
    }
    
    func getToken(){
        let pListUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Token.plist")
        let decoder = PropertyListDecoder()
        do{
            let xml = try Data(contentsOf: pListUrl)
            let newToken = try decoder.decode(String.self, from: xml)
            currToken = newToken
        } catch{
            print (error)
        }
    }

}


//extension PatientListTableViewController: UISearchResultsUpdating{
//    func updateSearchResults(for searchController: UISearchController) {
//
//    }
//}
