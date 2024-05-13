//
//  State.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 12/05/24.
//

import Foundation

// We set up the `State` property wrapper

protocol StateProperty {
    var value: Any { get nonmutating set }
}

@propertyWrapper
struct State<Value>: StateProperty {
    private var box: Box<StateBox<Value>>
    
    init(wrappedValue: Value) {
        self.box = Box(value: StateBox(wrappedValue))
    }
    
    var wrappedValue: Value {
        get {
            box.value.value
        }
        
        nonmutating set {
            box.value.value = newValue
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
    
    var value: Any {
        get { box.value }
        nonmutating set { box.value = newValue as! StateBox<Value>  }
    }
}


final class Box<Value> {
    var value: Value
    
    init(value: Value) {
        self.value = value
    }
}


/*
 Now we can store a dependeny view when it gets the value of `StateBox`. The dependent we want to
 store is the view's Node so that we can update it's `needsRebuild` flag. But we don't to strongly
 reference these nodes. If a node goes away we should simply stop rebuiling it. So we add another type of box
`Weak` which stores a weak reference. Since we can't weakly reference a value types we have to constrain the box's
 wrapped type, A to be an object, Now we can append a new Weak<Node> to the dependencies of the StateBox. The
 simpliest way to get access to the node that's being built is by using global variable.
 */

var currentGlobalBodyNode: Node? = nil

final class Weak<A: AnyObject> {
    weak var value: A?
    
    init(value: A) {
        self.value = value
    }
}

final class StateBox<Value> {
    private var _value: Value
    private var dependencies: [Weak<Node>] = []
    
    init(_ value: Value) {
        self._value = value
    }
    
    var value: Value {
        get {
            dependencies.append(Weak(value: currentGlobalBodyNode!))
            // skip duplicates and remove nil entries
            return _value
        }
        
        set {
            _value = newValue
            for d in dependencies {
                d.value?.needsRebuild = true
            }
        }
    }
}
/*
 The above implementation has a couple of caveats. Every time we rebuild a node tree, we add notes
 to dependecies array of each StateBox. This means that the same node can be in the array multiple times
 Also we are not cleaning up the nodes that have gone away. so there acn be empty Weak boxes boxes in the array
 */
