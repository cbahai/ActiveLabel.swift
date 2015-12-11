//
//  ActiveType.swift
//  ActiveLabel
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

enum ActiveElement {
    case Mention(String)
    case Hashtag(String)
    case URL(String)
    case Regex([String])
    case None
}

public enum ActiveType {
    case Mention
    case Hashtag
    case URL
    case Regex
    case None
}

func activeElement(word: String) -> ActiveElement {
    if let url = reduceRightToURL(word) {
        return .URL(url)
    }
    
    if word.characters.count < 2 {
        return .None
    }
    
    // remove # or @ sign and reduce to alpha numeric string (also allowed: _)
    guard let allowedWord = reduceRightToAllowed(word.substringFromIndex(word.startIndex.advancedBy(1))) else {
        return .None
    }
    
    if word.hasPrefix("@") {
        return .Mention(allowedWord)
    } else if word.hasPrefix("#") {
        return .Hashtag(allowedWord)
    } else {
        return .None
    }
}

private func reduceRightToURL(str: String) -> String? {
    if let urlDetector = try? NSDataDetector(types: NSTextCheckingType.Link.rawValue) {
        let nsStr = str as NSString
        let results = urlDetector.matchesInString(str, options: .ReportCompletion, range: NSRange(location: 0, length: nsStr.length))
        if let result = results.map({ nsStr.substringWithRange($0.range) }).first {
            return result
        }
    }
    return nil
}

private func reduceRightToAllowed(str: String) -> String? {
    if let regex = try? NSRegularExpression(pattern: "^[a-z0-9_]*", options: [.CaseInsensitive]) {
        let nsStr = str as NSString
        let results = regex.matchesInString(str, options: [], range: NSRange(location: 0, length: nsStr.length))
        if let result = results.map({ nsStr.substringWithRange($0.range) }).first {
            if !result.isEmpty {
                return result
            }
        }
    }
    return nil
}

func reduceToRegex(mutAttrString: NSMutableAttributedString, regex: NSRegularExpression, replaceHandler: ([String] -> String?)? = nil) -> [(range: NSRange, values: [String])]? {
    if mutAttrString.string.isEmpty {
        return nil
    }
    
    var elements = [(range: NSRange, values: [String])]()
    var location = 0
    while let result = regex.firstMatchInString(mutAttrString.string, options: [], range: NSRange(location: location, length: mutAttrString.length - location)) {
        var values = [String]()
        for i in 0..<result.numberOfRanges {
            let value = (mutAttrString.string as NSString).substringWithRange(result.rangeAtIndex(i))
            values.append(value)
        }
        
        let elementRange: NSRange
        if let content = replaceHandler?(values) {
            mutAttrString.replaceCharactersInRange(result.range, withString: content)
            elementRange = NSRange(location: result.range.location, length: (content as NSString).length)
        } else {
            elementRange = result.range
        }
        elements.append((range: elementRange, values: values))
        
        location = elementRange.location + elementRange.length
    }
    
    return elements
}
