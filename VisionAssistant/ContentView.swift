import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var cameraController = CameraController()
    @State private var isListening = false
    @State private var questionText = ""
    
    var body: some View {
        VStack {
            // Camera preview
            CameraPreview(cameraController: cameraController)
                .frame(height: 300)
            
            // Question display
            Text(questionText)
                .padding()
            
            // Listen button
            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
            }) {
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: 40))
                    .foregroundColor(isListening ? .red : .blue)
            }
            .padding()
        }
    }
    
    private func startListening() {
        isListening = true
        speechRecognizer.startRecording { result in
            switch result {
            case .success(let text):
                questionText = text
                captureAndSendPhoto(with: text)
            case .failure(let error):
                print("Recognition error: \(error)")
            }
            isListening = false
        }
    }
    
    private func stopListening() {
        isListening = false
        speechRecognizer.stopRecording()
    }
    
    private func captureAndSendPhoto(with question: String) {
        cameraController.capturePhoto { image in
            guard let image = image else { return }
            NetworkManager.shared.uploadPhotoAndQuestion(image: image, question: question) { result in
                switch result {
                case .success(let response):
                    // Use text-to-speech to speak the response
                    speak(response)
                case .failure(let error):
                    print("Upload error: \(error)")
                }
            }
        }
    }
} 