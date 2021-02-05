//
//  RecognitionDelegate.swift
//  IMH
//
//  Created by admin user on 13/1/21.
//

import Foundation

protocol RecognitionDelegate {
    
    func setCapturedState(isCaptured: Bool)
    func receiveMedicineRecord() -> MedicineRecord
    func receiveRecognitionResults() -> RecognitionResult
}
