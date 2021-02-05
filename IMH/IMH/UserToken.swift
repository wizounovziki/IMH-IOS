//
//  UserToken.swift
//  IMH
//
//  Created by admin user on 28/1/21.
//

import Foundation

class UserToken: Codable {
    var role : String
    var token : String
    var user_name : String
    
    init(role: String, token: String, user_name: String) {
        self.role = role
        self.token = token
        self.user_name = user_name
    }
    
}
