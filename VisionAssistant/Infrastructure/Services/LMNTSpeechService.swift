import Foundation
import AVFoundation

class AudioPlayerService: SpeechSynthesizing {
    @Published var isSpeaking = false
    private var player: AVAudioPlayer?
    
    func speak(_ text: String) async throws {
        // Get audio data from backend
        let audioData = try await NetworkManager.shared.getSpeechAudio(for: text)
        
        try await MainActor.run {
            player = try AVAudioPlayer(data: audioData)
            player?.delegate = self
            isSpeaking = true
            player?.play()
        }
    }
    
    func stop() {
        player?.stop()
        isSpeaking = false
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
    }
} 