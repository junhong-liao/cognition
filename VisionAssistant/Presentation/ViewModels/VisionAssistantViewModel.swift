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
    
    // Add camera warm-up state
    private var isCameraWarmedUp: Bool = false
    
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
    
    func startWorkflow() async {
        do {
            // 1. Warm up camera if needed
            if !isCameraWarmedUp {
                try await warmUpCamera()
            }
            
            // 2. Listen for question
            let question = try await listenForQuestion()
            self.recognizedText = question
            
            // 3. Capture photo
            guard let image = try await capturePhoto() else {
                throw VisionError.cameraError("Failed to capture image")
            }
            
            // 4. Process image and question
            let answer = try await processImageUseCase.execute(image: image, question: question)
            
            // 5. Speak response
            await MainActor.run {
                self.response = answer
                self.isSpeaking = true
            }
            try await lmntSpeechService.speak(answer)
            
            await MainActor.run {
                self.isSpeaking = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isListening = false
                self.isSpeaking = false
            }
        }
    }
    
    private func warmUpCamera() async throws {
        guard let camera = cameraController else {
            throw VisionError.cameraError("Camera not initialized")
        }
        
        // Warm up sequence
        try await camera.prepare()
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        isCameraWarmedUp = true
    }
    
    private func listenForQuestion() async throws -> String {
        await MainActor.run { self.isListening = true }
        
        return try await withCheckedThrowingContinuation { continuation in
            speechRecognizer.startRecording { result in
                switch result {
                case .success(let text):
                    continuation.resume(returning: text)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func capturePhoto() async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            cameraController.capturePhoto { image in
                continuation.resume(returning: image)
            }
        }
    }
} 