//
//  ViewController.swift
//  VirtualTourist
//
//  Created by MadhuBabu Adiki on 6/24/24.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    // MARK: Define variables
    @IBOutlet weak var mapView: MKMapView!
    var pins: [Pin] = []
    var dataController: DataController!
    
    // MARK: Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLongPressGesture()
        mapView.delegate = self
//        dataController.wipeAllData()
        fetchPins()
    }
    
    func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gesture:)))
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addPin(coordinate)
        }
    }
    
    fileprivate func fetchPins() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pins = result
            addPinsToMap(pins)
        }
    }
    
    func addPinsToMap (_ pins: [Pin]) {
        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            mapView.addAnnotation(annotation)
        }
    }
    
    func addPin(_ coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        //
        dataController.viewContext.perform {
            let pin = Pin(context: self.dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            
            do {
                try self.dataController.viewContext.save()
                self.pins.append(pin)
                self.fetchImages(for: pin)
            } catch {
                print("Failed to save pin: \(error.localizedDescription)")
            }
        }
    }
    
    
    func fetchImages(for pin: Pin) {
        FlickrAPI.fetchImages(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)) { photoURLs, error in
            guard let photoURLs = photoURLs, error == nil else {
                print("Failed to fetch photo URLs: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let context = self.dataController.viewContext
            context.perform {
                let group = DispatchGroup()
                
                for urlString in photoURLs {
                    guard let url = URL(string: urlString) else {
                        continue
                    }
                    
                    let photo = Photo(context: context)
                    photo.pin = pin
                    photo.image = UIImage(named: "PosterPlaceholder")?.jpegData(compressionQuality: 1.0)
                    
                    group.enter()
                    URLSession.shared.dataTask(with: url) {
                        data, response, error in
                        defer { group.leave() }
                        guard let data = data, error == nil else {return }
                        
                        let photo = Photo(context: context)
                        photo.image = data
                    }.resume()
                }
                
                group.notify(queue: .main) {
                    do {
                        try context.save()
                    } catch {
                        print("Failed to save photos: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: MKMapViewDelegate
extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "showPhotoAlbumView", sender: view.annotation)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoAlbumView", let desinationVC = segue.destination as? PhotoAlbumViewController, let annotation = sender as? MKAnnotation {
            
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "latitude == %lf AND longitude == %lf", annotation.coordinate.latitude, annotation.coordinate.longitude)
            if let pins = try? dataController.viewContext.fetch(fetchRequest), let selectedPin = pins.first {
                desinationVC.pin = selectedPin
                desinationVC.dataController = dataController
            }
        }
    }
}
