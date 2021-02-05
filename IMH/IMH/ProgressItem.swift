//
//  ProgressItem.swift
//  IMH
//
//  Created by admin user on 11/1/21.
//

import Foundation
import UIKit

class ProgressItem {
    var image: UIImageView
    var isCaptured: Bool
    
    init(image: UIImageView, isCaptured: Bool) {
        self.image = image
        self.isCaptured = isCaptured
    }
}
