//
//  AnyEquatable.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 08/05/24.
//

import Foundation


/*
 In the `isEqual` function we recieve two `Any` values and we want to find out whether or not these values
 are `Equatable` and equal. Because the `Equatable` protocol has `Self` requirement, we're unable to cast to it - the compiler wouldn't know what type `Self` is and therefore which implementation of `==` to use
 
 We could try to ask for the values' type using `type(of:)`. At runtime this might tell us that lhs is an `Int`'
 For example. However we can't use this info to turn the `Any` value into a typed variable
 */

/*
But there's something else we can do using a trick we learned from Mathhew Johnson -
 The (public but hidden) function `_openExistential` can tke a value of type `Any` and pass it into a generic closure
 Inside the closure, we receive the actual type of `lhs`
 */

/*
 We create a non-generic version of `Equatable: AnyEquatable` This also defines `isEqual` function but this one takes
 two value of type `Any` instead of a generic type. This makes it possible to case to this protoocl since it has no `Self`
 requirement
 */

protocol AnyEquatable {
    static func isEqual(lhs: Any, rhs: Any) -> Bool
}

/*
 Now we need something to conform to this protocol- we define an empty enum with a generic
 parameter `T`. We use an empty enum because we don't want to create instance of it, but rather
 only use it's type declaration.
 */

enum Wrapped<T> {}

// We conditionally conform `Wrapped` to `AnyEqutable` if it's type parameter T conforms
// to `Equatable`

/*
 We are using dynamic casting to implement the conforamce; if we can cast lhs and rhs to the
 `Equatable` type T then we can compare the values using the equality operator `==`
 */

extension Wrapped: AnyEquatable where T: Equatable {
    static func isEqual(lhs: Any, rhs: Any) -> Bool {
        guard let l = lhs as? T , let r = rhs as? T else {
            return false
        }
        
        return l == r
    }
}

func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    //guard let l = lhs as? Equatable else {
        // error
    //}
    
    //lhs as! type(of: lhs) // this doesn't work
    
    // Now we can try casting `Wrapped<LHS>` to the `AnyEquatable` type. if this succeeds
    // we know `LHS` must conform to `Equatable`. If it fails it means we aren't dealing with
    // an `Equatable value so we return `false`
    
    /*
     If the cast succeed then `typeInfo` holds an `AnyEquatable` type and we can call it's static method `isEqual`
     */
    func f<LHS>(lhs: LHS) -> Bool {
        if let typeInfo = Wrapped<LHS>.self as? AnyEquatable.Type {
            return typeInfo.isEqual(lhs: lhs, rhs: rhs)
        }
        
        return false
        
    }
    
    // Note. The underscore prefix of `_openExistential` means we should consider it to be private and subject to change
    // we don't want to use this kind of API i
    return _openExistential(lhs, do: f)
    
}

/*
 This way of comparing `Any` value is a bit of hack but it's the best solution we found to mimic
 SwiftUI runtime behaviour without losing it's declrative nature
 */
