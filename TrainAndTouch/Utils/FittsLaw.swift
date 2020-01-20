//
//  FittsLaw.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 14.12.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation
import UIKit

class FittsLaw {
    
    var touchStart = Date()
    var touchEnd: Date?
    var fittsLawElements: [FittsLawElement] = []
    
    func getMeanDt() -> TimeInterval {
        
        var sum: TimeInterval = 0
        
        for fittsLawElement in fittsLawElements {
            
            sum += fittsLawElement.dT
        }
        
        if fittsLawElements.count > 0 {
            return sum / Double(fittsLawElements.count)
        } else {
            return sum
        }
    }
    
    func getMeanId() -> CGFloat {
        
        var sum: CGFloat = 0
        
        for fittsLawElement in fittsLawElements {
            
            sum += fittsLawElement.iD
        }
        
        if fittsLawElements.count > 0 {
            return sum / CGFloat(fittsLawElements.count)
        } else {
            return sum
        }
    }
    
    func getA(meanDT: TimeInterval, meandID: CGFloat, b: CGFloat) -> CGFloat {
        
        return CGFloat(meanDT) - b * meandID
    }
    
    func getB(meanDt: TimeInterval, meanId: CGFloat) -> CGFloat {
        
        var sum1: CGFloat = 0
        var sum2: CGFloat = 0
        
        for fittsLawElement in fittsLawElements {
            
            let d0 = fittsLawElement.dT - meanDt
            let d1 = fittsLawElement.iD - meanId
            
            sum1 += CGFloat(d0) * d1
            sum2 += d1 * d1
        }
        
        return sum1 / sum2
    }
    
    func getId(d: CGFloat, w: CGFloat) -> CGFloat {
        
        return log2((d / w) + 1)
    }
    
    func getDt() -> TimeInterval {
        
        let timeInterval = touchStart.timeIntervalSinceNow * -1 // mutiply by -1 in oder to have positive values
        
        return timeInterval
    }
}

struct FittsLawElement {
    
    let dT: TimeInterval //time difference
    let iD: CGFloat //Index of difficulty
}
