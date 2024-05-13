//
//  Node.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

// Node is an object. What we will do is do a render pass turn a tree of views into a tree of nodes.
// Next time something changes in state we keep updating the node's with the latest view
final class Node {
    var children: [Node] = []
    var needsRebuild = true
    var view: BuiltinView!
    var previousView: Any?
    var statePropeties: [String: Any] = [:]
    
    // Since we have a `rebuildIfNeeded` we have a flag `needsRebuild` and this is set as `true` for the initial pass
    func rebuildIfNeeded() {
        view._buildNodeTree(self)
    }
}

// This means we have to store the view's pervious value in the node so taht we can compare the current view to it
