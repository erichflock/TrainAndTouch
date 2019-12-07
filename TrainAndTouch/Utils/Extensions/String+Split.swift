//
//  String+Split.swift
//  TrainAndTouch
//
//  Created by Erich Flock on 06.12.19.
//  Copyright © 2019 flock. All rights reserved.
//

import Foundation

extension String {
    
    func splitByLength(_ length: Int) -> [String] {
        
        var result = [String]()
        var collectedWords = [String]()
        collectedWords.reserveCapacity(length)
        var count = 0
        let words = self.components(separatedBy: " ")

        for word in words {
            count += word.count + 1 //add 1 to include space
            if (count > length) {
                // Reached the desired length

                result.append(collectedWords.map { String($0) }.joined(separator: " ") )
                collectedWords.removeAll(keepingCapacity: true)

                count = word.count
                collectedWords.append(word)
            } else {
                collectedWords.append(word)
            }
        }

        // Append the remainder
        if !collectedWords.isEmpty {
            result.append(collectedWords.map { String($0) }.joined(separator: " "))
        }

        return result
    }
}
