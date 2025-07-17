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
        case 1: "dicomIcon"
        case 2: "Sphere"
        case 3: "Window"
        default: "unexpected"
        }
    }
    
    var bodyText: String {
        switch stepNumber {
        case 1: "Import the DICOM dataset from your local folder into the system."
        case 2: "The system will generate a 3D model from the imported DICOM dataset."
        case 3: "The system allows connection to a fluoroscope for real-time streaming of live 2D X-ray images."
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
                .frame(width: 160, height: 160)

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
