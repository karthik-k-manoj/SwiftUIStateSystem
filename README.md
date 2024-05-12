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


// Property Wrapper

We'll look at implementing the `ObservedObject` property wrapper. It's purpose turns out to be quite simple: it observes it's wrapped object 
by subscribing to the `objectWillChange` publisher of that object. When that publisher emits, the `ObservedObject` invalidates the view it's in,
regardless of whether the state actually changes.


// SwiftUI State Explained: Tuple Views and View Builders 

To construct more complex view hierachies for our tests, we first build tuple views adn view builders

In previous epoise we build `ObservedObject` property wrapper, but we only tested our implementation 
using a simple setup a single view holding a `ObservedObject` property. Today we wan to look at how SwiftUI
deals with nested views that may or may not depend on a value from an `ObservedObject`and specifically which 
`body` is executed and when. We then want to mimic that behaviour in our implementation

 We start with an empty SwiftUI project and we copy our `ContentView` and `Model` into into it


// SwiftUI State Explained: Bindings


- We implement the binding property wrapper and add a projected value on the observed object

 Today we will look at the `Binding` property wrapper and creating bindings an `ObservedObject`
 but first, we have to take care of a subtle issue from last week, when we started to compare view values
 to avoid unnecessary renders.
 
 Fixing the Issue
 
 We can demonstrate that issue in a normal SwiftUI project. Let's say we have a view with a `@ObservedOject`
 property that we assign a global model object to:
 
 import SWiftUI
 
 class Model: ObserveableObject {
    @Published var counter = 0
} 

let nestedModel = Model()

struct Nested: View {
    @ObservedObject var model = nestedModel
    
    var body: some View {
        print("Nested body")
        return Text("TODO")
    }
}

We nest this view in the main `ContentView` where we use `@State` property to trigger view updates.
We also add print statements so we can see when a view gets rendered

struct ContentView: View {
    @State var counter = 0
    
    var body: some View {
        print("ContentView body")
        return VStack {
            Button("Increment") { counter += 1 }
            Nested()
        }
        .padding()
    }
}

When we press the button, the body of the `ContentView`  needs to reexectured because it depeneds on
the `counter` state. But the button action doesn't anything for the nested view so that view's body isn't executed'

Back in our implementaion, we add a test that asserts we follow the same logic as SwiftUI if the parameters
of nested view which contains an `ObservedObject`, don't change, the view shouldn't get rerendered

let nestedModel = Model()

func setUp() {
    nestedBodyCount = 0
    contentViewBodyCount = 0
    nestedModel.counter = 0
}

