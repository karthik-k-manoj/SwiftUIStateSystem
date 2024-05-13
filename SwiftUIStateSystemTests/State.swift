//
//  State.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 12/05/24.
//

import Foundation

// We set up the `State` property wrapper

protocol StateProperty {
    var value: Any { get nonmutating set }
}

@propertyWrapper
struct State<Value>: StateProperty {
    private var box: Box<Box<Value>>
    
    init(wrappedValue: Value) {
        self.box = Box(value: Box(value: wrappedValue))
    }
    
    var wrappedValue: Value {
        get {
            box.value.value
        }
        
        nonmutating set {
            box.value.value = newValue
        }
    }
    
    var value: Any {
        get { box.value }
        nonmutating set { box.value = newValue as! Box<Value>  }
    }
}


final class Box<Value> {
    var value: Value
    
    init(value: Value) {
        self.value = value
    }
}
