//
//  View.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

// If we add the `@ViewBuilder` attribute to the `body` property of the `View` protocol itself
// we don't have to add it to every implementation separately.
protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}

extension View {
    func debug(_ f: () -> ()) -> some View {
        f()
        return self
    }
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
        
        /*
         SwiftUI probably keeps a list of nodes that needs a rebuild and only rebuilds
         those nodes directly. Our approach going through the enitre tree and skipping
         the nodes that don't needs to rebuilt - is simpler but less efficient
         
         We no longer needs to check `needsRebuild` in the `rebuildIfNeeded` method
         because we perform that check `_buildNodeTree`
         */
        let shouldRunBody = node.needsRebuild || !self.equalToPrevious(node)
        if !shouldRunBody {
            for child in node.children {
                child.rebuildIfNeeded()
            }
            
            return
        }
        
        node.view = AnyBuiltinView(self)
        
        self.observeObjects(node)
        self.restoreStateProperties(node)
        
        // Create a new view value each time we call this.
        // Check if we actually need to execute the body. For now we do it Node `needsReBuild`. For now that should be fine.
        // For each parent node, we create the child view and child node in this method
        let b = body
        
        // Here we get to see that we are not creating a new node if it's already there.
        // We will reuse the old node that will also to maintain state
        
        if node.children.isEmpty {
            node.children = [Node()]
        }
        
        let childNode = node.children[0]
        // Now child view and child node are used to build it's node
        b.buildNodeTree(childNode)
        
        self.storeStateProperties(node)
        node.previousView = self
        node.needsRebuild = false
    }
    
    // Restore is basically updating the wrapped value
    func restoreStateProperties(_ node: Node) {
        let m = Mirror(reflecting: self)
        for (label, value) in m.children {
            guard let prop = value as? StateProperty else { continue }
            guard let propValue = node.statePropeties[label!] else { continue }
            prop.value = propValue
        }
    }
    
    /*
     In this we loop over the the properites that conform to `StateProperty` and we store their values in the node
     */
    // store is basically storing it in a dictionary owned by node
    func storeStateProperties(_ node:  Node) {
        let m = Mirror(reflecting: self)
        for (label, value) in m.children {
            guard let prop = value as? StateProperty else { continue }
            node.statePropeties[label!] = prop.value
        }
        
    }
}
/*
 In the `equalToPrevious` method we first check if the previous view is non-nil and it can be cast to the
 same type as the current view. If either of check fails we return false
 
 Now we can use reflection to pair up and compare the properties of the two view value. If the labels
 of a pair of properties don't match - which would be the case for different enum values - we also return false
 
 Then we have to compare two values of pair of properties. We'll implement this comaprison in a separate function
 but if that function returns false for any pairt of properties, we also return `false` from `equalToPrevious`. Finally if we make it past all the above checks we consider the views to be equal, so we return true
 */

extension View {
    func equalToPrevious(_ node: Node) -> Bool {
        guard let previous = node.previousView as? Self else { return false }
        let m1 = Mirror(reflecting: self)
        let m2 = Mirror(reflecting: previous)
        for pair in zip(m1.children, m2.children) {
            guard pair.0.label == pair.1.label else { return false }
            let p1 = pair.0.value
            let p2 = pair.1.value
            if p1 is StateProperty { continue }
            if !isEqual(p1, p2) { return false }
        }
        
        return true
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



