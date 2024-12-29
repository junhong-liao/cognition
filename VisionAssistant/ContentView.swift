import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var cameraController = CameraController()
    @State private var isListening = false
    @State private var response = ""
    
    var body: some View {
        VStack {
            // Camera preview
            CameraPreview(cameraController: cameraController)
                .frame(height: 300)
            
            // Response text
            Text(response)
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
            case .success(let question):
                // 1. Take photo
                cameraController.capturePhoto { image in
                    guard let image = image else { return }
                    
                    // 2. Send to backend
                    NetworkManager.shared.uploadPhotoAndQuestion(image: image, question: question) { result in
                        switch result {
                        case .success(let answer):
                            // 3. Get response and speak it
                            response = answer
                            LMNTSpeech.shared.speak(answer)
                        case .failure(let error):
                            print("Error: \(error)")
                        }
                    }
                }
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
} 