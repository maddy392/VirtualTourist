//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Madhu Babu Adiki on 6/26/24.
//

import Foundation
import MapKit

class FlickrAPI {
    static let API_KEY = "78bfad8a0896119cda8947bffe2fbb46"
    
    static func fetchImages(coordinate: CLLocationCoordinate2D, completionHandler: @escaping ([String]?, Error?) -> Void) {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        let pageNum = Int.random(in: 1...10)
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(latitude)&lon=\(longitude)&per_page=5&format=json&nojsoncallback=1&sort=interestingness-desc&page=\(pageNum)"
        
        guard let url = URL(string: urlString) else {
            completionHandler(nil, nil)
            return
        }
        
        print("Fetching Flickr Images")
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: url) {
                data, response, error in
                guard let data = data, error == nil else {
                    completionHandler(nil, error)
                    return
                }
                
                
                let decoder = JSONDecoder()
                do {
                    let responseObject = try decoder.decode(FlickrResponse.self, from: data)
                    let photos = responseObject.photos
                    var photosURL: [String] = []
                    for item in photos.photo {
                        photosURL.append(item.imageUrl)
                    }
                    DispatchQueue.main.async{
                        completionHandler(photosURL, nil)
                    }
                } catch {
                    print(error)
                    completionHandler(nil, error)
                }
            }
            task.resume()
        }
    }
}
