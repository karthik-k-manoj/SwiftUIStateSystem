//
//  ContentView.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

struct Nested: View {
    var body: some View {
        Button("Nested Button", action: {})
    }
}

struct ContentView: View {
    @ObservedObject var model = Model()
    
    var body: some View {
        let button = Button("\(model.counter)") {
            model.counter += 1
        }
        
        let nested = Nested()
        return TupleView(button, nested)
    }
}
