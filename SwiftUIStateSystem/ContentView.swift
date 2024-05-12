//
//  ContentView.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import SwiftUI


struct ContentView: View {
    @State var counter = 0
    
    var body: some View {
        print("ContentView body")
        return VStack {
            Button("\(counter)") {
                counter += 1
            }
            Nested()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
