import SwiftUI

/// Repository protocol for handling vision-related operations
protocol VisionRepository {
    /// Process an image with a question and return a response
    /// - Parameters:
    ///   - image: The SwiftUI image to analyze
    ///   - question: The question about the image
    /// - Returns: A VisionResponse containing the analysis result
    /// - Throws: VisionError if processing fails
    func processImage(_ image: Image, question: String) async throws -> VisionResponse
    
    /// Cancel any ongoing processing
    func cancelProcessing()
    
    /// Check if the service is available
    var isAvailable: Bool { get }
}

/// Errors that can occur during vision processing
enum VisionError: Error, LocalizedError {
    case networkError
    case processingError(String)
    case invalidImage
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error"
        case .processingError(let message):
            return "Processing error: \(message)"
        case .invalidImage:
            return "Invalid or corrupted image"
        case .serviceUnavailable:
            return "Vision service is currently unavailable"
        }
    }
} 