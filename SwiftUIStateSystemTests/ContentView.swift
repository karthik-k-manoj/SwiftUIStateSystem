//
//  ContentView.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

// To test the number of times a `body` is executed, we define a couplp of global counter variables

var nestedBodyCount = 0
var contentViewBodyCount = 0

struct Nested: View {
    var body: some View {
        nestedBodyCount += 1
        return Button("Nested Button", action: {})
    }
}


struct ContentView: View {
    @ObservedObject var model = Model()

    // We cannot add statement other than returning a `View`. Instead we can define a helper method that execute
    // a closure to `View` and do the increment in a call to that helper
    var body: some View {
        Button("\(model.counter)") {
            model.counter += 1
        }
        
        Nested()
            .debug {
                contentViewBodyCount += 1
            }
    }
}
