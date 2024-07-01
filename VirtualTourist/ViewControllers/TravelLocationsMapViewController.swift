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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
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
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemarks = placemarks?.first, error == nil else {
                print("Reverse geocoding failed: \(error?.localizedDescription ?? "No error info")")
                return
            }
            
            let name = placemarks.name ?? "Unnamed Location"
            annotation.title = name
        
        //
            self.dataController.viewContext.perform {
            let pin = Pin(context: self.dataController.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            pin.name = name
            
            do {
                try self.dataController.viewContext.save()
                self.pins.append(pin)
                self.fetchImageURLs(for: pin)
//                self.fetchImages(for: pin)
            } catch {
                print("Failed to save pin: \(error.localizedDescription)")
            }
        }
    }
}
    
    
    func fetchImageURLs(for pin: Pin) {
        activityIndicator.startAnimating()
        FlickrAPI.fetchImages(coordinate: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)) { photoURLs, error in
            guard let photoURLs = photoURLs, error == nil else {
                print("Failed to fetch photo URLs: \(error?.localizedDescription ?? "Unknown error")")
                self.activityIndicator.stopAnimating()
                return
            }
            
            let context = self.dataController.viewContext
            context.perform {                
                for urlString in photoURLs {
                    let photo = Photo(context: context)
                    photo.pin = pin
                    photo.url = urlString
                    
                }
                
                do {
                    try context.save()
                } catch {
                    print("Failed to save photos: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.mapView.selectAnnotation(self.mapView.annotations.last!, animated: true)
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let identifier = "pin"
        var view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.animatesWhenAdded = true
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
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
