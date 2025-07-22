//
//  MagicalGardenApp.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI

@main
struct MagicalGardenApp: App {
    
    @State private var appModel = AppModel()
    @State private var onboarding: OnboardingParameters = .init()
    @State var isMenuExpanded: Bool = true
    
#if os(visionOS)
    var body: some Scene {
        WindowGroup(id: "main") {
            ZStack {
                if onboarding.completed {
                    ContentView()
                } else {
                    InfoView(showInfo: .constant(true))
                }
            }
            .frame(width: 676, height: 550)
            .fixedSize()
        }
        
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear { appModel.immersiveSpaceState = .open }
                .onDisappear { appModel.immersiveSpaceState = .closed }
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
#endif
    
#if os(iOS)
    var body: some Scene {
        
        Group {
            let size = UIScreen.main.bounds.size
            WindowGroup {
                ZStack {
                    if appModel.immersiveSpaceState == .open {
                        ZStack {
                            ImmersiveView()
                                .environment(appModel)
                                .onAppear { AudioManager.shared.playBackgroundMusic(named: "Music") }
                                .onDisappear { AudioManager.shared.stopBackgroundMusic() }
                        }
                    }
                    
                    DisclosureGroup("Menu", isExpanded: $isMenuExpanded) {
                        MenuView(appModel: appModel)
                    }
                    .frame(width: isMenuExpanded ? size.width * 0.79 : size.width * 0.2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .animation(.default, value: isMenuExpanded)
                    .anchorToTopLeft()
                }
                .ignoresSafeArea()
            }
            .onChange(of: appModel.wantsToPresentImmersiveSpace) { _, newValue in
                appModel.immersiveSpaceState = newValue ? .open : .closed
                
                if newValue { isMenuExpanded = false }
                
            }
        }
    }
#endif
    
}
