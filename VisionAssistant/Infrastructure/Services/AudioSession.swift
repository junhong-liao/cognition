import SwiftUI
import AVFoundation

class AudioSessionManager: ObservableObject {
    @Published var isActive: Bool = false
    
    func configureSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try await session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try await session.setActive(true, options: .notifyOthersOnDeactivation)
        isActive = true
    }
    
    func deactivateSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try await session.setActive(false)
        isActive = false
    }
}

// Usage in SwiftUI view:
struct RecordingView: View {
    @StateObject private var audioSession = AudioSessionManager()
    
    var body: some View {
        VStack {
            // ... recording UI
        }
        .task {
            try? await audioSession.configureSession()
        }
    }
} 