//
//  ImageDelegate.swift
//  IMH
//
//  Created by admin user on 4/1/21.
//

import Foundation
import UIKit

protocol RegistrationDelegate {
    func receiveImages() -> [UIImage]
    func clearCapturedImages()
    func clearCapturedAngles()
    func setToastMessage(message: String)
}
