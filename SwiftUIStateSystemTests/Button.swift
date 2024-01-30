//
//  Button.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

struct Button: View {
    var title: String
    var action: () -> ()
    
    init(_ title: String, action: @escaping () -> ()) {
        self.title = title
        self.action = action
    }
    
    var body: Never {
        fatalError()
    }
}
