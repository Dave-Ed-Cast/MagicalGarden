//
//  MenuView.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI
import RealityKit

struct MenuView: View {
    
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @Bindable var appModel: AppModel
    
    var body: some View {
        
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Text("Welcome to the garden! Interact with the button to enter or exit it.")
                Text("Once inside, place the plant(s) on the highlighted plane.")
            }
            Spacer()
            .multilineTextAlignment(.center)
            .font(.footnote)
            Toggle(
                appModel.wantsToPresentImmersiveSpace ? "Exit" : "Enter",
                isOn: $appModel.wantsToPresentImmersiveSpace
            )
            .font(.largeTitle)
            .buttonBorderShape(.roundedRectangle(radius: 36))
            .toggleStyle(EnterReturnToggleStyle())
            .frame(width: 300)
        }
        
    }
}

struct EnterReturnToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
                .frame(maxWidth: .infinity, idealHeight: 50)
        }
    }
}
