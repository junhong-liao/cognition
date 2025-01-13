import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    @StateObject private var viewModel = VisionAssistantViewModel()
    
    var body: some View {
        VStack {
            // Camera preview
            CameraPreview(cameraController: viewModel.cameraController)
                .frame(height: 300)
            
            // Response text
            Text(viewModel.response)
                .padding()
            
            // Listen button
            Button(action: {
                if viewModel.isListening {
                    viewModel.stopListening()
                } else {
                    viewModel.startListening()
                }
            }) {
                Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                    .font(.system(size: 40))
                    .foregroundColor(viewModel.isListening ? .red : .blue)
            }
            .padding()
        }
    }
} 