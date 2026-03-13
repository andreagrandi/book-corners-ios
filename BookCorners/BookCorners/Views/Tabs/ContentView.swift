//
//  ContentView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Nearby", systemImage: "books.vertical", value: 0) {
                LibraryListView()
            }

            Tab("Map", systemImage: "map", value: 1) {
                MapTabView()
            }

            Tab("Submit", systemImage: "plus.circle", value: 2) {
                SubmitLibraryView()
            }

            Tab("Profile", systemImage: "person", value: 3) {
                Text("Profile")
            }
        }
    }
}

#Preview {
    ContentView()
}
