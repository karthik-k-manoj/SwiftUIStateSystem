//
//  State.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 12/05/24.
//

import Foundation

// We set up the `State` property wrapper

protocol StateProperty {}

@propertyWrapper
struct State<Value>: StateProperty {
    private var box: Box<Value>
    
    init(wrappedValue: Value) {
        self.box = Box(value: wrappedValue)
    }
    
    var wrappedValue: Value {
        get {
            box.value
        }
        
        nonmutating set {
            box.value = newValue
        }
    }
}


final class Box<Value> {
    var value: Value
    
    init(value: Value) {
        self.value = value
    }
}
