struct VisionResponse: Codable {
    let result: String
    let error: String?
    
    init(result: String, error: String? = nil) {
        self.result = result
        self.error = error
    }
} 