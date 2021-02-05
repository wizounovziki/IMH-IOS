//
//  History.swift
//  IMH
//
//  Created by admin user on 21/1/21.
//

import Foundation

class History: Codable {
    var status : String
    var time_clock : String
    var time_date : String
    
    init(status: String, time_clock: String, time_date: String) {
        self.status = status
        self.time_clock = time_clock
        self.time_date = time_date
    }
    
}
