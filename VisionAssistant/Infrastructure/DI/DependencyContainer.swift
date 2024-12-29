import Foundation

// Protocol for each service type
protocol SpeechRecognizing {
    func startRecording(completion: @escaping (Result<String, Error>) -> Void)
    func stopRecording()
}

protocol CameraControlling {
    var isSetup: Bool { get }
    var previewLayer: AVCaptureVideoPreviewLayer? { get }
    func capturePhoto(completion: @escaping (UIImage?) -> Void)
}

protocol SpeechSynthesizing {
    var isSpeaking: Bool { get }
    func speak(_ text: String) async throws
    func stop()
}

protocol NetworkServicing {
    func uploadPhotoAndQuestion(image: UIImage, question: String) async throws -> VisionResponse
}

// Main container
class DependencyContainer {
    static let shared = DependencyContainer()
    
    // Services
    private(set) lazy var speechRecognizer: SpeechRecognizing = SpeechRecognizer()
    private(set) lazy var cameraController: CameraControlling = CameraController.shared
    private(set) lazy var speechService: SpeechSynthesizing = LMNTSpeechService()
    private(set) lazy var networkManager: NetworkServicing = NetworkManager()
    
    // Environment
    private(set) var environment: AppEnvironment
    
    private init(environment: AppEnvironment = .production) {
        self.environment = environment
    }
    
    // Factory method for view models
    func makeVisionAssistantViewModel() -> VisionAssistantViewModel {
        VisionAssistantViewModel(
            speechRecognizer: speechRecognizer,
            cameraController: cameraController,
            speechService: speechService,
            networkManager: networkManager
        )
    }
}

// Environment configuration
enum AppEnvironment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "http://localhost:5001"
        case .staging:
            return "https://staging-api.example.com"
        case .production:
            return "https://api.example.com"
        }
    }
    
    var lmntAPIKey: String {
        switch self {
        case .development:
            return ProcessInfo.processInfo.environment["LMNT_API_KEY_DEV"] ?? ""
        case .staging:
            return ProcessInfo.processInfo.environment["LMNT_API_KEY_STAGING"] ?? ""
        case .production:
            return ProcessInfo.processInfo.environment["LMNT_API_KEY_PROD"] ?? ""
        }
    }
} 