//
//  PhotoListViewModel.swift
//  TestWithPhoto
//
//  Created by Evgeny on 14.04.23.
//

import Foundation
import Combine
import UIKit

// MARK: -- Response Model
struct PhotoTypeResponse: Codable {
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalElements: Int
    let content: [PhotoType]
}

enum SelectedPhotoType {
    case allPhoto
    case withPhoto
    case withoutPhoto
}

// MARK: -- View Model
class PhotoListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var photoTypes = [PhotoType]()
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoType: SelectedPhotoType = .allPhoto
    
    // MARK: - Properties
    var totalPages = 6
    var currentPage = -1
    private let photoService = PhotoService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Methods
    // Function for uploading photo to server
    func uploadPhoto(photoType: PhotoType, imageData: Data, developerName: String = "Evgeny Smorgun", completion: @escaping (String?, Error?) -> Void) {
        photoService.sendPhotoToServer(photoType: photoType, imageData: imageData, developerName: developerName) { result in
            switch result {
            case .success(let id):
                completion(id, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    // Function for fetching photo types
    func fetchPhotoTypes() {
        currentPage += 1
        fetchPhotoTypes(page: currentPage)
    }
    
    func changePhotoType() {
        currentPage = -1
        photoTypes.removeAll()
        fetchPhotoTypes()
    }
    
    private func fetchPhotoTypes(page: Int) {
        guard page < totalPages else { return }
        let url = URL(string: "https://junior.balinasoft.com/api/v2/photo/type?page=\(page)")!
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: PhotoTypeResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.currentPage = response.page
                self.totalPages = response.totalPages
                switch selectedPhotoType {
                case .withoutPhoto:
                    for item in response.content {
                        if item.image == nil {
                            self.photoTypes.append(item)
                        }
                    }
                case .withPhoto:
                    for item in response.content {
                        if item.image != nil {
                            self.photoTypes.append(item)
                        }
                    }
                case .allPhoto:
                    self.photoTypes.append(contentsOf: response.content)
                }
            })
            .store(in: &cancellables)
    }
}
