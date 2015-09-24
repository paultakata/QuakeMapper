//
//  Earthquake.swift
//  QuakeMapper
//
//  Created by Paul Miller on 14/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Earthquake)

class Earthquake: NSManagedObject, MKAnnotation {
    
    //MARK: - Properties
    
    @NSManaged var receivedTitle:             String
    @NSManaged var magnitude:                 Double
    @NSManaged var placeText:                 String
    @NSManaged var time:                      NSDate
    @NSManaged var timezone:                  Int
    @NSManaged var url:                       String
    @NSManaged var latitude:                  Double
    @NSManaged var longitude:                 Double
    @NSManaged var id:                        String
    @NSManaged var tweetsAvailable:           Bool
    @NSManaged var mapThumbnailImageFilePath: String?
    
    var safeCoordinate: CLLocationCoordinate2D? = nil
    
    //MARK: Relationships
    
    @NSManaged var tweets:                    NSMutableOrderedSet
    @NSManaged var webcams:                   NSMutableOrderedSet
    
    //MARK: Computed properties
    
    var coordinate: CLLocationCoordinate2D {
        
        return safeCoordinate!
    }
    
    var title: String? {
        
        //Create date formatter with suitable properties.
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.doesRelativeDateFormatting = true
        
        let timeString = dateFormatter.stringFromDate(time)
        
        //Return title string consisting of quake magnitude and date.
        return "Magnitude \(magnitude)\n\(timeString)"
    }
    
    var subtitle: String? {
        
        return placeText
    }
    
    var mapThumbnailImage: UIImage? {
        
        //If the filePath exists, return the image.
        if let filePath = mapThumbnailImageFilePath {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
            let pathArray = [dirPath, filePath]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(named: fileURL.path!)
        }
        
        return nil
    }
    
    var placeTitle: String {
        
        //Try to create substring containing just the place name...
        if let range = placeText.rangeOfString("of ") {
            
            let text = placeText.substringFromIndex(range.endIndex)
            
            return text
        }
        
        //...else return the whole string.
        return placeText
    }
    
    //MARK: - Initialisers
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        safeCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Earthquake", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        //Get first nested dictionary and retrieve properties from it.
        if let propertiesDictionary = dictionary[QuakeMapperClient.USGSJSONResponseKeys.Properties] as? [String : AnyObject] {
            
            self.receivedTitle = propertiesDictionary[QuakeMapperClient.USGSJSONResponseKeys.Title]     as! String
            self.magnitude     = propertiesDictionary[QuakeMapperClient.USGSJSONResponseKeys.Magnitude] as! Double
            self.placeText     = propertiesDictionary[QuakeMapperClient.USGSJSONResponseKeys.PlaceText] as! String
            
            //Create NSDate object from received time in "milliseconds from the epoch".
            let timeInMilliseconds = propertiesDictionary[QuakeMapperClient.USGSJSONResponseKeys.Time] as! Double
            let timeInSeconds = timeInMilliseconds / 1000.0
            self.time = NSDate(timeIntervalSince1970: timeInSeconds)
            
            //Determine which quakes we can possibly retrieve tweets about.
            let timeNow = NSDate()
            self.tweetsAvailable = timeNow.timeIntervalSinceDate(self.time) > 604800 ? false : true //604800 seconds == 1 week, the availability of Twitter's search function.
            
            self.timezone = propertiesDictionary[QuakeMapperClient.USGSJSONResponseKeys.Timezone] as! Int
            self.url      = propertiesDictionary[QuakeMapperClient.USGSJSONResponseKeys.URL]      as! String
        }
        
        //Get second nested dictionary and retrieve properties from it.
        if let geometryDictionary = dictionary[QuakeMapperClient.USGSJSONResponseKeys.Geometry] as? [String : AnyObject] {
            
            let coordinatesArray = geometryDictionary[QuakeMapperClient.USGSJSONResponseKeys.Coordinates] as! [Double]
            
            self.longitude = coordinatesArray[0]
            self.latitude = coordinatesArray[1]
        }
        
        self.id = dictionary[QuakeMapperClient.USGSJSONResponseKeys.ID] as! String
        safeCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    //MARK: - Core Data
    
    override func prepareForDeletion() {
        
        //Delete the map thumbnail image when the earthquake is deleted.
        if let fileName = mapThumbnailImageFilePath {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch _ {
            }
        }
    }
}
