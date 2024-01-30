//
//  BuiltinView.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

protocol BuiltinView {
    func _buildNodeTree(_ node: Node)
}

extension BuiltinView {
    var body: Never {
        fatalError("We should never reach this")
    }
}
