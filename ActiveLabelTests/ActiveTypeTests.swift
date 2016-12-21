//
//  ActiveTypeTests.swift
//  ActiveTypeTests
//
//  Created by Johannes Schickling on 9/4/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import XCTest
@testable import ActiveLabel

extension ActiveElement: Equatable {}

func ==(a: ActiveElement, b: ActiveElement) -> Bool {
    switch (a, b) {
    case (.mention(let a), .mention(let b)) where a == b: return true
    case (.hashtag(let a), .hashtag(let b)) where a == b: return true
    case (.url(let a), .url(let b)) where a == b: return true
    case (.none, .none): return true
    default: return false
    }
}

class ActiveTypeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInvalid() {
        XCTAssertEqual(activeElement(""), ActiveElement.none)
        XCTAssertEqual(activeElement(" "), ActiveElement.none)
        XCTAssertEqual(activeElement("x"), ActiveElement.none)
        XCTAssertEqual(activeElement("ಠ_ಠ"), ActiveElement.none)
        XCTAssertEqual(activeElement("😁"), ActiveElement.none)
    }
    
    func testMention() {
        XCTAssertEqual(activeElement("@userhandle"), ActiveElement.mention("userhandle"))
        XCTAssertEqual(activeElement("@userhandle."), ActiveElement.mention("userhandle"))
        XCTAssertEqual(activeElement("@_with_underscores_"), ActiveElement.mention("_with_underscores_"))
        XCTAssertEqual(activeElement("@u"), ActiveElement.mention("u"))
        XCTAssertEqual(activeElement("@."), ActiveElement.none)
        XCTAssertEqual(activeElement("@"), ActiveElement.none)
    }
    
    func testHashtag() {
        XCTAssertEqual(activeElement("#somehashtag"), ActiveElement.hashtag("somehashtag"))
        XCTAssertEqual(activeElement("#somehashtag."), ActiveElement.hashtag("somehashtag"))
        XCTAssertEqual(activeElement("#_with_underscores_"), ActiveElement.hashtag("_with_underscores_"))
        XCTAssertEqual(activeElement("#h"), ActiveElement.hashtag("h"))
        XCTAssertEqual(activeElement("#."), ActiveElement.none)
        XCTAssertEqual(activeElement("#"), ActiveElement.none)
    }
    
    func testURL() {
        XCTAssertEqual(activeElement("http://www.google.com"), ActiveElement.url("http://www.google.com"))
        XCTAssertEqual(activeElement("https://www.google.com"), ActiveElement.url("https://www.google.com"))
        XCTAssertEqual(activeElement("https://www.google.com."), ActiveElement.url("https://www.google.com"))
        XCTAssertEqual(activeElement("www.google.com"), ActiveElement.url("www.google.com"))
        XCTAssertEqual(activeElement("google.com"), ActiveElement.url("google.com"))
    }
    
}
