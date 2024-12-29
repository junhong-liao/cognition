import XCTest
@testable import VisionAssistant

class VisionAssistantViewModelTests: XCTestCase {
    var viewModel: VisionAssistantViewModel!
    var mockSpeechRecognizer: MockSpeechRecognizer!
    var mockCameraController: MockCameraController!
    var mockSpeechService: MockSpeechService!
    var mockNetworkManager: MockNetworkManager!
    
    override func setUp() {
        super.setUp()
        mockSpeechRecognizer = MockSpeechRecognizer()
        mockCameraController = MockCameraController()
        mockSpeechService = MockSpeechService()
        mockNetworkManager = MockNetworkManager()
        
        viewModel = VisionAssistantViewModel(
            speechRecognizer: mockSpeechRecognizer,
            cameraController: mockCameraController,
            speechService: mockSpeechService,
            networkManager: mockNetworkManager
        )
    }
    
    func testStartListening() async {
        // Given
        let expectedQuestion = "What's in the image?"
        mockSpeechRecognizer.mockResult = .success(expectedQuestion)
        mockCameraController.mockImage = UIImage()
        mockNetworkManager.mockResponse = VisionResponse(result: "A cat")
        
        // When
        await viewModel.toggleListening()
        
        // Then
        XCTAssertTrue(mockSpeechRecognizer.didCallStartRecording)
        XCTAssertTrue(mockCameraController.didCallCapturePhoto)
        XCTAssertTrue(mockNetworkManager.didCallUpload)
        XCTAssertTrue(mockSpeechService.didCallSpeak)
        XCTAssertEqual(viewModel.recognizedText, expectedQuestion)
    }
    
    func testErrorHandling() async {
        // Given
        mockSpeechRecognizer.mockResult = .failure(VisionError.unauthorized)
        
        // When
        await viewModel.toggleListening()
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isListening)
    }
    
    func testCameraError() {
        // Given
        mockCameraController.isSetup = false
        
        // When
        viewModel.onAppear()
        
        // Then
        XCTAssertTrue(viewModel.showCameraError)
    }
} 