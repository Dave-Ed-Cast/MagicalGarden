//
//  ContentView.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 17/07/25.
//

import SwiftUI
#if os(visionOS)
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to the Magical Garden!")
                .font(.title3.bold())
            
            Text("Step into or out of the garden whenever you like. \nOnce inside, gently place your plant on the designed surface to begin.")
                .font(.headline)
            
            ToggleImmersiveSpaceButton()
        }
    }
}


#Preview {
    ContentView()
}
#endif
