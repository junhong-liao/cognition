struct VisionResponse: Codable {
    let result: String
    let error: String?
}

enum VisionError: Error {
    case networkError
    case invalidData
    case unauthorized
    case unknown(String)
} 