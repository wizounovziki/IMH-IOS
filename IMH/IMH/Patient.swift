//
//  Patient.swift
//  IMH
//
//  Created by admin user on 19/1/21.
//

import Foundation


class Patient: Codable {
    var NRIC : String
    var id : Int
    var name : String
    var ward : Ward
    
    init(ic: String, id: Int, name: String, ward: Ward) {
        self.name = name
        self.NRIC = ic
        self.id = id
        self.ward = ward
    }
    
}
