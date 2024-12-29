import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraController: CameraController
    
    init(cameraController: CameraController = .shared) {
        self.cameraController = cameraController
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        
        // Setup preview layer
        if let previewLayer = cameraController.previewLayer {
            view.setupPreviewLayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update preview layer if needed
        if let previewLayer = cameraController.previewLayer {
            uiView.setupPreviewLayer(previewLayer)
        }
    }
}

class PreviewView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    func setupPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        // Remove existing layer if any
        previewLayer?.removeFromSuperlayer()
        
        // Add new layer
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        self.previewLayer = layer
    }
} 