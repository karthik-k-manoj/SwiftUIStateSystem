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

let nestedModel = Model()

final class SwiftUIStateSystemTests: XCTestCase {
    override func setUp() {
        nestedBodyCount = 0
        contentViewBodyCount = 0
        nestedModel.counter = 0
    }
    
    func testUpdate() {
        // construct a content view
        let v = ContentView()
        // construct a node (root node)
        let node = Node()
        
        v.buildNodeTree(node)
        
        var button: Button { 
            node.children[0].children[0].view as! Button
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
    
    // rebuilding a view means executing the view's body
    /*
     When we add the counter plan old property even without using it in the body the view should rebuild
     itself every time the value of the property changes. But it doesn't because we don't set it's `needsRebuild` flag to `true`
     */

    func testChangedNested() {
        struct Nested: View {
            var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button", action: {})
            }
        }
        
        struct ContentView: View {
            @ObservedObject var model = Model()
            
            var body: some View {
                contentViewBodyCount += 1
                let button = Button("\(model.counter)") {
                    model.counter += 1
                }
                
                let nested = Nested(counter: model.counter)
                return TupleView(button, nested)
            }
        }
        
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
        // Need to fix this
        XCTAssertEqual(nestedBodyCount, 2)
    }
    
    /*
     We can add a third test with a nested view that depends on the parent view's state,
     but whose properties don't actually change - for example, a view that only changes when a passed
     in `counter` parameter exceeds 10. This test shows that view doesnt get rendered when we incremeny
     only once
     */
    func testUnchangedNested() {
        struct Nested: View {
            var isLarge = false
            
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button", action: {})
            }
        }
        
        struct ContentView: View {
            @ObservedObject var model = Model()
            
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                
                Nested(isLarge: model.counter > 10)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }
        
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
    
    func testUnchangedNestedWithObservedObject() {
        struct Nested: View {
            //  We need to only check if previous and current observed object wrapped observable obejct are the same
            // as observedObject will only take care of their properties. If there is change in properties
            // then it is goin to rerender the view it is in
            @ObservedObject var moedel = nestedModel
            
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button", action: {})
            }
        }
        
        struct ContentView: View {
            @ObservedObject var model = Model()
            
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                
                Nested()
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }
        
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
    
    func testBinding1() {
        struct Nested: View {
            @Binding var counter: Int
            
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button", action: {})
            }
        }
        
        struct ContentView: View {
            @ObservedObject var model = Model()
            
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                
                // $dollar syntax
                Nested(counter: $model.counter)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }
        
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
        XCTAssertEqual(nestedBodyCount, 2)
    }
    
    
    func testBinding2() {
        struct Nested: View {
            @Binding var counter: Int
            
            var body: some View {
                nestedBodyCount += 1
                return Button("\(counter)", action: {
                    counter += 1
                })
            }
        }
        
        struct ContentView: View {
            @ObservedObject var model = Model()
            
            var body: some View {
                // $dollar syntax
                Nested(counter: $model.counter)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }
        
        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)

        var button: Button {
            node.children[0].children[0].view as! Button
        }
        
        XCTAssertEqual(contentViewBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        XCTAssertEqual(button.title, "0")
        
        button.action()
        node.rebuildIfNeeded()
        
        XCTAssertEqual(contentViewBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 2)
        XCTAssertEqual(button.title, "1")
    }
    
    func testSimple() {
        struct Sample: View {
            @State var counter = 0
            
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }
        
        let s = Sample()
        let node = Node()
        s.buildNodeTree(node)
        
        var button: Button {
            node.children[0].view as! Button
        }
        
        XCTAssertEqual(button.title, "0")
        
        button.action()
        node.needsRebuild = true
        node.rebuildIfNeeded()
        
        XCTAssertEqual(button.title, "1")
    }
    
    func testStateWithNested() {
        struct Nested: View {
            @State var counter = 0
            
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }
        
        /*
         When this Sample view is rebuild, a new Nested view gets created with - by default - the same initial state.
         This is why we need to restore the state from the view's previous value
         
         
         We refine our test o check the nested view's state. Both button should start with the title 0. When we
         execute the nested button action and rebuild the view we expect the nested button title to change to 1
         
         The test fails; the nested button title is stil 0 after the rebuild. Let's think about how we compare
         old and new view to determine if we have to rerender a view. because we probably have to do something
         special for @State properties
         
         We're comparing values of the state property like any other property. But later on we will make
         State explicity invalidate the view if it's value changes so we can actually skip these properties when
         comparing views
         
         Due to `State` bring generic we can't literally check whether a property is `State`. Instead we add a protocol
         to which we conform only `State` and we check whether a property conforms to that protocol
         */
        
        struct Sample: View {
            @State var counter = 0
            
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
                Nested()
            }
        }
        
        let s = Sample()
        let node = Node()
        s.buildNodeTree(node)
        
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        
        let nestedNode = node.children[0].children[1]
        
        var nestedButton: Button {
            nestedNode.children[0].view as! Button
        }
        
        XCTAssertEqual(button.title, "0")
        XCTAssertEqual(nestedButton.title, "0")
        
        nestedButton.action()
        nestedNode.needsRebuild = true
        
        node.rebuildIfNeeded()
        
        XCTAssertEqual(button.title, "0")
        XCTAssertEqual(nestedButton.title, "1")
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


// Comparing Views
/*
 We ended with a failing test. If we have a view nested inside a views that's invalidated by an `ObservedObject`
 that the nested view also gets rebuilt if it has changed, regardless of whether it's explicitly invalidated itself
 */

/*
 To make this work we need to find out if a view has changed compared to it's previous state. `Views` don't conform
 to `Equatable` by default so we need some other way to check for equality
 
 And we can't get around this by simply rebuildining every child of an invalidated view because then we would be doing
 too much work; we don't want to rebuild a view that hasn't changed

 */

// Checking for changes
/*
 Let's first look at `buildNodeTree`. In this function we executea a view's `body` if the view's node if the view's node is flagged
 with `needRebuild`. We broaden this condition to also rebuild the view if it isn't equal to it's previous iteration.
 */


