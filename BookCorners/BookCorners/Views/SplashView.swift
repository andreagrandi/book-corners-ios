//
//  SplashView.swift
//  BookCorners
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(red: 0.30, green: 0.56, blue: 0.16)
                .ignoresSafeArea()
            Image("SplashImage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .accessibilityLabel("Book Corners — Share, Discover, Read")
        }
    }
}

#Preview {
    SplashView()
}
