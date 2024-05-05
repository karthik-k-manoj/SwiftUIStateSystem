//
//  ContentView.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import SwiftUI

final class Model: ObservableObject {
    @Published var counter = 0
}

struct ContentView: View {
    @ObservedObject var model: Model
    
    init(model: Model) {
        self._model = ObservedObject(wrappedValue: model)
    }
    
    var body: some View {
        Button("\(model.counter)") {
            model.counter += 1
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: Model())
    }
}
