import Foundation

/// Errors that can occur during vision processing
enum VisionError: Error {
    case networkError
    case invalidData
    case unauthorized
    case processingError(String)
    case invalidImage
    case serviceUnavailable
    case unknown(String)
    
    var localizedDescription: String {
        switch self {
        case .networkError:
            return "Network connection error"
        case .invalidData:
            return "Invalid data received"
        case .unauthorized:
            return "Unauthorized access"
        case .processingError(let message):
            return "Processing error: \(message)"
        case .invalidImage:
            return "Invalid or corrupted image"
        case .serviceUnavailable:
            return "Vision service is currently unavailable"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
} 