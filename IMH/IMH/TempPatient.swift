//
//  TempPatient.swift
//  IMH
//
//  Created by admin user on 21/1/21.
//

import Foundation

class TempPatient: Codable {
    var NRIC : String
    var id : Int
    var name : String
    var ward : Ward
    var profile : String
    
    init(ic: String, id: Int, name: String, ward: Ward, profile: String) {
        self.name = name
        self.NRIC = ic
        self.id = id
        self.ward = ward
        self.profile = profile
    }
    
}
