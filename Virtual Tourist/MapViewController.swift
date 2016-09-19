//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by wealthyjalloh on 24/07/2016.
//  Copyright © 2016 CWJ. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    var selectedPinLocation: Location?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        restoreMapRegion(false)

        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let annotationsToRemove = mapView.annotations.filter { $0 !== mapView.userLocation }
        mapView.removeAnnotations(annotationsToRemove)
        for locationAnyObject in fetchedResultsController.sections![0].objects! {
            let location = locationAnyObject as! Location
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(location.latitude.doubleValue, location.longitude.doubleValue)
            mapView.addAnnotation(annotation)        
        }
    }

    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }

    func saveMapRegion() {

        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]

        // Archive the dict into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }

    func restoreMapRegion(animated: Bool) {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {

            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: animated)
        }
    }

    func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

        let dictionary: [String: AnyObject] = [
            Location.Keys.ID : 0,
            Location.Keys.Latitude : touchMapCoordinate.latitude,
            Location.Keys.Longitude : touchMapCoordinate.longitude
        ]
        let _ = Location(dictionary: dictionary, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()

        let annotation = MKPointAnnotation()
        annotation.coordinate = touchMapCoordinate
        mapView.addAnnotation(annotation)
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        for locationAnyObject in fetchedResultsController.sections![0].objects! {
            let location = locationAnyObject as! Location
            if location.latitude.doubleValue == view.annotation?.coordinate.latitude && location.longitude.doubleValue == view.annotation?.coordinate.longitude  {
                selectedPinLocation = location
                break
            }
        }
        performSegueWithIdentifier("MapToPhotoAlbumSegue", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MapToPhotoAlbumSegue" {
            let photoAlbumViewController = segue.destinationViewController as! PhotoAlbumViewController
            photoAlbumViewController.pinLocation = selectedPinLocation
        }
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Location")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController

    }()
}
