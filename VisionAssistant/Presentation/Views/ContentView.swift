import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: VisionAssistantViewModel
    
    init(viewModel: VisionAssistantViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            CameraView(isSetup: viewModel.isCameraSetup, isListening: viewModel.isListening)
            
            Text(viewModel.recognizedText)
                .font(.system(size: 18))
                .foregroundColor(viewModel.isListening ? .blue : .gray)
            
            Button(action: {
                Task {
                    await viewModel.startWorkflow()
                }
            }) {
                Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                    .font(.system(size: 40))
                    .foregroundColor(viewModel.isListening ? .red : .blue)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .alert("Camera Not Available", isPresented: $viewModel.showCameraError) {
            Button("OK", role: .cancel) { }
            Button("Open Settings") {
                if let settingsURL = URL(string: "app-settings:") {
                    openURL(settingsURL)
                }
            }
        }
        .alert("Microphone Not Available", isPresented: $viewModel.showMicError) {
            Button("OK", role: .cancel) { }
            Button("Open Settings") {
                if let settingsURL = URL(string: "app-settings:") {
                    openURL(settingsURL)
                }
            }
        }
    }
}

// Extracted subviews for better organization
struct CameraView: View {
    let isSetup: Bool
    let isListening: Bool
    @StateObject private var cameraController = CameraController.shared
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Group {
            if isSetup {
                CameraPreview(cameraController: cameraController)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: isListening ? 2 : 0)
                    )
                    .animation(.easeInOut, value: isListening)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        Text("Camera not available")
                            .foregroundColor(.red)
                    )
            }
        }
    }
}

struct ListenButton: View {
    let isListening: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.system(size: 40))
                    .foregroundColor(isListening ? .red : .blue)
            }
        }
        .padding()
        .scaleEffect(isListening ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isListening)
    }
} 