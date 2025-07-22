//
//  AudioManager.swift
//  MagicalGarden
//
//  Created by Davide Castaldi on 22/07/25.
//

import AVFoundation

final class AudioManager {
    static let shared = AudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    func playBackgroundMusic(named filename: String, loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "wav") else {
            print("Audio file not found: \(filename)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = loop ? -1 : 0
            audioPlayer?.volume = 0.5
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play background music: \(error)")
        }
        print("playing music")
    }
    
    func stopBackgroundMusic() { audioPlayer?.stop() }
}
