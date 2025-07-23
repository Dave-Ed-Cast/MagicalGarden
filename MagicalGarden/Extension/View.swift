//
//  View.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI

extension View {
    /// For iOS anchoring of the menu
    func anchorToTopLeft() -> some View { modifier(AnchorToTopLeftModifier()) }
}

struct AnchorToTopLeftModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            Spacer()
                .frame(height: 40)

            HStack(alignment: .top) {
                Spacer()
                    .frame(width: 20)

                content

                Spacer()
            }

            Spacer()
        }
    }
}
