//
//  PhotoService.swift
//  TestWithPhoto
//
//  Created by Evgeny on 15.04.23.
//

import Foundation

// MARK: -- Error's
enum PhotoError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case noResponseData
    case invalidResponseFormat
    case jsonParsingError(Error)
}

// MARK: -- PhotoService
class PhotoService {
    func sendPhotoToServer(photoType: PhotoType, imageData: Data, developerName: String = "Evgeny Smorgun", completion: @escaping (Result<String, Error>) -> Void) {
        // Set up the URL for the API endpoint
        guard let url = URL(string: "https://junior.balinasoft.com/api/v2/photo") else {
            completion(.failure(PhotoError.invalidURL))
            return
        }
        
        // Set up the request object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set up the request headers
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        
        // Set up the request body as a multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(developerName)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpeg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"typeId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(photoType.id)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the request body
        request.httpBody = body
        
        // Send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(PhotoError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(PhotoError.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(PhotoError.noResponseData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let id = json?["id"] as? String {
                    completion(.success(id))
                } else {
                    completion(.failure(PhotoError.invalidResponseFormat))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
