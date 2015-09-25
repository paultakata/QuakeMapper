//
//  QuakeMapperConvenience.swift
//  QuakeMapper
//
//  Created by Paul Miller on 17/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import TwitterKit

extension QuakeMapperClient {
    
    //MARK: - Convenience methods
    
    func getUSGSQuakeData(completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        //USGS feed has no parameters or methods, so create plain request.
        GETMethodWithWebsite(Website.USGSEarthquake,
            method: "",
            parameters: [String : AnyObject]()) {
            JSONResult, error in
            
            //If we get an error, pass it to the completion handler.
            if let error = error {
                
                completionHandler(success: false, error: error)
                
                //If not, try to retrieve data and create Earthquake objects with it.
            } else if let resultsDictionary = JSONResult as? [String : AnyObject],
                quakesArray = resultsDictionary[USGSJSONResponseKeys.Features] as? [[String : AnyObject]] {
                    
                    self.findOrCreateNewQuakeFromArray(quakesArray)
                    
                    completionHandler(success: true, error: nil)
            } else {
                
                completionHandler(success: false, error: NSError(domain: "getUSGSQuakeData", code: 1, userInfo: nil))
            }
        }
    }
    
    func getMapSnapshotForQuake(quake: Earthquake,
        withCompletion completion: (success: Bool, error: NSError?) -> Void) {
        
        //Create snapshotter with suitable options.
        let snapshotOptions = MKMapSnapshotOptions()
        snapshotOptions.size = CGSizeMake(116, 116) // To match up with the imageView in the earthquake table view cells.
        snapshotOptions.region = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(quake.latitude, quake.longitude), 100000, 100000)
        snapshotOptions.mapType = .Hybrid
        
        let snapshotter = MKMapSnapshotter(options: snapshotOptions)
        
