//
//  FittsLaw.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 14.12.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation

class FittsLaw {
    
    /*
     var meandT = 0.0;
     var meanID = 0.0;
     
     data.forEach(function(item, index, array) {
         meandT += item[0];
         meanID += item[1];
     });
     
     meandT /= data.length;
     meanID /= data.length;

     var sum1 = 0.0;
     var sum2 = 0.0;
     
     data.forEach(function(item, index, array) {
         var d0 = item[0] - meandT;
         var d1 = item[1] - meanID;
         sum1 += d0 * d1;
         sum2 += d1 * d1;
     });

     b = sum1/sum2;
     a = meandT - b * meanID;
     */
    
    func getA(meandT: Float, meandID: Float, b: Float) -> Float {
        
        return meandT - b * meandID
    }
    
    func getB(means: [Float]) -> Float {
        
        for mean in means {
            
        }
        
        return 0.0
    }
}
