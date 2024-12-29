import XCTest
@testable import VisionAssistant

class NetworkTests: XCTestCase {
    var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        // Use a mock server URL for testing
        networkManager = NetworkManager(baseURL: "http://localhost:5001")
    }
    
    func testPhotoUpload() async throws {
        // Given
        let image = UIImage()
        let question = "What's in the image?"
        
        // When
        do {
            let response = try await networkManager.uploadPhotoAndQuestion(image: image, question: question)
            
            // Then
            XCTAssertNotNil(response.result)
        } catch {
            XCTFail("Network request failed: \(error)")
        }
    }
    
    func testInvalidImageData() async {
        // Given
        let invalidImage = UIImage()  // Empty image
        let question = "What's in the image?"
        
        // Then
        do {
            _ = try await networkManager.uploadPhotoAndQuestion(image: invalidImage, question: question)
            XCTFail("Should throw an error for invalid image")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
} 