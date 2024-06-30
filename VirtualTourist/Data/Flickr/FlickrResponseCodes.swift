//
//  FlickrResponseCodes.swift
//  VirtualTourist
//
//  Created by Madhu Babu Adiki on 6/27/24.
//

import Foundation

struct PhotoCodable: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
    }
    
    var imageUrl: String {
//        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_m.jpg"
        return "https://live.staticflickr.com/\(server)/\(id)_\(secret)_s.jpg"
    }
}


struct Photos : Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: Int
    let photo: [PhotoCodable]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photo
        
    }
}


struct FlickrResponse: Codable {
    let photos: Photos
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case photos
        case stat
    }
}
