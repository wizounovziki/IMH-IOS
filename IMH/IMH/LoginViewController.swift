//
//  LoginViewController.swift
//  IMH
//
//  Created by admin user on 25/1/21.
//

import UIKit

class LoginViewController: UIViewController{
    @IBOutlet weak var outUsername: UITextField!
    @IBOutlet weak var outPassword: UITextField!
    @IBOutlet weak var outErrorLabel: UILabel!
    
    @IBOutlet weak var box: UIView!
    
    var token = ""
    
    private let decoder = JSONDecoder()
    
    private let url = URL(string: "http://172.29.57.17:5432/login")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: - shaded box
        view.backgroundColor = UIColor.lightGray
        box.layer.shadowColor = UIColor.gray.cgColor
        box.layer.shadowRadius = 10
        box.layer.shadowOpacity = 1
        box.layer.shadowOffset = .zero
        box.backgroundColor = UIColor.white

        // Do any additional setup after loading the view.
    }
    
    @IBAction func login(_ sender: UIButton) {
        submitData()
    }
    // MARK: - submits the username and password
    private func submitData(){
        // Step 1 - Create a URL object
        guard let url = self.url else {
           return
         }
        
        
        DispatchQueue.main.async{
            self.outErrorLabel.text = ""
            self.token = ""
        }
        
        let user = outUsername.text!
        let pass = outPassword.text!
        let loginString = String(format: "%@:%@", user, pass)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
         // Step 2 - Create a URLRequest object
         var request = URLRequest(url:url)
         request.httpMethod = "POST"
         request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        

        //print(data?.base64EncodedData())
        
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
                
                let newToken = self.decodeFromJSON(data: data)
                
                DispatchQueue.main.async{
                    self.token = newToken.token
                    print("Token is \(self.token)")
                    self.performSegue(withIdentifier: "postLogin", sender: self)
                }
               }
             } else{
                DispatchQueue.main.async{
                    self.outErrorLabel.text = "Wrong Username / Password"
                }
             }
           }
         }
         
         // Step 5 - Start / resume the task
         task.resume()
    }
    
    // MARK: - Decode from JSON to UserToken array
    private func decodeFromJSON(data: Data) -> UserToken{
        let result = UserToken(role: "", token: "", user_name: "")
        
        if let decodedData = try? decoder.decode(UserToken.self, from: data){
            print("Decode success")
            return decodedData
        }
        return result
    }
    
    // MARK: - Sends the token to Token.plist for storage
    func sendToken(){
        let pListUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Token.plist")
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do{
            let data = try encoder.encode(token)
            try data.write(to: pListUrl)
        } catch {
            print(error)
        }
    }
}
