//
//  Nested.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 05/05/24.
//

import SwiftUI

// We create `Nested` view and we add print statements to each of the view's body properties
// and to the intializer of the nested view to see which parts get executed

// When we run the app we can see that `ContentView` is initialized and it's `body` is executed.
// This automatically initializes the `Nested` view and it's `body` is also executed.
// When we press the button SwiftUI executed the `body` of the `ContentView` again and it creates
// a new value of `Nested`, but it doesn't execute the nested view's body.

// Next we want to see what happens if we pass the model's counter value to the `Nested`
// This time nested view's body also gets executed when we press the button, even though the `body`
// doesn't uses the counter. Beacause `counter` is a plain property and not a `@State` or `@Binding` property
// SwiftUI can't track whether or not the property is used. Therefore, it needs to account for the worst
// case scenario and rerender the view

/*
 In conclusion, we need to the examine the `View` value after an update and if it's somehow different
 from previous version, we need to rerender it. We'll get started with this idea in mind, and later on we'll
 take a closer look at what is means for a view to "be different"
 */

struct Nested: View {
    var counter: Int
    
    init(counter: Int) {
        self.counter = counter
        print("Nested init")
    }
    
    var body: some View {
        print("Nested body")
        return Text("TODO")
    }
}

struct Nested_Previews: PreviewProvider {
    static var previews: some View {
        Nested(counter: 0)
    }
}