func testUnchangedNestedWithObservedObject() {
    struct Nested: View {
        @ObserbedObject var model = nestedModel
        
        var body: some View {
            nestedBodyCount += 1
            return Button("Nested Button", action: {})
        }
    }
    
    struct ContentView: View {
        @ObservedObject var model = Model()
        
        var body: some View {
            Button("\(model.counter)" {
                model.counter += 1
            }
            
            Nested()
                .debug {
                    contentViewBodyCount += 1
                }
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

We run the test and we see that it fails; the nested view's body is executed not once but twice. This has
to with the way we compare old and new view values

When `ContentView` gets rerendered, a new value of Nested is constructed and we compare this value to the previous
iteration to determine whether we have to rexecute it's body. This comparison is done by looping over the view's properties
and checking if they're `Equatable` and equal.  If we find a property that's not `Equatable` we always rerender the view
and this is the case in our test setup, as the `ObservedObject` property wrapper is not `Equatable`

Since `ObservedObject` already keeps track of changes to the object it observes we just need to check if the view holds
the same object as before. Only if it holds a differenet object than previous view value do we have to rerender the view

So we conform `ObservedObject` to `Equatable` and do a pointer comparisons of the wrapped object

extension ObservedObject: Equatable {
    static func ==(l: ObservedObject, r: ObservedObject) -> Bool {
        l.wrappedValue === r.wrappedValue
    }
} 

With that in place, the test succeeds and we can move on to Binding

Let's first look at how a binding is treated by SwiftUI state system. Say we have a view that takes a
binding.

struct Nested: View {
    @Binding var counter: Int 
    
    var body: some View {
        print("Nested body")
        return Text("\(counter)"
    }
}

For this view, we can create a binding from an observed from an observed object by using the dollar
sign prefix

struct ContentView: View {
    @ObservedObject var model = Model()
    
    var body: some View {
        print("ContentView body")
        return VStack {
            Button("\(model.counter)") { model.counter += 1 }
            Nested(counter: $model.counter)
        }
    }
}

When we click the button, the model observed by the `ContentView` is changed causing the view
to be rerendered. This causes a new Nested value to be created, for which a new `Binding` is also 
created. This even happens if the nested view doesn't actually use the binding in it's body

struct Nested: View {
    @Binding var counter: Int
    
    var body: some View {
        print("Nested body")
        return Text("Hello")
    }
}


In short if a view has a `@Binding` property it's `body` always gets reexecuted. SwiftUI
must do so because a binding stores getter and setter functions and functions cant be compareed
to each other.

We can also demonstrate this if we call the model's `objectWillChange` instead of writing
to the binding.

struct ContentView: View {
    @ObservedObject var model = Model()
    
    var body: some View {
        print("ContentView Body")
        return VStack {
            Button("\(model.counter)") 
        }
    }
}

The binding simply always invalidates the nested view


Implementing Binding
-------------------

Let's see how we can recreate this. We begin by writing a test in which we assert that a nested view
with a binding gets rerendered with every state change

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
            Nested(counter: $model.counter)
                .debug {
                    contentViewBodyCount += 1
                }
        }
    }
    
    let v = ContentView()
    let node = Node()
    v.buildNodeTree(node)
    XCTAssertEqual(cpmtemtViewBodyCount, 1)
    XCTAssertEqual(, 1)
}
}
To make this test compile, we have to implement both `Binding` and it's `ObservedObject.projectedValue`

The `Binding` property wrapper stores a getter and a setter function. We implement it's `wrappedValue` as a computed property
that call these two functions

@propertyWrapper
public struct Binding<Value> {
    var get: () -> Value
    var set: (Value) -> ()
    
    public var wrappedValue: Value {
        get { get() }
        set { set(newValue)
    }
}


Bindings from ObservedObject

To make the dollar sign syntax work, we need to implement `projectedValue` on the `ObservedObject` property wrapper.
As the projected value, SwiftUI returns a wrapped around the observable object. This wrapper uses dynamic member loolup
of the observed object's properties to construct the key path needed for the binding. This is how ther wrapper type is declared 
in the headers


We add a wrapper type to our implementation and we return a value of this type from the projectValue

@propertyWrapper
struct ObservedObject<ObjectType: ObservableObject>: AnyObservedObject {
    private var box: ObservedObjectBox<ObjectType>
    
    @dynamicMemberLookup
    struct Wrapper {
        private var observedObject: ObservedObject<ObjectType>
        
        fileprivate init(_ o: ObservedObject<ObjectType>) {
            observedObject = o
        }
        
        subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Value>) -> Binding<Value> {
            Binding(get {
                observedObject.wrappedValue[keyPath: keyPath],
                set: {
                observedObject.wrappeedValue[keyPath: keyPath] = $0
                }
            
            })
        }
    }
    
    var projectedValue: Wrapper {
        Wrapper(self)
    }
}

We add the `@dynamicMemberLookup` attribute to the wrapper which means we have to implement `subscript(dynamicMember:)
When we accessa property on the wrapper. Swift call this subscript method after converting our dot synatx into a key path.
In the subscript method, we create a binding using the given key path

So what happens when we call $model.counter? The projected value accessed with `$model` returns `Wrapper` struct. Because
that struct implements dynamic member look up we can use normal doy syntax -- `.counter` to access a property on the observable
object. This looks like we are directly accessing a property on the observable object. But we are actually creating a wrapper
passing in a key path which returns a Binding to that property 

Testing Binding

The test now passes which means the view gets invalidated correctly But we should also test that `Binding` actually works
in terms of getting and setting values

When we try setting a value to the binding we get a compiler error that binding is immutable

func testBinding2() {
    struct Nested: View {
        @Binding var counter: Int 
        var body: some View {
            nestedBodyCount += 1
            return Button("\(counter)", action: { counter += 1})
        }
    }
}

If we assign to a property of the struct we mutate the struct. But in this case we aren't actually mutating the `Binding` itself
we are only calling the set function. SO we can mark the wrapper value setter as non mutating

@propertyWrapper 
struct Binding<Value> {
    var get: () -> Value
    var set: (value) -> ()
    
    var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }
}


Now we can update the models/ counter from the nested view. We remove the button from Content View and we add assertions about
the buttons title going from 0 to 1

wo
