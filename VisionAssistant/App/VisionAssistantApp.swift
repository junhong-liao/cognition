@main
struct VisionAssistantApp: App {
    private let container: DependencyContainer
    
    init() {
        // Configure environment based on build configuration
        #if DEBUG
        container = DependencyContainer(environment: .development)
        #else
        container = DependencyContainer(environment: .production)
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: container.makeVisionAssistantViewModel())
        }
    }
} 