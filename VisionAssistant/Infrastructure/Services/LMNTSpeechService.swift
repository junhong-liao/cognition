import Foundation
import AVFoundation

protocol SpeechSynthesizing {
    func speak(_ text: String) async throws
    func stop()
}

class LMNTSpeechService: SpeechSynthesizing {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func speak(_ text: String) async throws {
        let url = URL(string: "https://api.lmnt.com/v1/speech/synthesize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "text": text,
            "voice": "lily",
            "format": "mp3"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Play the audio
        try await playAudio(data)
    }
    
    private func playAudio(_ data: Data) async throws {
        // Implementation for playing the audio
    }
    
    func stop() {
        // Implementation for stopping audio playback
    }
} 