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
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        fetchPhotos()
        self.title = pin.name
    }
    
    func fetchPhotos() {
//        print("Fetching photos from database for pin : \(pin.name ?? "no name")")
        if let photosArray = pin.photos?.allObjects as? [Photo] {
            photos = photosArray
        } else {
            print("No photos available")
            createPlaceholderPhoto()
        }
        collectionView.reloadData()
    }
    
    func createPlaceholderPhoto() {
        let placeholderPhoto = Photo(context: dataController.viewContext)
        placeholderPhoto.pin = pin
        placeholderPhoto.url = nil
        placeholderPhoto.image = UIImage(named: "PosterPlaceholder")?.jpegData(compressionQuality: 1.0)
        photos.append(placeholderPhoto)
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
    
    func fetchPhotoURLs() {
        clearExistingPhotos()
        activityIndicator.startAnimating()
        
        FlickrAPI.fetchImages(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)) { photoURLs, error in
            
            guard let photoURLs = photoURLs, error == nil else {
                print("Failed to fetch photo URLs: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                return
            }
            
            let context = self.dataController.viewContext
            context.perform {
                for urlString in photoURLs {
                    let photo = Photo(context: context)
                    photo.pin = self.pin
                    photo.url = urlString
                    self.photos.append(photo)
                }
                
                do {
                    try context.save()
                } catch {
                    print("Failed to save photos: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    @IBAction func reloadPhotos(_ sender: Any) {
        fetchPhotoURLs()
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        cell.configureWithPlaceholder()
        let photo = photos[indexPath.item]
        
        if let imageData = photo.image {
//            print("Loading already existing data")
            cell.configureWithImageData(imageData)
        } else if let urlString = photo.url, let url = URL(string: urlString) {
//            print("Loading data for image: \(urlString)")
                URLSession.shared.dataTask(with: url) {
                    data, response, error in
                    guard let data = data, error == nil else {
                        print("Failed to download image: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        cell.configureWithImageData(data)
                    }
                    
                    self.dataController.viewContext.perform {
                        photo.image = data
                        do {
                            try self.dataController.viewContext.save()
                        } catch {
                            print("Failed to save image data: \(error.localizedDescription)")
                        }
                    }
                }.resume()
            }
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
        let collectionViewSize = collectionView.frame.size.width - padding * 2
        
        let itemSize = collectionViewSize / 3.0
        return CGSize(width: itemSize, height: itemSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
          if collectionView.numberOfItems(inSection: section) == 1 {
               let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
              return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: collectionView.frame.width - flowLayout.itemSize.width)
          }
          return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
      }
}

// Custom UICollectionViewCell
class PhotoCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    
    func configureWithPlaceholder() {
        imageView.image = UIImage(named: "PosterPlaceholder")
    }
    
    func configureWithImageData(_ data: Data) {
        imageView.image = UIImage(data: data)
    }
}
