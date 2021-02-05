//
//  ProgressBar.swift
//  IMH
//
//  Created by admin user on 11/1/21.
//

import Foundation
import UIKit

class ProgressBar {
    var progressItems15 : [Float: [ProgressItem]] = [:]
    var progressItems5 : [Float: ProgressItem] = [:]
    private let image = UIImage(named: "turquoisebar.png")
    
    var numberOfBars: Int!

    init(numberOfBars: Int) {
        self.numberOfBars = numberOfBars
        createBars(numOfBars: numberOfBars)
    }
    
    private func createBars(numOfBars: Int){
        
        var xcoordinateFor15Bars = 17
        var xcoordinateFor5Bars = 142
        
        for i in [Float(1.5707964), Float(0.7853982), Float(0.0), Float(-0.7853982), Float(-1.5707964)] {
            
            if numOfBars == 5{
                create5Bars(xcoordinate: xcoordinateFor5Bars, angle: i)
                xcoordinateFor5Bars = xcoordinateFor5Bars + 25
            }
            else {
                create15Bars(xcoordinate: xcoordinateFor15Bars, angle: i)
                xcoordinateFor15Bars = xcoordinateFor15Bars + 75
            }
        }
    }
    private func create15Bars(xcoordinate: Int, angle: Float){
        var items : [ProgressItem] = []
        var x = xcoordinate
        
        for j in 0...2{
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x:x,y:69,width: 30,height: 20)
            items.append(ProgressItem(image: imageView, isCaptured: false))
            x = x+25
        }
        progressItems15[angle] = items
        items.removeAll()
    }
    
    private func create5Bars(xcoordinate: Int, angle: Float){
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x:xcoordinate,y:69,width: 30,height: 20)
        progressItems5[angle] = ProgressItem(image: imageView, isCaptured: false)
    }
}
