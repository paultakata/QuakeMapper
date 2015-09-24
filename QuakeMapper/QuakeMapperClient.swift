//
//  QuakeMapperClient.swift
//  QuakeMapper
//
//  Created by Paul Miller on 13/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import Foundation
import UIKit

class QuakeMapperClient {
    
    //MARK: - Properties
    //MARK: Shared instance
    
    //Single line shared instance declaration. Still thread safe!😄
    //Via http://krakendev.io/blog/the-right-way-to-write-a-singleton
    
    static let sharedInstance = QuakeMapperClient()
    
    //MARK: Shared session.
    
    var session: NSURLSession
    
    //MARK: Core Data convenience
    
    var sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext!
    
    //MARK: Authentication state.
    
    //Twitter token for authenticating API calls. Not stored because its validity can expire.
    var twitterBearerToken: String?
    
    //MARK: - Initialiser
    
    private init() {
        
        session = NSURLSession.sharedSession()
    }
    
    //MARK: - GET
    
    func GETMethodWithWebsite(website: Website,
        method: String,
        parameters: [String : AnyObject],
        completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
            //Build the URL and URL request specific to the website required.
            let urlString = website.baseURL() + method + QuakeMapperClient.escapedParameters(parameters)
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            //Add appropriate HTTP header field keys.
            request = website.addHTTPHeaderFieldKeysForGETRequest(request)
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                //Hide the network activity indicator.
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                //Parse the received data.
                if let error = downloadError {
                    
                    let newError = QuakeMapperClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    QuakeMapperClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
                }
            }
            
            //Start the request task and show network activity indicator.
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            task.resume()
    }
    
    func GETMethodForURLString(urlString: String,
        completionHandler: (result: NSData?, error: NSError?) -> Void) {
            
            //Create request with urlString.
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                //Hide the network activity indicator.
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                if let error = downloadError {
                    
                    let newError = QuakeMapperClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    completionHandler(result: data, error: nil)
                }
            }
            
            //Start the request task and show network activity indicator.
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            task.resume()
    }
    
    // MARK: - POST
    
    func POSTMethodWithWebsite(website: Website,
        method: String,
        parameters: [String : AnyObject],
        jsonBody: [String : AnyObject],
        completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
            //Build the URL and request specific to the website required.
            let urlString = website.baseURL() + method + QuakeMapperClient.escapedParameters(parameters)
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            request.HTTPMethod = "POST"
            
            //Add appropriate HTTP header field keys and HTTP body.
            request = website.addHTTPHeaderFieldKeysForPOSTRequest(request)
            
            request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                //Parse the received data.
                if let error = downloadError {
                    
                    let newError = QuakeMapperClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    QuakeMapperClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
                }
            }
            
            //Start the request task.
            task.resume()
    }
    
    //MARK: - PUT
    
    func PUTMethodWithWebsite(website: Website,
        method: String,
        parameters: [String : AnyObject],
        jsonBody: [String:AnyObject],
        completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
            //Build the URL and request specific to the website required.
            let urlString = website.baseURL() + method + QuakeMapperClient.escapedParameters(parameters)
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            request.HTTPMethod = "PUT"
            
            //Add appropriate HTTP header field keys and HTTP body.
            request = website.addHTTPHeaderFieldKeysForPUTRequest(request)
            
            request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(jsonBody, options: [])
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                //Parse the received data.
                if let error = downloadError {
                    
                    let newError = QuakeMapperClient.errorForData(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    QuakeMapperClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
                }
            }
            
            //Start the request task.
            task.resume()
    }
    
    //MARK: - HEAD
    
    func HEADMethodForURL(url: NSURL,
        completionHandler: (error: NSError?) -> Void) {
            
            //Create HEAD request and task.
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "HEAD"
            
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                //If there is an error, pass it to the completion handler...
                if let error = downloadError {
                    
                    let newError = QuakeMapperClient.errorForData(data, response: response, error: error)
                    
                    completionHandler(error: newError)
                } else {
                    
                    //...if not, pass nil.
                    completionHandler(error: nil)
                }
            }
            
            //Start the request task.
            task.resume()
    }
    
    //MARK: - DELETE
    
    func DELETEMethodWithWebsite(website: Website,
        method: String,
        parameters: [String : AnyObject],
        completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
            //Create URL and DELETE request.
            let urlString = website.baseURL() + method + QuakeMapperClient.escapedParameters(parameters)
            var request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            request.HTTPMethod = "DELETE"
            
            //Add appropriate HTTP header fields keys.
            request = website.addHTTPHeaderFieldKeysForDELETERequest(request)
            
            //Make the request.
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                if let error = downloadError {
                    
                    let newError = QuakeMapperClient.errorForData(data, response: response, error: error)
                    
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    QuakeMapperClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
                }
            }
            
            //Start the request task.
            task.resume()
    }
    
    //MARK: - Helper functions.
    
    //Create Base64 encoded bearer value for Twitter authentication.
    class func getBase64TwitterAuthValue() -> String {
        
        let key = NSBundle.mainBundle().objectForInfoDictionaryKey("consumerKey") as! String
        let secret = NSBundle.mainBundle().objectForInfoDictionaryKey("consumerSecret") as! String
        let bearer = key + " " + secret
        
        let utf8Bearer = bearer.dataUsingEncoding(NSUTF8StringEncoding)
        
        let base64Bearer = utf8Bearer?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        return base64Bearer!
    }
    
    //I repurposed these from Jarrod's code in The Movie Manager, so they are similar.
    
    //Reformat parameters to be usable in URLs.
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            let replaceSpaceValue = escapedValue!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    //Check to see if there is a received error, if not, return the original local error.
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
            
            //Check for presence of "error" in JSON response...
            if let errorMessage = parsedResult[QuakeMapperClient.CommonJSONResponseKeys.Error] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "Mapper Error", code: 1, userInfo: userInfo)
            }
            
            //...if not then check for presence of "errors" array in JSON response.
            if let errorArray = parsedResult[QuakeMapperClient.TwitterJSONResponseKeys.Errors]   as? [[String : AnyObject]],
                 errorMessage = errorArray[0][QuakeMapperClient.TwitterJSONResponseKeys.Message] as? String {
                    
                    let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                    
                    return NSError(domain: "Mapper error", code: 1, userInfo: userInfo)
            }
        }
        return error
    }
    
    //Parse the received JSON data and pass it to the completion handler.
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        let parsedResult: AnyObject?
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            completionHandler(result: parsedResult, error: nil)
            
        } catch let error as NSError {
            
            completionHandler(result: nil, error: error)
        }
    }
    
    //Swap URL placeholder for actual value of e.g. user ID.
    class func substituteKeyInMethod(method: String, key: String, value: String) -> String? {
        
        if method.rangeOfString("{\(key)}") != nil {
            
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
}
