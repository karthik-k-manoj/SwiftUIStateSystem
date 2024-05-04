//
//  README.md
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 04/05/24.
//

If some state changes after a view hierarchy has been rendered in SwiftUI, the system rerenders the parts of the view
hierarchy that depends on that particular piece of state. We establish a view's dependency on some state using various
property wrappers such as `State`, `StateObject`, `ObservedObject`, `Binding`. Without fully understanding how these 
dependencies work, it can be difficult to know when and why state change trigger view updates. 

Something to keep in mind is the difference between intializing a `View` and executing it's `body` property. These are two
separate actions and we want to examine abd replicate how SwiftUI performs these actions. And in doing so our goal isn't to
write the most efficient code possible, but to make the state system as understandable as possible

Let's define a simple test case. We create a `Model` class that has a `counter` property and we conform the class to `ObservableObject`
which we import from Combine framework. We store an instance of this class in a view we let the view observe it. We return a button as the
view's body, and it shows the counter's current value and increments the counter when tapped. When th button is tapped, it changes the model
After this, the view should automatically be rendered again to show the increment count. 

We will define `View` protocol to create a dummy button and more importantly: we'll create a persistent `Node` tree that shadows the view tree.

In the WWDc talk Demystify SwiftUI, Apple discuess how a view can be represneted by different `View` values over time, but the the view's lifetime
is equal to the lifetimes of it's identity. And a view's identity can be established in different ways:

1) Based on the view's place in the view tree; Apple calls this structural identity (position in the view tree)
2) Using identifiers like we do with `ForEach` or the `.id(_:)` view modifier; Apple calls this explicit identity

As long as SwiftUI keeps view alive or view has identity then we need to have the node instance of the view. 
It will contain state for the view
 
In our implementations we focus on structural identity to determine view's lifetime. 
And we want to persist a view's state in a `Node` throughout the view's lifetime.

// Creating a Button

To start our implemetation, we need to define some building blocks start with `View`

protocol View {
    associatedType Body: View
    var body: Body { get }
}

We also need a `Button` View

struct Button: View {
    var title: String
    var action: () -> ()
    
    init(_ title: String, action: @escaping () -> ()) {
        self.title = title
        self.action = action
    }
    
    var body: Never {   
        fatalError()
    }
}

The button won't do anything because we won't be rendering anything, so we throw a fatal error in the body property,
This means the `Button.Body` type is `Never`, so we need to conform `Never` type to `View`

extension Never: View {
    var body: Never {
        fatalError("We should never reach this.")
    }
}

// Node Tree

 The next thing we need for our test is a way to convert out `View` into a `Node` tree
 
 
final class Model: ObservableObject {
    @Published var counter: Int = 0
}

struct ContentView: View {
    var model = Model()
    
    var body: some View {
        Button("\(model.counter)") {
            model.counter += 1
        }
    }
}

final class NotSwiftUIStateTests: XCTestCase {
    func testUpdate() {
        let v = ContentView()
        v.buildNodeTree()
    }
}

For each part of the view tree, we want a node. For our sample view, this means we create a node for the `ContentView` and one 
for it's body view: the `Button`. To enable the construction of a tree of nodes, we define a `children` property - which stores
an array of child nodes - on `Node`

final class Node {
    var children: [Node] = []
} 

The idea is to construct a node tree once and update it with each "render pass" of our view tree. To update the tree, we write
a method on `Node` which we can call to let the node update itself if needed. We also add a flag, `needRebuild`. We also add a flag
`needsRebuild`, that we can flip if the node should update itself.

In our test we create a root node and we pass it to `buildNodeTree` method on the root view to construct the initial node tree

func class NotSWiftUIStateTests: XCTestCase {
    func testUpdate() {
        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
    }
}  

We need to add this method to `View` It isn't a protocol requirement but rather an implementation detail, so we write method in an 
extension of protocol:

extension View {
    func buildNodeTree(_ node: Node) {
    
    }
}

To execute `rebuildIfNeeded` a node needs access to the view it represents to call `buildNodeTree` on it. So we need a way
to store the view in the node but we can't simply store a `View` value in the node because `View` is a generic protocol 
(i.e. it has an associated type)

final class Node {
    var children: [Node] = []
    var needsRebuild = true
    var view: View // Protocol `View` can only be used as a generic constraint because it has `Self` or associated type requirement
    
    func rebuildIfNeeded() {
        if needsRebuild {
            view.buildNodeTree(self)
        }
    }
}

We can get around this generic problem by distinguishing between user-defined `View`s and `BuiltinViews` The `BuiltinView` protocol 
can have the `buildNodeTree` method as its single requirement, thus avoiding the need for an associated type. This makes it possible to use
`BuiltinView` as a wrapper around `View` and to store view values in `Node` 
