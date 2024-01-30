//
//  Button.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

struct Button: View, BuiltinView {
    var title: String
    var action: () -> ()
    
    init(_ title: String, action: @escaping () -> ()) {
        self.title = title
        self.action = action
    }
    
    func _buildNodeTree(_ node: Node) {
        // todo create a UIButton
    }
}
