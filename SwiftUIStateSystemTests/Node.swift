//
//  Node.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

final class Node {
    var children: [Node] = []
    var needsRebuild = true
    var view: BuiltinView!
    
    func rebuildIfNeeded() {
        if needsRebuild {
            view._buildNodeTree(self)
        }
    }
}
