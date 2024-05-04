//
//  SwiftUIStateSystemTests.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import XCTest

final class SwiftUIStateSystemTests: XCTestCase {
    func testUpdate() {
        // construct a content view
        let v = ContentView()
        // construct a node (root node)
        let node = Node()
        
        v.buildNodeTree(node)
        
        var button: Button { 
            node.children[0].view as! Button
        }
        
        XCTAssertEqual(button.title, "0")
        
        button.action()
        node.needsRebuild = true // TODO this should happen automatically
        node.rebuildIfNeeded()
        
        XCTAssertEqual(button.title, "1")
    }
}
