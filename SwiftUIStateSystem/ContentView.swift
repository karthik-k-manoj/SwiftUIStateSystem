//
//  ContentView.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var model = Model()
    
    var body: some View {
        print("ContentView body")
        return VStack {
            Button("\(model.counter)") {
                //model.counter += 1
                model.objectWillChange.send() // counter has not changed at all
            }
            Nested(counter: $model.counter) // This always created a new Binding and that means
            // it invalidtes our Nested view and the nested view gets rerendered (body is executed)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// In principle a `Binding` is really simple it is jsut a wrapper around getter and a setter 
