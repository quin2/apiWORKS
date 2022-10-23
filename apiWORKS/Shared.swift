//
//  Shared.swift
//  apiWORKS
//
//  Created by Quinn Vinlove on 10/23/22.
//

import Foundation

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}

func getCurrentPrefix(request: Request?) -> String {
    if isTrue(request?.group?.devMode) {
        return request?.group?.devPrefix ?? ""
    } else {
        return request?.group?.prodPrefix ?? ""
    }
}

func getCurrentURL(request: Request?) -> String {
    return getCurrentPrefix(request: request) + (request?.url ?? "")
}

func isTrue(_ bool: Bool?) -> Bool {
    guard let b = bool else {
        return false
    }
    return b
}
