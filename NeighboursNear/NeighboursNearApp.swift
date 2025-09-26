//
//  NeighboursNearApp.swift
//  NeighboursNear
//
//  Created by Simon on 25.09.2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct NeighboursNearApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: StoreOf<AppFeature>.init(initialState: .init(), reducer: {
                AppFeature()
            }))
        }
    }
}
