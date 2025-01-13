import SwiftUI
import AVFoundation
import Speech

class VisionAssistantViewModel: ObservableObject {
    @Published var isListening = false
    @Published var response = ""
    private var speechRecognizer: SpeechRecognizer
    private var cameraController: CameraController
    private var networkManager: NetworkManager

    init(speechRecognizer: SpeechRecognizer = SpeechRecognizer(),
         cameraController: CameraController = CameraController(),
         networkManager: NetworkManager = NetworkManager.shared) {
        self.speechRecognizer = speechRecognizer
        self.cameraController = cameraController
        self.networkManager = networkManager
    }

    func startListening() {
        isListening = true
        speechRecognizer.startRecording { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let question):
                self.handleQuestion(question)
            case .failure(let error):
                print("Recognition error: \(error)")
            }
            self.isListening = false
        }
    }

    private func handleQuestion(_ question: String) {
        cameraController.capturePhoto { [weak self] image in
            guard let self = self, let image = image else { return }
            self.networkManager.uploadPhotoAndQuestion(image: image, question: question) { result in
                switch result {
                case .success(let answer):
                    self.response = answer
                    LMNTSpeech.shared.speak(answer)
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }

    func stopListening() {
        isListening = false
        speechRecognizer.stopRecording()
    }
} 