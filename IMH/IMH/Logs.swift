//
//  Logs.swift
//  IMH
//
//  Created by admin user on 21/1/21.
//

import Foundation

class Logs : Codable {
    var logs : [History]
    
    init(logs : [History]) {
        self.logs = logs
    }
}

