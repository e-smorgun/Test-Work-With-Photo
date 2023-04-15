//
//  PhotoModel.swift
//  TestWithPhoto
//
//  Created by Evgeny on 14.04.23.
//

import Foundation

struct PhotoType: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let image: URL?
    
    static func ==(lhs: PhotoType, rhs: PhotoType) -> Bool {
        return lhs.id == rhs.id
    }
}
