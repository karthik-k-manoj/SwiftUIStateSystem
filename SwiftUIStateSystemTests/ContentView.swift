//
//  ContentView.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

struct ContentView: View {
    var model = Model()
    
    var body: some View {
        Button("\(model.counter)") {
            model.counter += 1
        }
    }
}
