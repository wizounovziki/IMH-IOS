//
//  MedicineRecord.swift
//  IMH
//
//  Created by admin user on 22/1/21.
//

import Foundation


class MedicineRecord {
    
    var nric : String
    var method : String
    var uuid : String
    
    init(nric: String, method: String, uuid: String) {
        self.nric = nric
        self.method = method
        self.uuid = uuid
    }
    
}
