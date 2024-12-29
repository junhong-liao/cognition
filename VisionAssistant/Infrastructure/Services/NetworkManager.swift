import Foundation
import UIKit

class NetworkManager: NetworkServicing {
    private let session: URLSession
    private let baseURL: String
    
    init(baseURL: String = "http://127.0.0.1:5001",
         configuration: URLSessionConfiguration = .default) {
        self.baseURL = baseURL
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
    }
    
    func uploadPhotoAndQuestion(image: UIImage, question: String) async throws -> VisionResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AppError.vision(.invalidImage)
        }
        
        let url = URL(string: "\(baseURL)/process-image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form data
        var body = Data()
        body.append(multipartFormData(boundary: boundary, name: "file", fileName: "photo.jpg", mimeType: "image/jpeg", data: imageData))
        body.append(multipartFormData(boundary: boundary, name: "question", value: question))
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                return try JSONDecoder().decode(VisionResponse.self, from: data)
            case 401, 403:
                throw NetworkError.serverError("Unauthorized")
            case 500...599:
                throw NetworkError.serverError("Server error")
            default:
                throw NetworkError.serverError("Unknown error")
            }
            
        } catch is URLError {
            throw NetworkError.noConnection
        } catch {
            throw error
        }
    }
    
    private func multipartFormData(boundary: String, name: String, fileName: String? = nil, mimeType: String? = nil, value: String? = nil, data: Data? = nil) -> Data {
        var fieldData = Data()
        fieldData.append("--\(boundary)\r\n")
        
        if let fileName = fileName, let mimeType = mimeType {
            fieldData.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
            fieldData.append("Content-Type: \(mimeType)\r\n\r\n")
            if let data = data {
                fieldData.append(data)
            }
        } else {
            fieldData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            if let value = value {
                fieldData.append(value)
            }
        }
        
        fieldData.append("\r\n")
        return fieldData
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 