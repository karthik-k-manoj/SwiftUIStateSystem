//
//  ViewBuilder.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 06/05/24.
//

import Foundation

/*
 We want to clean up our code by implementing `ViewBuilder` and using it construct the `TupleView`
 
 `ViewBuilder` is what's called a result builder (previously function builder). To implement this result builder,
 we first need a static method called `buildBlock` which takes a single view and returns it
 
 Then we add an overload that accepts two views and returns a `TupleView`
 */

@resultBuilder
struct ViewBuilder {
    static func buildBlock<V: View>(_ content: V) -> V {
        content
    }
    
    static func buildBlock<V1: View, V2: View>(_ v1: V1, _ v2: V2) -> TupleView {
        TupleView(v1, v2)
    }
}
