//
//  MapViewController.swift
//  QuakeMapper
//
//  Created by Paul Miller on 13/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import CoreData
import MapKit
import UIKit
import TwitterKit

class MapViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var mapView:                    MKMapView!
    @IBOutlet weak var refreshBarButton:           UIBarButtonItem!
    @IBOutlet weak var dateSlider:                 UISlider!
    @IBOutlet weak var dateLabel:                  UILabel!
    @IBOutlet weak var upToDateLabel:              UILabel!
    @IBOutlet weak var segmentedControl:           UISegmentedControl!
    @IBOutlet weak var activityIndicator:          UIActivityIndicatorView!
    @IBOutlet weak var returnToPreviousZoomButton: UIButton!
    
    //MARK: Temporary storage properties
    
    var allQuakes: [Earthquake]? {
        
        didSet {
            
            //Get subsets of the quake data on a background thread.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                
                self.getQuakeSubsetsWithCompletion({
                    success in
                    
                    //Once complete, call segmentedControlValueChanged() to update the correct annotations
                    //based on whatever the user has selected. Also re-enable UI controls.
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.dateSlider.enabled = true
                        self.segmentedControl.enabled = true
                        self.activityIndicator.stopAnimating()
                        self.segmentedControlValueChanged(self.segmentedControl)
                    })
                })
            })
        }
    }
    
    var recentQuakes:              [Earthquake]            = [] //Arrays and dictionary to store subsets of quake data.
    var quakesByDay:               [NSDate : [Earthquake]] = [:]
    var quakesByDaySortedDayArray: [NSDate]                = []
    
    var previousSliderValue: Int = 0
    var previousMapRegion:   MKCoordinateRegion?
    
    let dateFormatter = NSDateFormatter() //Declared here to avoid creating multiple date formatters elsewhere.
    
    //MARK: Constants
    
    let CentreLatitudeKey        = "Centre Latitude Key"
    let CentreLongitudeKey       = "Centre Longitude Key"
    let SpanLatitudeDeltaKey     = "Span Latitude Delta Key"
    let SpanLongitudeDeltaKey    = "Span Longitude Delta Key"
    let DateQuakesLastCheckedKey = "Date Quakes Last Checked Key"
    
    //MARK: Core Data convenience
    
    var sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext!
    
    //MARK: - Overrides
    //MARK: View methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        logInTwitter()
        prepareUI()
        prepareDateFormatter()
        prepareMap()
        getAllQuakes(nil)
    }

    //MARK: Memory management
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    //MARK: - IB methods
    
    @IBAction func dateSliderValueChanged(sender: UISlider) {
        
        let sliderValueAsInt = Int(sender.value)
        
        //Check if slider has been moved sufficiently to change its Int value. Hopefully reduces flickering of annotations.
        if sliderValueAsInt != previousSliderValue {
            
            //Remove previously displayed map annotations.
            mapView.removeAnnotations(mapView.annotations)
            
            //Retrieve dictionary key from array, and new annotations from dictionary.
            let key = quakesByDaySortedDayArray[sliderValueAsInt]
            mapView.addAnnotations(quakesByDay[key])
            
            //Update date label with relevant date.
            let dayString = dateFormatter.stringFromDate(key)
            dateLabel.text = dayString
            
            //Update previousSliderValue.
            previousSliderValue = sliderValueAsInt
        }
    }
    
    @IBAction func returnToPreviousZoomButtonPressed(sender: UIButton) {
        
        //Reset map region.
        mapView.setRegion(previousMapRegion!, animated: true)
        
        //Reset UI.
        UIView.animateWithDuration(0.5, animations: {
            
            self.segmentedControl.alpha = 1.0
            self.returnToPreviousZoomButton.alpha = 0.0
        })
        
        refreshBarButton.enabled = true
        mapView.zoomEnabled = true
        mapView.scrollEnabled = true
        mapView.pitchEnabled = true
        mapView.rotateEnabled = true
        
        //Reset map annotations.
        previousSliderValue = -1                       //These two lines reset the annotations to display
        segmentedControlValueChanged(segmentedControl) //what the user was last looking at.
    }
    
    @IBAction func refreshBarButtonPressed(sender: UIBarButtonItem) {
        
        getAllQuakes(sender)
    }
    
    @IBAction func segmentedControlValueChanged(sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
            
        case 0: //Show All
            
            //Animate UI changes.
            if self.dateLabel.alpha != 0.0 {
                
                UIView.animateWithDuration(0.3,
                    animations: {
                        self.dateLabel.alpha = 0.0
                        self.dateSlider.alpha = 0.0
                    },
                    completion: nil)
            }
            
            //Remove old annotations and add all quakes.
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(allQuakes)
            
            //Set previousSliderValue to an impossible value, this will force dateSliderValueChanged()
            //to run if user switches from View By Day to another setting and back again.
            previousSliderValue = -1
            
        case 1: //Show Recent
            
            //Animate UI changes.
            if self.dateLabel.alpha != 0.0 {
                
                UIView.animateWithDuration(0.3,
                    animations: {
                        self.dateLabel.alpha = 0.0
                        self.dateSlider.alpha = 0.0
                    },
                    completion: nil)
            }
            
            //Remove old annotations and add recent quakes.
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotations(recentQuakes)
            
            //Set previousSliderValue to an impossible value, this will force dateSliderValueChanged()
            //to run if user switches from View By Day to another setting and back again.
            previousSliderValue = -1
            
        case 2: //View by Day
            
            //Animate UI changes.
            UIView.animateWithDuration(0.3,
                animations: {
                    self.dateLabel.alpha = 1.0
                    self.dateSlider.alpha = 1.0
                },
                completion: nil)
            
            //Call dateSliderValueChanged(), this removes the old annotations and
            //adds the correct new ones based on the user's slider position.
            dateSliderValueChanged(dateSlider)
            
        default:
            break
        }
    }
    
    //MARK: - Helper functions
    
    func logInTwitter() {
        
        Twitter.sharedInstance().logInGuestWithCompletion {
            session, error in
            
            if let session = session,
                accessToken = session.accessToken {
                    
                    //Store the bearer token for future API calls.
                    QuakeMapperClient.sharedInstance.twitterBearerToken = accessToken
            }
        }
    }
    
    func prepareUI() {
        
        dateLabel.alpha = 0.0
        dateLabel.layer.cornerRadius = 5
        dateLabel.layer.masksToBounds = true
        
        returnToPreviousZoomButton.alpha = 0.0
        returnToPreviousZoomButton.layer.cornerRadius = 5
        returnToPreviousZoomButton.layer.masksToBounds = true
        
        upToDateLabel.alpha = 0.0
        dateSlider.alpha = 0.0
        
        //Rotate slider 90 degs counter-clockwise.
        dateSlider.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        dateSlider.setThumbImage(UIImage(named: "EarthquakeRotated"), forState: .Normal)
    }
    
    func prepareDateFormatter() {
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        dateFormatter.doesRelativeDateFormatting = true
    }
    
    func prepareMap() {
        
        mapView.delegate = self
        mapView.mapType = .Hybrid
        loadMapRegion()
    }
    
    func getQuakeSubsetsWithCompletion(completion: (success: Bool) -> Void) {
        
        //Reset temporary variables.
        recentQuakes = []
        quakesByDay = [:]
        quakesByDaySortedDayArray = []
        
        //Create calendar for user's system and array to store keys.
        let calendar = NSCalendar.currentCalendar()
        let timezone = NSTimeZone.systemTimeZone()
        calendar.timeZone = timezone
        var unsortedArray: [NSDate] = []
        
        if let allQuakes = allQuakes {
            
            //Iterate through all the quakes...
            for quake in allQuakes {
                
                //...append recent quakes to new array...
                if quake.tweetsAvailable {
                    
                    recentQuakes.append(quake)
                }
                
                //...and split them into a dictionary based on the day they occurred.
                let dayEarthquakeOccured = dateAtBeginningOfDayForDate(quake.time, withCalendar: calendar)
                
                //If the dictionary already has that date as a key...
                if let quakesOnThisDay = quakesByDay[dayEarthquakeOccured] {
                    
                    //...append the new quake to it...
                    quakesByDay[dayEarthquakeOccured]!.append(quake)
                } else {
                    
                    //...otherwise add the new key and value to the dictionary...
                    quakesByDay[dayEarthquakeOccured] = [quake]
                    
                    //...and the key to an array.
                    unsortedArray.append(dayEarthquakeOccured)
                }
            }
            
            //Sort the array.
            quakesByDaySortedDayArray = sorted(unsortedArray, {
                date1, date2 in
                
                let compare = date1.compare(date2)
                return compare == .OrderedDescending ? false : true
            })
            
            //Clean it so there are only 30 days of data.
            if quakesByDaySortedDayArray.count > 30 {
                
                let excess = quakesByDaySortedDayArray.count - 30
                
                for var i = 0; i < excess; i++ {
                    
                    quakesByDaySortedDayArray.removeAtIndex(0)
                }
            }
        }
        
        completion(success: true)
    }
    
    func dateAtBeginningOfDayForDate(date: NSDate, withCalendar calendar: NSCalendar) -> NSDate {
        
        //Get date components from NSDate input.
        let dateComponents = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: date)
    
        //Set the hour, minutes and seconds to 0 to return midnight on the day in the user's calendar and timezone.
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        
        let beginningOfDay = calendar.dateFromComponents(dateComponents)
        
        return beginningOfDay!
    }
    
    func getAllQuakes(sender: UIBarButtonItem?) {
        
        //By default, download the quake data.
        var shouldDownloadQuakeData = true
        
        //If data has been downloaded in the past...
        if let dateQuakesLastChecked = NSUserDefaults.standardUserDefaults().objectForKey(DateQuakesLastCheckedKey) as? NSDate {
            
            //...check to see if that was in the last 15 minutes...
            let now = NSDate()
            let timeDifference = now.timeIntervalSinceDate(dateQuakesLastChecked)
            
            if timeDifference < 900 { //900 seconds == 15 minutes, the refresh time of the USGS feed.
                
                //...and if so don't re-download identical data.
                shouldDownloadQuakeData = false
                
                //Check if getAllQuakes() was called by user pressing refresh button.
                if sender != nil {
                    
                    //If so, inform the user there is nothing new.
                    UIView.animateWithDuration(0.5,
                        animations: { self.upToDateLabel.alpha = 1.0 },
                        completion: {
                            i in
                            
                            UIView.animateWithDuration(0.5,
                                delay: 1.0,
                                options: nil,
                                animations: { self.upToDateLabel.alpha = 0.0 },
                                completion: nil)
                    })
                }
                
                //Fetch any existing quakes if they haven't already been fetched.
                if allQuakes?.count == 0 || allQuakes == nil {
                    
                    allQuakes = fetchAllQuakes()
                }
            }
        }
        
        if shouldDownloadQuakeData {
            
            //Disable UI controls and enable activity indicator during download.
            segmentedControl.enabled = false
            dateSlider.enabled = false
            activityIndicator.startAnimating()
            
            downloadQuakeData({
                success in
                
                if success {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.allQuakes = self.fetchAllQuakes()
                    })
                }
            })
        }
    }
    
    func fetchAllQuakes() -> [Earthquake] {
        
        //Create and execute the fetch request.
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Earthquake")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        //Check for errors.
        if error != nil {
            
            alertUserWithTitle("Error",
                message: "Something weird happened. If it keeps happening you might have to reinstall.",
                retry: false)
        }
        
        return results as! [Earthquake]
    }
    
    func fetchWebcamsForEarthquake(earthquake: Earthquake) -> [Webcam] {
        
        //Create and execute the fetch request.
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Webcam")
        fetchRequest.predicate = NSPredicate(format: "earthquake == %@", earthquake)
        
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        //Check for errors.
        if error != nil {
            
            alertUserWithTitle("Error",
                message: "Something weird happened. If it keeps happening you might have to reinstall.",
                retry: false)
        }
        
        return results as! [Webcam]
    }
    
    func downloadWebcamsForEarthquake(earthquake: Earthquake, withCompletion completion: (success: Bool) -> Void) {
        
        //Start download process.
        QuakeMapperClient.sharedInstance.getWebcamsForEarthquake(earthquake, withCompletion: {
            success, error in
            
            if success {
                
                //Try to get the icon images for the newly downloaded webcams.
                let newWebcams = self.fetchWebcamsForEarthquake(earthquake)
                
                for webcam in newWebcams {
                    
                    QuakeMapperClient.sharedInstance.getIconImageForWebcam(webcam, withCompletion: {
                        success, error in
                        
                        //If successful, show the new webcam annotation.
                        dispatch_async(dispatch_get_main_queue(), {
                            
                            self.mapView.addAnnotation(webcam)
                            CoreDataStackManager.sharedInstance.saveContext()
                        })
                    })
                }
                
                //Save to Core Data.
                dispatch_async(dispatch_get_main_queue(), {
                
                    CoreDataStackManager.sharedInstance.saveContext()
                })
                
                completion(success: true)
            } else {
                
                completion(success: false)
            }
        })
    }
    
    func downloadQuakeData(completionHandler: (success: Bool) -> Void) {
        
        //Download the current earthquake data...
        QuakeMapperClient.sharedInstance.getUSGSQuakeData({
            success, error in
            
            if success {
                
                //...if successful store current date/time as reference...
                let downloadedDate = NSDate()
                NSUserDefaults.standardUserDefaults().setObject(downloadedDate, forKey: self.DateQuakesLastCheckedKey)
                
                //...save....
                dispatch_async(dispatch_get_main_queue(), {
                    
                    CoreDataStackManager.sharedInstance.saveContext()
                })
                
                //...and call the completion handler.
                completionHandler(success: true)
            } else {
                
                //If it didn't work, alert the user with a retry option...
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.alertUserWithTitle("Something went wrong getting the quake data.", message: "\(error!.localizedDescription) Tap to retry.", retry: true)
                })
                
                //...and call the completion handler.
                completionHandler(success: false)
            }
        })
    }
    
    func saveMapRegion() {
        
        //The mapView region property is a struct containing 4 double values.
        //This saves each value individually to NSUserDefaults.
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.latitude, forKey: CentreLatitudeKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.center.longitude, forKey: CentreLongitudeKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.latitudeDelta, forKey: SpanLatitudeDeltaKey)
        NSUserDefaults.standardUserDefaults().setDouble(mapView.region.span.longitudeDelta, forKey: SpanLongitudeDeltaKey)
    }
    
    func loadMapRegion() {
        
        //Check for user defaults, if they exist then zoom map to old location.
        //Check for existence of centreLatitude before proceeding. doubleForKey() returns 0 if key doesn't exist.
        let centreLatitude = NSUserDefaults.standardUserDefaults().doubleForKey(CentreLatitudeKey)
        
        if centreLatitude != 0 {
            
            //Assemble all the things...
            let centreLongitude    = NSUserDefaults.standardUserDefaults().doubleForKey(CentreLongitudeKey)
            let spanLatitudeDelta  = NSUserDefaults.standardUserDefaults().doubleForKey(SpanLatitudeDeltaKey)
            let spanLongitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey(SpanLongitudeDeltaKey)
            
            let centre = CLLocationCoordinate2DMake(centreLatitude, centreLongitude)
            let span   = MKCoordinateSpanMake(spanLatitudeDelta, spanLongitudeDelta)
            
            //...into a region...
            let region = MKCoordinateRegionMake(centre, span)
            
            //...and move the map back to where the user left it.
            mapView.region = region
        }
    }
    
    func alertUserWithTitle(title: String, message: String, retry: Bool) {
        
        //Create alert and show it to user.
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "OK",
            style: .Default,
            handler: nil)
        
        if retry {
            
            let retryAction = UIAlertAction(title: "Retry",
                style: .Destructive,
                handler: {
                    action in
                    
                    self.getAllQuakes(nil)
            })
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func imageForAnnotation(annotation: Earthquake) -> UIImage {
        
        //Return green, yellow or red annotation image based on quake magnitude.
        if annotation.magnitude < 5.0 {
            return UIImage(named: "GraphIconGreen")!
            
        } else if annotation.magnitude < 6.0 {
            return UIImage(named: "GraphIconYellow")!
            
        } else {
            return UIImage(named: "GraphIconRed")!
        }
    }
    
    func configureView(view: MKAnnotationView, forAnnotation annotation: Earthquake) {
        
        //Set the required image.
        view.image = imageForAnnotation(annotation)
        
        //Get a Twitter button and enable/disable it depending on the age of the earthquake.
        let leftButton = UIButton.buttonWithType(.Custom) as! UIButton
        leftButton.frame = CGRectMake(0, 0, 20, 20)
        leftButton.setImage(UIImage(named: "TwitterBird"), forState: .Normal)
        leftButton.enabled = annotation.tweetsAvailable
        leftButton.tag = 0
        
        view.leftCalloutAccessoryView = leftButton
    }
    
    func configureWebcamView(view: MKAnnotationView, forAnnotation annotation: Webcam) {
        
        //Set the required properties.
        view.image = annotation.iconImage
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.canShowCallout = false
    }
}

//MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        
        //Save the map region as the user moves it around.
        saveMapRegion()
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if let annotation = annotation as? Earthquake { //Views for Earthquake annotations.
            
            let identifier = "Earthquake"
            var view: MKAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) {
                
                dequeuedView.annotation = annotation
                
                //Annotation views vary depending on the quake magnitude, so require configuring each time.
                configureView(dequeuedView, forAnnotation: annotation)
                
                view = dequeuedView
            } else {
                
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                configureView(view, forAnnotation: annotation)
                
                //The following properties are constant for all earthquake annotation views,
                //so are not included in the configureView(forAnnotation:) method.
                view.canShowCallout = true
                
                let rightButton = UIButton.buttonWithType(.Custom) as! UIButton
                rightButton.frame = CGRectMake(0, 0, 20, 20)
                rightButton.setImage(UIImage(named: "Camera"), forState: .Normal)
                rightButton.tag = 1
                
                view.rightCalloutAccessoryView = rightButton
            }
            return view
            
        } else if let annotation = annotation as? Webcam { //Views for Webcam annotations.
            
            let identifier = "Webcam"
            var view: MKAnnotationView
            
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) {
                
                dequeuedView.annotation = annotation
                configureWebcamView(dequeuedView, forAnnotation: annotation)
                
                view = dequeuedView
            } else {
                
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                configureWebcamView(view, forAnnotation: annotation)
            }
            return view
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        if view.reuseIdentifier == "Earthquake" { //This section for Earthquake annotations.
            
            //Store current map region.
            previousMapRegion = mapView.region
            
            mapView.zoomEnabled = false
            mapView.scrollEnabled = false
            mapView.pitchEnabled = false
            mapView.rotateEnabled = false
            
            //Get the earthquake.
            if let earthquake = view.annotation as? Earthquake {
                
                //STEP 1: Zoom to it. I have an 80km radius search for webcams, so including padding I am using a 170km span here.
                mapView.setRegion(MKCoordinateRegionMakeWithDistance(earthquake.coordinate, 170000, 170000), animated: true)
                
                //Get array of currently displayed annotations...
                if var annotations = mapView.annotations as? [Earthquake] {
                    
                    //...find the selected one...
                    if let index = find(annotations, earthquake) {
                        
                        //...remove it from the array and then remove
                        //the remaining annotations from the map.
                        annotations.removeAtIndex(index)
                        mapView.removeAnnotations(annotations)
                    }
                }
                
                //STEP 2: Fetch stored webcams.
                let storedWebcams = fetchWebcamsForEarthquake(earthquake)
                
                //If none exist...
                if storedWebcams.count == 0 {
                    
                    //...attempt to download nearby webcams...
                    downloadWebcamsForEarthquake(earthquake, withCompletion: {
                        success in
                        
                        //Intentionally left blank.
                    })
                } else {
                    
                    //Add previously stored webcams.
                    self.mapView.addAnnotations(storedWebcams)
                }
                
                //STEP 3: Update UI.
                UIView.animateWithDuration(0.5, animations: {
                    
                    self.segmentedControl.alpha = 0.0
                    self.dateSlider.alpha = 0.0
                    self.dateLabel.alpha = 0.0
                    self.returnToPreviousZoomButton.alpha = 1.0
                })
                
                refreshBarButton.enabled = false
            }
        }
        
        if view.reuseIdentifier == "Webcam" { //This section for Webcam annotations.
            
            if let webcam = view.annotation as? Webcam {
                
                let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
                nextVC.webcam = webcam
                
                presentViewController(nextVC, animated: true, completion: nil)
            }
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        
        //Get earthquake tapped on...
        let earthquake = view.annotation as! Earthquake
        
        //...get the right view controller to pass it to...
        let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("QuakeDetailTabBarController") as! UITabBarController
        let childVC = nextVC.viewControllers?.first as! UINavigationController
        let grandchildVC = childVC.topViewController as! TweetTableViewController
        
        //...pass it...
        grandchildVC.earthquake = earthquake
        
        //...and set correct selected tab.
        nextVC.selectedIndex = control.tag
        
        presentViewController(nextVC, animated: true, completion: nil)
    }
    
    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {
        
        //Allow drop animation on Show All and Show Recent only.
        if segmentedControl.selectedSegmentIndex != 2 {
            
            //Variable to allow delayed drops on each annotation view.
            var i = -1
            
            for view in views {
                i++
                
                // Don't animate drop of user location view.
                if view.annotation is MKUserLocation {
                    
                    continue
                }
                
                if let annotationView = view as? MKAnnotationView {
                    
                    let point = MKMapPointForCoordinate(annotationView.annotation.coordinate)
                    
                    //Don't animate drop if annotation view is offscreen.
                    if !MKMapRectContainsPoint(mapView.visibleMapRect, point) {
                        
                        continue
                    }
                    
                    //Get final frame for annotation view...
                    let endFrame = annotationView.frame
                    
                    //..set start frame and alpha...
                    annotationView.frame = CGRectMake(annotationView.frame.origin.x, annotationView.frame.origin.y - 120, annotationView.frame.size.width, annotationView.frame.size.height)
                    annotationView.alpha = 0.0
                    
                    //...make a delay...
                    let delay = 0.01 * Double(i)
                    
                    //...and animate the drop.
                    UIView.animateWithDuration(0.3,
                        delay: delay,
                        options: .CurveEaseOut,
                        animations: {
                            annotationView.frame = endFrame
                            annotationView.alpha = 1.0
                        },
                        completion: nil)
                }
            }
        } else {
            
            //On View by Day, only animate alpha.
            for view in views {
                
                // Don't animate user location view.
                if view.annotation is MKUserLocation {
                    
                    continue
                }
                
                if let annotationView = view as? MKAnnotationView {
                    
                    let point = MKMapPointForCoordinate(annotationView.annotation.coordinate)
                    
                    //Don't animate if annotation view is offscreen.
                    if !MKMapRectContainsPoint(mapView.visibleMapRect, point) {
                        
                        continue
                    }
                    
                    //Set start alpha.
                    annotationView.alpha = 0.0
                    
                    //Animate it.
                    UIView.animateWithDuration(0.1,
                        delay: 0,
                        options: .CurveEaseIn,
                        animations: {
                            annotationView.alpha = 1.0
                        },
                        completion: nil)
                }
            }
        }
    }
    
    //The following 3 functions are used to show and hide the network activity indicator as the map loads.
    
    func mapViewWillStartLoadingMap(mapView: MKMapView!) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView!) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func mapViewDidFailLoadingMap(mapView: MKMapView!, withError error: NSError!) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}
