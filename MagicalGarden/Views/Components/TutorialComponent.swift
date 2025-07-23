//
//  TutorialComponent.swift
//  AnAppleADay
//
//  Created by Davide Castaldi on 27/02/25.
//

import SwiftUI

struct TutorialComponent: View {
    
    let stepNumber: Int

    var imageName: String {
        switch stepNumber {
        case 1: "garden"
        case 2: "surfaces"
        case 3: "bloom"
        default: "unexpected"
        }
    }
    
    var bodyText: String {
        switch stepNumber {
        case 1: "Enter the garden by interacting with the interface."
        case 2: "Look around for surfaces that light up, and click on them to spawn plants"
        case 3: "When the plants are ready, they will be signaled."
        default: "Unexpected tutorial step."
        }
    }

    var body: some View {
        VStack {
            Text("Step \(stepNumber)")
                .font(.title)
            
            Spacer()
            
            Image(imageName)
                .resizable()
                .frame(width: 320, height: stepNumber == 3 ? 200 : 160)

            Spacer()
            
            Text(bodyText)
                .frame(width: 200)
                .multilineTextAlignment(.center)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
    }
}
