//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by wealthyjalloh on 24/07/2016.
//  Copyright © 2016 CWJ. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var bottomButton: UIButton!

    var pinLocation: Location?
    var selectedCellIndices: [NSIndexPath] = []
    var flickrPhotoDownloader: FlickrPhotoDownloader?
    var numberOfPhotosInCollection: Int = 0
    let DEFAULT_NUMBER_OF_PHOTOS_IN_COLLECTION = 15

    override func viewDidLoad() {
        super.viewDidLoad()

        let mapSpan = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        let mapCenter = CLLocationCoordinate2DMake((pinLocation?.latitude.doubleValue)!, (pinLocation?.longitude.doubleValue)!)
        let region = MKCoordinateRegion(center: mapCenter, span: mapSpan)
        mapView.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapCenter
        mapView.addAnnotation(annotation)

        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        collectionViewFlowLayout.minimumInteritemSpacing = space
        collectionViewFlowLayout.minimumLineSpacing = space
        collectionViewFlowLayout.itemSize = CGSizeMake(dimension, dimension)
        collectionView.dataSource = self
        collectionView.delegate = self
        

        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
        if pinLocation?.photos.count == 0 {
            numberOfPhotosInCollection = DEFAULT_NUMBER_OF_PHOTOS_IN_COLLECTION
        } else {
            numberOfPhotosInCollection = (pinLocation?.photos.count)!
        }

        flickrPhotoDownloader = FlickrPhotoDownloader.sharedInstance
    }
    


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if pinLocation!.photos.isEmpty {
            self.flickrPhotoDownloader?.downloadImageURLs(self.pinLocation, numberOfPhotosInCollection: self.numberOfPhotosInCollection, completion: { 
                self.collectionView.reloadData()
            })
        }
        collectionView.reloadData()
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPhotosInCollection
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoAlbumCollectionViewCell", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        
        if self.selectedCellIndices.filter({$0 == indexPath}).count > 0  {
            cell.imageView.alpha = 0.5
        } else {
            cell.imageView.alpha = 1
        }

        if indexPath.row >= pinLocation!.photos.count {
            cell.imageView.image = nil
            cell.textField.hidden = false
            cell.textField.text = "Loading..."
            return cell
        }

        let photo = pinLocation!.photos[indexPath.row]
        if photo.image == nil {
            cell.imageView.image = nil
            cell.textField.hidden = false
            cell.textField.text = "Loading..."
            
            
            flickrPhotoDownloader?.downloadImage(photo.imageURL){ (image) in
                dispatch_async(dispatch_get_main_queue(), {
                    if let downloadedImage = image {
                        if let collectionCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? PhotoAlbumCollectionViewCell {
                            collectionCell.textField.hidden = true
                            collectionCell.imageView.image = downloadedImage
                        }
                        photo.imagePath = UIImageJPEGRepresentation(downloadedImage, 1)
                    } else {
                        cell.textField.text = "Error!"
                    }
                })

            }

        } else {
            cell.textField.hidden = true
            cell.imageView.image = photo.image
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        if self.selectedCellIndices.filter({$0 == indexPath}).count > 0 {
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            self.performDeselect(indexPath)
        } else {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoAlbumCollectionViewCell
            cell.imageView.alpha = 0.5
            selectedCellIndices.append(indexPath)
            bottomButton.setTitle("Remove", forState: UIControlState.Normal)
        }
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.performDeselect(indexPath)
    }
    
    private func performDeselect(indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? PhotoAlbumCollectionViewCell {
            cell.imageView.alpha = 1.0
        }
        self.removeIndexPath(indexPath)
        if selectedCellIndices.count == 0 {
            bottomButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
    }
    
    private func removeIndexPath(indexPath: NSIndexPath) {
        if self.selectedCellIndices.count > 0 {
            for n in 0..<self.selectedCellIndices.count {
                
                if self.selectedCellIndices[n] == indexPath {
                    self.selectedCellIndices.removeAtIndex(n)
                    break
                }
            }
        }
    }

    @IBAction func backToMap(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.pinLocation!)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController

    }()

    @IBAction func bottomButtonPressed(sender: AnyObject) {
        if bottomButton.titleLabel?.text == "Remove" {
            for indexPath in selectedCellIndices {
                let photo = pinLocation!.photos[indexPath.row]
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
            numberOfPhotosInCollection -= (selectedCellIndices.count)
            selectedCellIndices.removeAll(keepCapacity: false)
        } else if bottomButton.titleLabel?.text == "New Collection" {
            for var i = pinLocation!.photos.count-1; i >= 0; i -= 1 {
                let photo = pinLocation!.photos[i]
                sharedContext.deleteObject(photo)
            }
            CoreDataStackManager.sharedInstance().saveContext()
            numberOfPhotosInCollection = DEFAULT_NUMBER_OF_PHOTOS_IN_COLLECTION
            
            
            self.flickrPhotoDownloader?.downloadImageURLs(self.pinLocation, numberOfPhotosInCollection: self.numberOfPhotosInCollection, completion: { 
                self.collectionView.reloadData()
            })
        }

        collectionView.reloadData()
    }
}