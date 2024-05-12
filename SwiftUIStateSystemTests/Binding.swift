//
//  Binding.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 12/05/24.
//

import Foundation

@propertyWrapper
public struct Binding<Value> {
    var get: () -> Value
    var set: (Value) -> ()
    
    public var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) } // we cannot use setter because `struct` is immutable. It does not need to be  mutating. Setter is just changing property of an object
    }
}
