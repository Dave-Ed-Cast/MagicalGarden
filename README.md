# Magical Garden – AR Experience

**Magical Garden** is an augmented reality application that allows users to cultivate mystical metallic plants in their environment. Built with SwiftUI, RealityKit, and Reality Composer, the app supports both iOS 18.x and VisionOS 2.x platforms.

> Note: Due to lack of device, visionOS features were not tested on a physical device and device only APIs could not be tested. However, it is highly possible that everything might work as intended so please do test the application. The app was developed with compatibility in mind.

## Features

- Place and interact with three unique mystical plants in AR
- Each plant triggers an attention call after a random growth period
- Tapping a plant during its "call" causes it to grow and bloom
- Once all plants mature, a garden-wide bloom event is triggered
- Supports both iOS and visionOS platforms
- Guided onboarding tutorial for first-time users
- Audio and visual effects synchronized with interaction stages

## Setup and Build Instructions

1. Clone or download the repository
2. Open `MagicalGarden.xcodeproj` in the latest version of Xcode that supports iOS 18.x or VisionOS 2.x (or beta 26)
3. Select a build target:
   ## - iPhone or Apple Vision Pro (recommended)
   ## - simulators
4. Build and run

No external dependencies are required. The project uses SwiftUI, RealityKit, and system-provided tools only.

## Core Interactions

| Interaction        | Trigger                              | Result                                           |
|--------------------|--------------------------------------|--------------------------------------------------|
| Onboarding         | First app launch                     | Displays guided tutorial                         |
| Plant Placement    | Tap on a detected surface            | Places one of three mystical plants              |
| Growth Call        | Random timer (30s–3m) after placement| Plant shows visual cue and sends notifications   |
| User Interaction   | Tap during "call" state              | Triggers growth and bloom animation              |
| Garden Bloom       | All three plants matured             | Environment-wide bloom event with music and VFX  |
| Reset Garden       | Menu option with confirmation        | Resets all plant state and placement             |

### Component Map

- `Views/Immersive/ImmersiveView.swift`: Main immersive AR scene container
- `Models/ObjectSpawnHandler.swift`: Handles object placement and logic
- `Components/PlaneDetectionComponent.swift`: Plane detection abstraction for iOS and VisionOS
- `Models/AudioManager.swift`: Controls playback of background and event-specific audio
- `Views/OnboardingView.swift`: Presents tutorial on first launch
- `Models/PlantStage.swift`: Enum representing different lifecycle stages of plants

## Development Decisions and Tradeoffs

| Decision                              | Rationale                                                                 |
|---------------------------------------|---------------------------------------------------------------------------|
| Used combined Growth + Bloom USDZ     | Simplifies animation control and timing                                   |
| Swapped to Bloom animation when needed| Improves modularity and prepares for possible future feature extensions   |
| Skipped persistence                   | Time constraints and insufficient testing prevented solid implementation  |
| Skipped spatial audio                 | Not testable without Vision Pro hardware                                  |
| Developed on iOS with VisionOS in mind| Enabled faster iteration and ensured compatibility despite lack of device |
| Main logic class exceeds ideal size   | Consolidated code for dual-platform support due to limited time           |

## Demo and Testing

- The app runs fully on iOS 18.x simulators or devices.
- visionOS support is included and compiles, but could not be tested on hardware. However everything should work accordingly.
- 
## Future Improvements

- Implement persistent storage of plant states and growth progress
- Add spatial audio for immersive feedback on Vision Pro
- Refactor large control classes into smaller, testable modules
