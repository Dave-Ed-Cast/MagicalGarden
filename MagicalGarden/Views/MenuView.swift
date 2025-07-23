//
//  MenuView.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI
import RealityKit

#if os(iOS)
struct MenuView: View {
    
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @Bindable var appModel: AppModel
    
    var body: some View {
        
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Welcome to the Magical Garden!")
                    .font(.headline.bold())
                
                Text("Step into or out of the garden whenever you like. \nOnce inside, gently place your plant on the designed surface to begin.")
                    .font(.footnote)
            }
            
            Spacer()
            
            Toggle(
                appModel.wantsToPresentImmersiveSpace ? "Step Out" : "Step Into the Garden",
                isOn: $appModel.wantsToPresentImmersiveSpace
            )
            .font(.title2)
            .buttonBorderShape(.roundedRectangle(radius: 36))
            .toggleStyle(EnterReturnToggleStyle())
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9)
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
#endif
