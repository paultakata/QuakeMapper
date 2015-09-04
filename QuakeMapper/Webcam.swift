//
//  Webcam.swift
//  QuakeMapper
//
//  Created by Paul Miller on 14/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Webcam)

class Webcam: NSManagedObject, MKAnnotation {
    
    //MARK: - Properties
    
    @NSManaged var webcamID:             String
    @NSManaged var title:                String
    @NSManaged var url:                  String
    @NSManaged var urlMobile:            String
    @NSManaged var latitude:             Double
    @NSManaged var longitude:            Double
    @NSManaged var timelapseAvailable:   Bool
    @NSManaged var timelapseMp4URL:      String?
    @NSManaged var timelapseWebmURL:     String?
    @NSManaged var linkEmbedDayURL:      String
    @NSManaged var timezoneOffset:       Double
    @NSManaged var iconURL:              String
    @NSManaged var thumbnailURL:         String
    @NSManaged var toenailURL:           String
    @NSManaged var previewURL:           String
    
    @NSManaged var previewImageFilePath: String?
    @NSManaged var iconImageFilePath:    String?
    
    var safeCoordinate: CLLocationCoordinate2D? = nil
    
    //MARK: Relationships
    
    @NSManaged var earthquake:           Earthquake
    
    //MARK: Computed properties
    
    var coordinate: CLLocationCoordinate2D {
        
        return safeCoordinate!
    }
    
    var previewImage: UIImage? {
        
        //Return image from documents directory if it exists.
        if let filePath = previewImageFilePath {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
            let pathArray = [dirPath, filePath]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        
        return nil
    }
    
    var iconImage: UIImage? {
        
        //Return image from documents directory if it exists.
        if let filePath = iconImageFilePath {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
            let pathArray = [dirPath, filePath]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        
        return nil
    }
    
    //MARK: - Initialisers
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        safeCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    init(dictionary: [String : AnyObject], quake: Earthquake, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Webcam", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.webcamID  = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.WebcamID]  as! String
        self.title     = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.Title]     as! String
        self.url       = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.URL]       as! String
        self.urlMobile = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.URLMobile] as! String
        self.latitude  = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.Latitude]!.doubleValue
        self.longitude = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.Longitude]!.doubleValue
        
        //Some properties are contained in a nested dictionary, so unwrap it here.
        if let timelapseDictionary = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.Timelapse] as? [String : AnyObject] {
            
            self.timelapseAvailable = timelapseDictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.Available] as! Bool
            
            if self.timelapseAvailable {
                
                self.timelapseMp4URL  = timelapseDictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.FormatMP4]  as? String
                self.timelapseWebmURL = timelapseDictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.FormatWebM] as? String
            }
            
            self.linkEmbedDayURL = timelapseDictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.LinkEmbedDay] as! String
        }
        
        self.timezoneOffset = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.TimezoneOffset]!.doubleValue
        self.iconURL        = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.IconURL]        as! String
        self.thumbnailURL   = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.ThumbnailURL]   as! String
        self.toenailURL     = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.ToenailURL]     as! String
        self.previewURL     = dictionary[QuakeMapperClient.WebcamsTravelJSONResponseKeys.PreviewURL]     as! String
        
        self.earthquake = quake
        safeCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    //MARK: Core Data
    
    override func prepareForDeletion() {
        
        //Delete the webcam preview image when the Webcam is deleted.
        if let fileName = previewImageFilePath {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            NSFileManager.defaultManager().removeItemAtURL(fileURL, error: nil)
        }
        
        //Delete the webcam icon image when the Webcam is deleted.
        if let fileName = iconImageFilePath {
            
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
            let pathArray = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            NSFileManager.defaultManager().removeItemAtURL(fileURL, error: nil)
        }
    }
}
