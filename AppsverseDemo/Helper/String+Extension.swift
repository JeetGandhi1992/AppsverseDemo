//
//  String+Extension.swift
//  AppsverseDemo
//
//  Created by jeet_gandhi on 12/12/20.
//

import UIKit

extension String {

    func matches(for regex: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))

            return !results.isEmpty
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return false
        }
    }
}
