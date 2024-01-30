//
//  SwiftUIStateSystemTests.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import XCTest

final class SwiftUIStateSystemTests: XCTestCase {
    func testUpdate() {
        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        
        let button = node.children[0].view as! Button
        XCTAssertEqual(button.title, "0")
    }
}
