//
//  AnyBuiltinView.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

// Basically erases the generic `Body` type
struct AnyBuiltinView: BuiltinView {
    private var buildNodeTree: (Node) -> ()
    
    init<V: View>(_ view: V) {
        self.buildNodeTree = view.buildNodeTree(_:)
    }
    
    func _buildNodeTree(_ node: Node) {
        buildNodeTree(node)
    }
}
