import Foundation

/// Errors that can occur during vision processing
enum VisionError: LocalizedError {
    case cameraError(String)
    case networkError(String)
    case unauthorized
    case serverError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .cameraError(let message): return "Camera error: \(message)"
        case .networkError(let message): return "Network error: \(message)"
        case .unauthorized: return "Unauthorized access"
        case .serverError(let message): return "Server error: \(message)"
        case .unknown(let message): return "Unknown error: \(message)"
        }
    }
} 