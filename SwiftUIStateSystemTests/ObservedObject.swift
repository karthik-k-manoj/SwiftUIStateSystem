//
//  ObservedObject.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 05/05/24.
//

import Foundation
import Combine

protocol AnyObservedObject {
    func addDependency(_ node: Node)
}

// In `ObservedObject` we create a box for the `ObservableObject`. And we return the object from the box as the `wrappedValue`
@propertyWrapper
struct ObservedObject<ObjectType: ObservableObject>: AnyObservedObject {
    private var box: ObservedObjectBox<ObjectType>
    
    init(wrappedValue: ObjectType) {
        self.box = ObservedObjectBox(object: wrappedValue)
    }
    
    var wrappedValue: ObjectType {
        box.object
    }
    
    func addDependency(_ node: Node) {
        box.addDependency(node)
    }
}

// We need a way to keep the observation alive by storing the cancellable returned from sink.
// For this we write a private class, `ObservedObjectBox`, which can hold on to the object and the cancellable

fileprivate final class ObservedObjectBox<ObjectType: ObservableObject> {
    var object: ObjectType
    var cancellable: AnyCancellable?
    weak var node: Node?
    
    init(object: ObjectType, cancellable: AnyCancellable? = nil) {
        self.object = object
        self.cancellable = cancellable
    }
    
    // Now we can start the actual observaton by subscribing to the observable object's
    // `objectWillChange` publisher. In the subscription's callback we set `needsRebuild` on the node
    
    // Each time we call `addDependency` this overwrites the cancellable with a new one causing th
    // nodes' previous subscription to the `ObservedOject` to be cancled as a new subscription is created.
    // But we don't want to resubscribe  to the same object every time we update our `ContentView`. So we store
    // the node and we check is the node passed into addDependecy is a different one before replacing the subscription
    // This is more efficient than unsubscribing and resubscribing with every view update
    // If we get a different node then we need to change the subscription. An observed object will not be passed around
    // It is a property of a single view. If we want to observe the same object multiple times then we create multiple Observed object
    func addDependency(_ node: Node) {
        if node === self.node { return }
        self.node = node
        
        cancellable = object.objectWillChange.sink { _ in
            // this is known as invalidting the view
            node.needsRebuild = true
        }
    }
}
