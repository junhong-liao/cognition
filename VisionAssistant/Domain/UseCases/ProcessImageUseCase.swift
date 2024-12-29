protocol ProcessImageUseCase {
    func execute(image: UIImage, question: String) async throws -> String
}

class ProcessImageUseCaseImpl: ProcessImageUseCase {
    private let repository: VisionRepository
    
    init(repository: VisionRepository) {
        self.repository = repository
    }
    
    func execute(image: UIImage, question: String) async throws -> String {
        let response = try await repository.processImage(image, question: question)
        if let error = response.error {
            throw VisionError.unknown(error)
        }
        return response.result
    }
} 