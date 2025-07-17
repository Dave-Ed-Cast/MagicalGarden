//
//  AnchorToTopRightModifier.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 16/07/25.
//

import SwiftUI

struct AnchorToTopRightModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            Spacer()
                .frame(height: 40)

            HStack(alignment: .top) {
                Spacer()

                content

                Spacer()
                    .frame(width: 20)
            }

            Spacer()
        }
    }
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

extension View {
    func anchorToTopRight() -> some View {
        modifier(AnchorToTopRightModifier())
    }

    func anchorToTopLeft() -> some View {
        modifier(AnchorToTopLeftModifier())
    }
}