        //Start snapshotter...
        snapshotter.startWithCompletionHandler {
            snapshot, error in
            
            if let error = error {
                
                //...if there's an error, pass it to the completion handler...
                completion(success: false, error: error)
            } else {
                
                //...otherwise create a png image and fileURL...
                let fileName = quake.id + ".png"
                let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
                let pathArray = [dirPath, fileName]
                let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                
                let imageData = UIImagePNGRepresentation(snapshot!.image)
                
                //...save it, update the earthquake and call the completion handler.
                NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: imageData, attributes: nil)
                
                quake.mapThumbnailImageFilePath = fileURL.lastPathComponent!
                
                completion(success: true, error: nil)
            }
        }
    }
    
    func searchTwitterForLocation(location: CLLocationCoordinate2D,
        since: String,
        until: String,
        completionHandler: (success: Bool, errorString: String?, results: [AnyObject]?) -> Void) {
        
        //Declare method and parameters
        let method = Methods.Search
        let parameters: [String : AnyObject] = [
            TwitterURLKeys.Query   : "",
            TwitterURLKeys.Geocode : "\(location.latitude),\(location.longitude),50km",
            TwitterURLKeys.Since   : since,
            TwitterURLKeys.Until   : until,
            TwitterURLKeys.Count   : 100
        ]
        
        //Create request.
        GETMethodWithWebsite(Website.Twitter, method: method, parameters: parameters) {
            jsonResult, error in
            
            if let error = error {
                
                completionHandler(success: false, errorString: error.localizedDescription, results: nil)
            } else {
                
                //If we get a result, pass it to the completion handler.
                if let tweets = jsonResult.valueForKey(TwitterJSONResponseKeys.Statuses) as? [AnyObject] {
                    
                    completionHandler(success: true, errorString: nil, results: tweets)
                }
            }
        }

            /*
            let client = TWTRAPIClient()
            let endpoint = QuakeMapperClient.Constants.BaseTwitterURL + QuakeMapperClient.Methods.Search
            let parameters: [String : AnyObject] = [
                TwitterURLKeys.Query   : "",
                TwitterURLKeys.Geocode : "\(location.latitude),\(location.longitude),50km",
                TwitterURLKeys.Since   : since,
                TwitterURLKeys.Until   : until,
                TwitterURLKeys.Count   : 100
            ]
            let clientError: NSErrorPointer = nil
            
            let request = Twitter.sharedInstance().APIClient.URLRequestWithMethod("GET", URL: endpoint, parameters: parameters, error: clientError)
            
            client.sendTwitterRequest(request, completion: {
                response, data, connectionError in
                
                if connectionError == nil {
                    
                    var jsonError: NSError?
                    let parsedResult: AnyObject?
                    
                    do {
                        parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                        
                    } catch let error as NSError {
                        
                        jsonError = error
                        parsedResult = nil
                        
                        completionHandler(success: false, errorString: jsonError?.localizedDescription, results: nil)
                    }
                    
                    if let tweets = parsedResult?.valueForKey(TwitterJSONResponseKeys.Statuses) as? [AnyObject] {
                        completionHandler(success: true, errorString: nil, results: tweets)
                    }
                }
                
            })
            */
    }
    
    func getWebcamsForEarthquake(earthquake: Earthquake, withCompletion completion: (success: Bool, error: NSError?) -> Void) {
        
        //Declare parameters.
        let parameters: [String : AnyObject] = [
            WebcamsTravelURLKeys.Method      : WebcamsTravelURLValues.ListNearby,
            WebcamsTravelURLKeys.Format      : WebcamsTravelURLValues.JSON,
            WebcamsTravelURLKeys.DeveloperID : Constants.WebcamsTravelDevID,
            WebcamsTravelURLKeys.Latitude    : earthquake.latitude,
            WebcamsTravelURLKeys.Longitude   : earthquake.longitude,
            WebcamsTravelURLKeys.Radius      : 80,
            WebcamsTravelURLKeys.Unit        : "km",
            WebcamsTravelURLKeys.PerPage     : 48,
            WebcamsTravelURLKeys.Page        : 1
        ]
        
        //Create request.
        GETMethodWithWebsite(Website.WebcamsTravel, method: "", parameters: parameters) {
            jsonResult, error in
            
            if let error = error {
                
                completion(success: false, error: error)
            } else {
                
                //If we get a result, extract the webcam data, create Webcam objects and call the completion handler.
                if let resultsDictionary = jsonResult as? [String : AnyObject],
                       webcamsDictionary = resultsDictionary[WebcamsTravelJSONResponseKeys.Webcams] as? [String : AnyObject],
                            webcamsArray = webcamsDictionary[WebcamsTravelJSONResponseKeys.Webcam] as? [[String : AnyObject]] {
                    
                                for webcam in webcamsArray {
                                    
                                    dispatch_async(dispatch_get_main_queue(), {
                                        
                                        Webcam(dictionary: webcam, quake: earthquake, context: self.sharedContext)
                                    })
                                }
                                
                                completion(success: true, error: nil)
                }
            }
        }
    }
    
    func getPreviewImageForWebcam(webcam: Webcam,
        withCompletion completion: (success: Bool, error: NSError?) -> Void) {
            
        //Get URL for preview image.
        let imageURLString = webcam.previewURL
        
        //Make the request.
        GETMethodForURLString(imageURLString, completionHandler: {
            result, error in
            
            if let error = error {
                
                completion(success: false, error: error)
            } else {
                
                //If we get a result, save it to the documents directory...
                if let result = result {
                    
                    let fileName = NSURL.fileURLWithPath(imageURLString).lastPathComponent!
                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
                    let pathArray = [dirPath, fileName]
                    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                    
                    NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: result, attributes: nil)
                    
                    //...and update the filePath.
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        webcam.previewImageFilePath = fileName
                        
                        completion(success: true, error: nil)
                    })
                }
            }
        })
    }
    
    func getIconImageForWebcam(webcam: Webcam,
        withCompletion completion: (success: Bool, error: NSError?) -> Void) {
        
        //Get URL for thumbnail image.
        let iconURLString = webcam.iconURL
        
        //Make the request.
        GETMethodForURLString(iconURLString, completionHandler: {
            result, error in
            
            if let error = error {
                
                completion(success: false, error: error)
            } else {
                
                //If we get a result, save it to the documents directory...
                if let result = result {
                    
                    var fileName = "icon" + NSURL.fileURLWithPath(iconURLString).lastPathComponent!
                    
                    //The following adds "@2x" to the file name.
                    //This makes UIImage display it at a more useful scaling.
                    if let range = fileName.rangeOfString(".") {
                        
                        let fileNameWithoutSuffix = fileName.substringToIndex(range.startIndex)
                        fileName = fileNameWithoutSuffix + "@2x.jpg"
                    }
                    
                    let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
                    let pathArray = [dirPath, fileName]
                    let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
                    
                    NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: result, attributes: nil)
                    
                    //...and update the filePath.
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        webcam.iconImageFilePath = fileName
                        
                        completion(success: true, error: nil)
                    })
                }
            }
        })
    }
    
    //MARK: - Helper functions
    
    func findOrCreateNewQuakeFromArray(quakeArray: [[String : AnyObject]]) {
        
        //This function uses sets to determine which of the newly downloaded
        //quakes already exist in Core Data, and only add the new ones.
        //This is to minimise the number of fetches to Core Data.
        
        //Create sets to hold new earthquake IDs.
        var newQuakeIDsSet:      Set<String> = []
        var existingQuakeIDsSet: Set<String> = []
        
        for quake in quakeArray {
            
            newQuakeIDsSet.insert(quake[USGSJSONResponseKeys.ID] as! String)
        }
        
        //Create fetch request to get any existing Earthquakes matching the new IDs.
        let fetchRequest = NSFetchRequest(entityName: "Earthquake")
        fetchRequest.predicate = NSPredicate(format: "id IN %@", newQuakeIDsSet)
        
        //Fetch the results array...
        //dispatch_async(dispatch_get_main_queue(), {
        sharedContext.performBlock({
            let earthquakesMatchingIDs = try! self.sharedContext.executeFetchRequest(fetchRequest) as! [Earthquake]
            
            //...and use it to populate a set with the earthquake IDs.
            for quake in earthquakesMatchingIDs {
                
                existingQuakeIDsSet.insert(quake.id)
            }
            
            //Get subset containing IDs which don't already exist in Core Data...
            let setToBeAdded = newQuakeIDsSet.subtract(existingQuakeIDsSet)
            
            //...then iterate through the new quakes, adding the ones which
            //don't already exist.
            for quake in quakeArray {
                
                if setToBeAdded.contains(quake[USGSJSONResponseKeys.ID] as! String) {
                    
                    //self.sharedContext.performBlock({ Earthquake(dictionary: quake, context: self.sharedContext) })
                    
                    Earthquake(dictionary: quake, context: self.sharedContext)
                }
            }
        })
    }
}
