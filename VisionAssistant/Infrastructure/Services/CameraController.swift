import AVFoundation
import UIKit

class CameraController: ObservableObject {
    static let shared = CameraController() // Singleton for preview sharing
    
    @Published var isSetup = false
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    private var completionHandler: ((UIImage?) -> Void)?
    
    init() {
        setupCamera()
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        let output = AVCapturePhotoOutput()
        
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
            self.captureSession = session
            self.photoOutput = output
            
            // Create and configure preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            self.previewLayer = previewLayer
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
                DispatchQueue.main.async {
                    self?.isSetup = true
                }
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }
        
        self.completionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}

extension Came