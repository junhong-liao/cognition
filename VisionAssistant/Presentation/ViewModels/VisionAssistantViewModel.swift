import SwiftUI
import AVFoundation

@MainActor
class VisionAssistantViewModel: ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var showCameraError = false
    @Published var showMicError = false
    @Published var isCameraSetup = false
    @Published var errorMessage: String?
    @Published var isSpeaking = false
    
    private let speechRecognizer: SpeechRecognizing
    private let cameraController: CameraControlling
    private let speechService: SpeechSynthesizing
    private let networkManager: NetworkServicing
    
    init(speechRecognizer: SpeechRecognizing,
         cameraController: CameraControlling,
         speechService: SpeechSynthesizing,
         networkManager: NetworkServicing) {
        self.speechRecognizer = speechRecognizer
        self.cameraController = cameraController
        self.speechService = speechService
        self.networkManager = networkManager
        
        // Observe camera setup state
        self.cameraController.$isSetup
            .assign(to: &$isCameraSetup)
            
        // Observe speech state
        self.speechService.$isSpeaking
            .assign(to: &$isSpeaking)
    }
    
    func onAppear() {
        checkPermissions()
    }
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    private func checkPermissions() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.showCameraError = !granted
            }
        }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.showMicError = status != .authorized
            }
        }
    }
    
    private func startListening() {
        isListening = true
        recognizedText = ""
        
        speechRecognizer.startRecording { [weak self] result in
            switch result {
            case .success(let question):
                self?.recognizedText = question
                self?.capturePhotoWithQuestion(question)
            case .failure(let error):
                self?.handleError(error)
            }
            self?.isListening = false
        }
    }
    
    private func stopListening() {
        isListening = false
        speechRecognizer.stopRecording()
    }
    
    private func capturePhotoWithQuestion(_ question: String) {
        AudioServicesPlaySystemSound(1108)
        
        cameraController.capturePhoto { [weak self] image in
            guard let image = image else {
                self?.handleError(CameraError.captureError)
                return
            }
            // Next step: send to backend
        }
    }
    
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
        }
    }
    
    private func handleResponse(_ response: String) async {
        do {
            try await speechService.speak(response)
        } catch {
            handleError(error)
        }
    }
} 