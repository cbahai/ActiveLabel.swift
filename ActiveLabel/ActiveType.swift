//
//  ActiveType.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

enum ActiveElement {
    case mention(String)
    case hashtag(String)
    case url(String)
    case regex([String])
    case none
}

public enum ActiveType {
    case mention
    case hashtag
    case url
    case regex
    case none
}

func activeElement(_ word: String) -> ActiveElement {
    if let url = reduceRightToURL(word) {
        return .url(url)
    }
    
    if word.characters.count < 2 {
        return .none
    }
    
    // remove # or @ sign and reduce to alpha numeric string (also allowed: _)
    guard let allowedWord = reduceRightToAllowed(word.substring(from: word.characters.index(word.startIndex, offsetBy: 1))) else {
        return .none
    }
    
    if word.hasPrefix("@") {
        return .mention(allowedWord)
    } else if word.hasPrefix("#") {
        return .hashtag(allowedWord)
    } else {
        return .none
    }
}

private func reduceRightToURL(_ str: String) -> String? {
    if let urlDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
        let nsStr = str as NSString
        let results = urlDetector.matches(in: str, options: .reportCompletion, range: NSRange(location: 0, length: nsStr.length))
        if let result = results.map({ nsStr.substring(with: $0.range) }).first {
            return result
        }
    }
    return nil
}

private func reduceRightToAllowed(_ str: String) -> String? {
    if let regex = try? NSRegularExpression(pattern: "^[a-z0-9_]*", options: [.caseInsensitive]) {
        let nsStr = str as NSString
        let results = regex.matches(in: str, options: [], range: NSRange(location: 0, length: nsStr.length))
        if let result = results.map({ nsStr.substring(with: $0.range) }).first {
            if !result.isEmpty {
                return result
            }
        }
    }
    return nil
}

func reduceToRegex(_ mutAttrString: NSMutableAttributedString, regex: NSRegularExpression, replaceHandler: (([String]) -> String?)? = nil) -> [(range: NSRange, values: [String])]? {
    if mutAttrString.string.isEmpty {
        return nil
    }
    
    var elements = [(range: NSRange, values: [String])]()
    var location = 0
    while let result = regex.firstMatch(in: mutAttrString.string, options: [], range: NSRange(location: location, length: mutAttrString.length - location)) {
        var values = [String]()
        for i in 0..<result.numberOfRanges {
            let value = (mutAttrString.string as NSString).substring(with: result.rangeAt(i))
            values.append(value)
        }
        
        let elementRange: NSRange
        if let content = replaceHandler?(values) {
            mutAttrString.replaceCharacters(in: result.range, with: content)
            elementRange = NSRange(location: result.range.location, length: (content as NSString).length)
        } else {
            elementRange = result.range
        }
        elements.append((range: elementRange, values: values))
        
        location = elementRange.location + elementRange.length
    }
    
    return elements
}
