//
//  SwiftUIStateSystemTests.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import XCTest

// We reset the counters to zero in the test cases `setUp` method, which gets called before the test

/*
 In a new test method, we assert that `contentViewBodyCount` and `nestedBodyCount` are both equal to `1`
 */
final class SwiftUIStateSystemTests: XCTestCase {
    override class func setUp() {
        nestedBodyCount = 0
        contentViewBodyCount = 0
    }
    
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

        node.rebuildIfNeeded()
        
        XCTAssertEqual(button.title, "1")
    }
    
    // In this method we assert that `contentViewBodyCount` and
    // `nestedBodyCount` are both equal to 1 when we first build the node tree,
    // and that only `contentViewBodyCount` is incremented to 2 after we run the button action
    // and rebuild the node tree. The test fails because the nested view's body is also executed
    // when the button is pressed. Let's figure out why this happens and how we can avoid it
    func testConstantNested() {
        let v = ContentView()
        let node = Node()
        
        v.buildNodeTree(node)
        
        XCTAssertEqual(contentViewBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        
        button.action()
        
        node.rebuildIfNeeded()
        
        XCTAssertEqual(contentViewBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 1)
    }
}

/*
 At some point when we rebuild the node tree after the button press, we end up in `buildNodeTree` on the `ContentView`
 Since that view needs a rebuild and it's not a `BuiltinView` the view's `body` gets executed, and we call `buildNodeTree` on
 the body view which includes the nested view. Then `Nested` executes it's body view but it doesn't check `needsRebuild` in this proccess
 
 We only call `rebuildIfNeeded` once a the the start of the `build` That's wrong; we need to move this check into the recurssion
 
 After processing `BuiltinViews` we check if a node doesn't need a rebuild to see if we can skip it. However we still want
 to forward the call to the view's children so that they have a chance to rebuild if they need to
 */
