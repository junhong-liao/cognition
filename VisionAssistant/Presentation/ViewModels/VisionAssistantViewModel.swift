import SwiftUI
import Combine
import AVFoundation

class VisionAssistantViewModel: ObservableObject {
    @Published var isListening: Bool = false
    @Published var response: String = ""
    @Published var recognizedText: String = ""
    @Published var errorMessage: String?
    @Published var isSpeaking: Bool = false
    @Published var showCameraError: Bool = false
    @Published var showMicError: Bool = false
    
    private let speechRecognizer: SpeechRecognizing
    private let cameraController: CameraControlling
    private let processImageUseCase: ProcessImageUseCase
    private let lmntSpeechService: SpeechSynthesizing
    
    init(
        speechRecognizer: SpeechRecognizing,
        cameraController: CameraControlling,
        processImageUseCase: ProcessImageUseCase,
        lmntSpeechService: SpeechSynthesizing
    ) {
        self.speechRecognizer = speechRecognizer
        self.cameraController = cameraController
        self.processImageUseCase = processImageUseCase
        self.lmntSpeechService = lmntSpeechService
    }
    
    func onAppear() {
        // Check if camera is set up, show error otherwise
        if !cameraController.isSetup {
            showCameraError = true
        }
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    func startListening() {
        isListening = true
        recognizedText = ""
        
        speechRecognizer.startRecording { [weak self] result in
            guard let self = self else { return }
            
            self.isListening = false
            switch result {
            case .success(let question):
                // Save recognized text for display
                self.recognizedText = question
                // Process the question asynchronously
                self.handleQuestion(question)
            case .failure(let error):
                // If error is microphone-related, showMicError
                self.showMicError = true
                self.errorMessage = "Error: \(error)"
            }
        }
    }
    
    func stopListening() {
        isListening = false
        speechRecognizer.stopRecording()
    }
    
    private func handleQuestion(_ question: String) {
        cameraController.capturePhoto { [weak self] uiImage in
            guard let self = self else { return }
            
            // If no image was captured, show camera error
            guard let image = uiImage else {
                self.showCameraError = true
                return
            }
            
            Task {
                do {
                    // Pass the image & question to the domain use case
                    let answer = try await self.processImageUseCase.execute(image: image, question: question)
                    // Update response for UI
                    await MainActor.run {
                        self.response = answer
                    }
                    // Speak the response
                    try await self.lmntSpeechService.speak(answer)
                    // Mark isSpeaking as false when done
                    await MainActor.run {
                        self.isSpeaking = false
                    }
                } catch {
                    // Handle any errors from the use case or speechService
                    await MainActor.run {
                        self.errorMessage = "Error: \(error)"
                    }
                }
            }
        }
    }
} 