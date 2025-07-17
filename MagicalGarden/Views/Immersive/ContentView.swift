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
        ToggleImmersiveSpaceButton()
    }
}


#Preview {
    ContentView()
}
#endif
