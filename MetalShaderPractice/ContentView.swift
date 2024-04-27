//
//  ContentView.swift
//  MetalShaderPractice
//
//  Created by Chiaote Ni on 2024/4/13.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: Part I
                Spacer()
                // Point / Line / Plane: How metal render the texture, and what's its coordinate system
                NavigationLink("Basic color rendering") {
                    BasicDemoView()
                }
                Spacer()
                // Image Blending
                NavigationLink("Image blending") {
                    ImageBlendingDemoView()
                }
                Spacer()
                NavigationLink("Video editing") {

                }
                Spacer()
                NavigationLink("SwiftUI") {

                }
            }
            .padding(50)
        }
    }
}

#Preview {
    ContentView()
}
