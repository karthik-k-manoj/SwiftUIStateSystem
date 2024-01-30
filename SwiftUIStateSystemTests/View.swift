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

extension View {
    func buildNodeTree(_ node: Node) {
        if let b = self as? BuiltinView {
            node.view = b
            b._buildNodeTree(node)
            return
        }
        
        node.view = AnyBuiltinView(self)
        
        let b = body
        
        if node.children.isEmpty {
            node.children = [Node()]
        }
        b.buildNodeTree(node.children[0])
        node.needsRebuild = false
    }
}

extension Never: View {
    var body: Never {
        fatalError("We should never reach this")
    }
}
