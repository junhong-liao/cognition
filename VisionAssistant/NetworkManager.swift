import Foundation
import UIKit

class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://127.0.0.1:5001"  // Your Flask server URL
    
    func uploadPhotoAndQuestion(image: UIImage, question: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let url = URL(string: "\(baseURL)/process-image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // Add image data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        
        // Add question
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"question\"\r\n\r\n")
        body.append(question)
        body.append("\r\n")
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle response and call completion
        }.resume()
    }
} 