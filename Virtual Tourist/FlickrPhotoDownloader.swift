//
//  FlickrPhotoDownloader.swift
//  Virtual Tourist
//
//  Created by wealthyjalloh on 24/07/2016.
//  Copyright © 2016 CWJ. All rights reserved.
// Completed

import Foundation
import UIKit

class FlickrPhotoDownloader {
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "edf6f5ce58807bddda891bb3390e07e4"
    let EXTRAS = "url_m"
    let SAFE_SEARCH = "1"
    let DATA_FORMAT = "json"
    let NO_JSON_CALLBACK = "1"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0
    
    static let sharedInstance = FlickrPhotoDownloader()
    
    private init() {
        
    }

    func getImageURLsFromFlickrByByLatLong(latitude: Double, longitude: Double, completion: (([NSURL]) -> Void)?) {
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]

        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) { (data, response, error) in

            //GUARD: Was there an error?
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }

            //GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }

            //GUARD: Was there any data returned?
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }

            //Parse the data!
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }

            //GUARD: Did Flickr return an error?
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }

            // GUARD: Is "photos" key in our result?
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }

            //GUARD: Is "pages" key in the photosDictionary?
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }

            //Pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageURLsFromFlickrWithPage(methodArguments, pageNumber: randomPage, completion: completion)
        }
        task.resume()
    }

    func getImageURLsFromFlickrWithPage(methodArguments: [String : AnyObject], pageNumber: Int, completion:  (([NSURL]) -> Void)?) {
       
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber

        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) { (data, response, error) in

            //GUARD: Was there an error?
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }

            //GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }

            //GUARD: Was there any data returned?
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }

            //Parse the data!
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }

            //GUARD: Did Flickr return an error (stat != ok)?
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }

            //GUARD: Is the "photos" key in our result?
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find key 'photos' in \(parsedResult)")
                return
            }

            //GUARD: Is the "photo" key in photosDictionary?
            guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                print("Cannot find key 'photo' in \(photosDictionary)")
                return
            }

            var imageURLs = [NSURL]()
            for photoDictionary in photosArray {
                if let imageUrlString = photoDictionary["url_m"] as? String {
                    imageURLs.append(NSURL(string: imageUrlString)!)
                }
            }

            if let completion = completion {
                completion(imageURLs)
            }
        }
        
        task.resume()
    }

    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }

    func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {
            // make sure that its string value
            let stringValue = "\(value)"
            // escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            // append it
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    func downloadImageURLs(pinLocation: Location?, numberOfPhotosInCollection: Int, completion:()->Void) {
        
        self.getImageURLsFromFlickrByByLatLong((pinLocation?.latitude.doubleValue)!, longitude: (pinLocation?.longitude.doubleValue)!) {(imageURLs) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), {
                var i = 0
                for imageURL in imageURLs {
                    let dictionary: [String: AnyObject] = [
                        Photo.Keys.ID: 0,
                        Photo.Keys.ImageUrl: "\(imageURL)"
                    ]
                    let photo = Photo(dictionary: dictionary, context: CoreDataStackManager.sharedInstance().managedObjectContext)
                    photo.location = pinLocation!
                    i += 1
                    if i >= numberOfPhotosInCollection {
                        break
                    }
                }
                CoreDataStackManager.sharedInstance().saveContext()
                completion()
            })
        }
        
    }
    
    func downloadImage(imageURL: String?, completion: (UIImage?)->Void) {
        let session = NSURLSession.sharedSession()
        if let url = imageURL {
            let imageURL = NSURL(string: url)
            
            let request = NSURLRequest(URL: imageURL!)
            
            
            let task = session.dataTaskWithRequest(request) {data, response, downloadError in
                
                if let imageData = data, image = UIImage(data: imageData) {
                    completion(image)
                } else {
                    completion(nil)
                }
            }
            task.resume()
        } else {
            completion(nil)
        }
        
    }
}