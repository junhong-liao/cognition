import Foundation
import UIKit
import AVFoundation

class MockSpeechRecognizer: SpeechRecognizing {
    var mockResult: Result<String, Error>?
    var didCallStartRecording = false
    var didCallStopRecording = false
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        didCallStartRecording = true
        if let result = mockResult {
            completion(result)
        }
    }
    
    func stopRecording() {
        didCallStopRecording = true
    }
}

class MockCameraController: CameraControlling {
    var isSetup: Bool = true
    var previewLayer: AVCaptureVideoPreviewLayer? = nil
    var mockImage: UIImage?
    var didCallCapturePhoto = false
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        didCallCapturePhoto = true
        completion(mockImage)
    }
}

class MockSpeechService: SpeechSynthesizing {
    var isSpeaking: Bool = false
    var didCallSpeak = false
    var mockError: Error?
    
    func speak(_ text: String) async throws {
        didCallSpeak = true
        if let error = mockError {
            throw error
        }
        isSpeaking = true
    }
    
    func stop() {
        isSpeaking = false
    }
}

class MockNetworkManager: NetworkServicing {
    var mockResponse: VisionResponse?
    var mockError: Error?
    var didCallUpload = false
    
    func uploadPhotoAndQuestion(image: UIImage, question: String) async throws -> VisionResponse {
        didCallUpload = true
        if let error = mockError {
            throw error
        }
        return mockResponse ?? VisionResponse(result: "Mock response")
    }
} 