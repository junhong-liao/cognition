import Foundation

enum AppError: LocalizedError {
    case speech(SpeechError)
    case camera(CameraError)
    case network(NetworkError)
    case vision(VisionError)
    
    var errorDescription: String? {
        switch self {
        case .speech(let error): return error.localizedDescription
        case .camera(let error): return error.localizedDescription
        case .network(let error): return error.localizedDescription
        case .vision(let error): return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .speech(.unauthorized):
            return "Please enable microphone access in Settings"
        case .camera(.unauthorized):
            return "Please enable camera access in Settings"
        case .network(.noConnection):
            return "Please check your internet connection"
        default:
            return "Please try again"
        }
    }
}

enum NetworkError: Error {
    case noConnection
    case invalidResponse
    case serverError(String)
    case timeout
}

enum CameraError: Error {
    case unauthorized
    case unavailable
    case captureError
}

enum SpeechError: Error {
    case unauthorized
    case recognitionFailed
    case noAudio
} 