import Foundation
import AVFoundation

class LMNTSpeechService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.lmnt.com/v1/speech/synthesize"
    private var player: AVAudioPlayer?
    @Published var isSpeaking = false
    
    init(apiKey: String = ProcessInfo.processInfo.environment["LMNT_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }
    
    func speak(_ text: String) async throws {
        guard !text.isEmpty else {
            throw VisionError.invalidData
        }
        
        // Create request
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare request body
        let body = [
            "text": text,
            "voice": "adam",  // Default voice
            "format": "mp3",
            "speed": 1.0
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw VisionError.networkError
        }
        
        // Play audio
        try await MainActor.run {
            try playAudio(data)
        }
    }
    
    private func playAudio(_ data: Data) throws {
        player?.stop()
        player = try AVAudioPlayer(data: data)
        player?.delegate = self
        
        guard let player = player else {
            throw VisionError.processingError("Failed to create audio player")
        }
        
        isSpeaking = true
        player.play()
    }
    
    func stop() {
        player?.stop()
        isSpeaking = false
    }
}

extension LMNTSpeechService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isSpeaking = false
    }
} 