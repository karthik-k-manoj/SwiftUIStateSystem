//
//  View.swift
//  SwiftUIStateSystem
//
//  Created by Karthik K Manoj on 30/01/24.
//

import Foundation

protocol View {
    associatedtype Body: View
    var body: Body { get }
}
