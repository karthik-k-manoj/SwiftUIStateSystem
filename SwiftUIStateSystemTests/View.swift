//
//  View.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

protocol View {
    associatedtype Body: View
    var body: Body { get }
}

// When we first build a node, we need to find the `ObservedObject`'s in the view and subscribe to the
// ObservableObject they wrap. We only need to do this for (user defined) View's since our `BuiltInView`'s
// won't have any observed object

/*
 In the `builNodeTree` method, we want to inspect the view and find the `ObservedObject`s in it. We
 call a new method - `observeObjects - to start observing and we pass the view's node in for storing the
 observation
 */

extension View {
    // Not a requirement. This is an implementation detail.
    // It takes a node and modifies it
    func buildNodeTree(_ node: Node) {
        if let b = self as? BuiltinView {
            node.view = b
            b._buildNodeTree(node )
            return
        }  
        
        node.view = AnyBuiltinView(self)
        
        self.observeObjects(node)
        
        // Create a new view value each time we call this.
        // Check if we actually need to execute the body. For now we do it Node `needsReBuild`. For now that should be fine.
        let b = body
        
        // Here we get to see that we are not creating a new node if it's already there.
        // We will reuse the old node that will also to maintain state
        
        if node.children.isEmpty {
            node.children = [Node()]
        }
        
        b.buildNodeTree(node.children[0])
        node.needsRebuild = false
    }
}

extension View {
    // In the this methid, we create a `Mirror` of the view and we loop over the mirror's children to check
    // their types
    func observeObjects(_ node: Node) {
        let m = Mirror(reflecting: self)
        
        // We can't cast to `ObservedObject` because this type is generic over it's wrapped object's type
        // So we instead add a non-generic protocol declaring subscription methodm we conform `ObservedObject`
        // to it and we cast the child to that protocol
        for child in m.children {
            guard let observedObject = child.value as? AnyObservedObject else { return }
            // observed object of this specific view is fetched and called `addDependency` with that view's node
            observedObject.addDependency(node)
        }
    }
}

extension Never: View {
    var body: Never {
        fatalError("We should never reach this")
    }
}
