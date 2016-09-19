//
//  Photo.swift
//  Virtual Tourist
//
//  Created by wealthyjalloh on 24/07/2016.
//  Copyright © 2016 CWJ. All rights reserved.
//

import CoreData
import UIKit

class Photo : NSManagedObject {

    struct Keys {
        static let ID = "id"
        static let ImagePath = "image_path"
        static let ImageUrl = "image_url"
    }

    @NSManaged var id: NSNumber
    @NSManaged var imagePath: NSData?
    @NSManaged var imageURL: String?
 
    
    @NSManaged var location: Location?

    var image: UIImage?{
        get {
            if let imageData = self.imagePath {
                return UIImage(data: imageData)
            } else {
                return nil
            }
        }
    }

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        // Dictionary
        id = dictionary[Keys.ID] as! Int
        imagePath = dictionary[Keys.ImagePath] as? NSData
        imageURL = dictionary[Keys.ImageUrl] as? String
        
    }

}