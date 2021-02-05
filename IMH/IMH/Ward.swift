//
//  Ward.swift
//  IMH
//
//  Created by admin user on 19/1/21.
//

import Foundation

class Ward: Codable{
    var name : String
    var ward_id : Int
    
    init(name: String, ward_id: Int) {
        self.name = name
        self.ward_id = ward_id
    }
    
}
