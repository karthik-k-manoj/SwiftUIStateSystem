//
//  TupleView.swift
//  SwiftUIStateSystemTests
//
//  Created by Karthik K Manoj on 06/05/24.
//

import Foundation

/*
 If we want to write a similat test setup in our non-SwiftUI project, the first challenge we face
 is adding a nested view to `ContentView`. For this we need to define a `TupleView` whhich is a `BuiltInView`
 that stores two or more child views
 
 By wrapping the child views in `AnyBuiltinView`'s and storing them in an array, it'll be easy to later on
 write additional initializers that accept more than 2 views
 
 In `_buildNodeTree`, we have to iterate over `children` and recursively call `_buildNodeTree` on each
 child view. For each of these calls, we check if the passed in node already contains a child node for the
 child view in question and if it doesn't we createa  new one
 */
struct TupleView: BuiltinView, View {
    var children: [AnyBuiltinView]
    
    init<V1: View, V2: View>(_ v1: V1, _ v2: V2) {
        self.children = [AnyBuiltinView(v1), AnyBuiltinView(v2)]
    }
    
    func _buildNodeTree(_ node: Node) {
        for idx in children.indices {
            if node.children.count <= idx {
                node.children.append(Node())
            }
            
            let child = children[idx]
            child._buildNodeTree(node.children[idx])
        }
        
    }
}
/*
 Then we have to able to wrap views in a `TupleView`. In SwiftUI we use a view builder to define
 a view's content. We'll also write a view builder later on but for now we can create a `TupleViwq`
 manually
*/



