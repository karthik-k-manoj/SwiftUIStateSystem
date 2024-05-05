//
//  ObservedObject.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 05/05/24.
//

import Foundation


@propertyWrapper
struct ObservedObject<ObjectType: ObservableObject> {
    var wrappedValue: ObjectType
}
