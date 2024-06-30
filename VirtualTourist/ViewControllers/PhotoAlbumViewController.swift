//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Madhu Babu Adiki on 6/26/24.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    var pin: Pin!
    var photos: [Photo] = []
    var dataController: DataController!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        fetchPhotos()
        
        self.title = pin.name
    }
    
//    func createLayout() -> UICollectionViewLayout {
//        let layout = UICollectionViewFlowLayout()
//        let padding: CGFloat = 10
//        let itemSize = (view.frame.width - padding * 4) / 3
//        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
//        layout.minimumLineSpacing = padding
//        layout.minimumInteritemSpacing = padding
//        
//        return layout
//    }
    
    func fetchPhotos() {
        if let photosArray = pin.photos?.allObjects as? [Photo] {
            photos = photosArray
            collectionView.reloadData()
        }
    }
    
    func clearExistingPhotos() {
        if let photosArray = pin.photos?.allObjects as? [Photo] {
            for photo in photosArray {
                dataController.viewContext.delete(photo)
            }
            do {
                try dataController.viewContext.save()
            } catch {
                print("Failed to delete existing photos: \(error.localizedDescription)")
            }
        }
        photos.removeAll()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func fetchImages() {
        clearExistingPhotos()
        
        FlickrAPI.fetchImages(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)) { photoURLs, error in
            
            guard let photoURLs = photoURLs, error == nil else {
                print("Failed to fetch photo URLs: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let context = self.dataController.viewContext
            context.perform {
                let group = DispatchGroup()
                
                for urlString in photoURLs {
                    guard let url = URL(string: urlString) else {continue}
                    
                    let photo = Photo(context: context)
                    photo.pin = self.pin
                    photo.image = UIImage(named: "PosterPlaceholder")?.jpegData(compressionQuality: 1.0)
                    self.photos.append(photo)
                    
                    group.enter()
                    URLSession.shared.dataTask(with: url) {
                        data, response, error in
                        defer { group.leave() }
                        
                        guard let data = data, error == nil else { return }
                        
                        photo.image = data
                    }.resume()
                }
                
                group.notify(queue: .main) {
                    do {
                        try context.save()
                    } catch {
                        print("Failed to save photos: \(error.localizedDescription)")
                    }
                    self.collectionView.reloadData()
                }
            }

        }
    }
    
    @IBAction func reloadPhotos(_ sender: Any) {
        fetchImages()
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        let photo = photos[indexPath.item]
        cell.configure(photo: photo)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Image", message: "Are you sure you want to delete this image?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            
            let photoToDelete = self.photos[indexPath.item]
            self.dataController.viewContext.delete(photoToDelete)
            do  {
                try self.dataController.viewContext.save()
            } catch {
                print("Failed to delete photo: \(error.localizedDescription)")
                return
            }
            self.photos.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10
        let collectionViewSize = collectionView.frame.size.width - padding * 4
        
        let itemSize = collectionViewSize / 1
        return CGSize(width: itemSize, height: itemSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
}

// Custom UICollectionViewCell
class PhotoCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    
    func configure(photo: Photo) {
        imageView.image = UIImage(named: "PosterPlaceholder")
        
        if let imageData = photo.image {
            imageView.image = UIImage(data: imageData)
        }
    }
}
