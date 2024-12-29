class VisionRepositoryImpl: VisionRepository {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func processImage(_ image: UIImage, question: String) async throws -> VisionResponse {
        return try await networkManager.uploadPhotoAndQuestion(image: image, question: question)
    }
} 