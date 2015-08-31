//
//  EarthquakeTableViewController.swift
//  QuakeMapper
//
//  Created by Paul Miller on 18/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import CoreData
import UIKit

class EarthquakeTableViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Constants
    
    let DateQuakesLastCheckedKey = "Date Quakes Last Checked Key"
    
    //MARK: Core Data Convenience
    
    var sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext!
    
    //MARK: Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Earthquake")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "tweetsAvailable", ascending: false), NSSortDescriptor(key: "time", ascending: false)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: "tweetsAvailable",
            cacheName: nil)
        
        return fetchedResultsController
        }()
    
    //MARK: - Overrides
    //MARK: View methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        //Set delegates and datasource.
        tableView.delegate = self
        tableView.dataSource = self
        
        //Perform initial fetch.
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            
            alertUserWithTitle("Error",
                message: "Something went wrong. If it keeps happening you might have to reinstall.",
                retry: false)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        tableView.reloadData()
    }

    //MARK: Memory management
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    //MARK: - IB methods
    
    @IBAction func refreshBarButtonPressed(sender: UIBarButtonItem) {
        
        getAllQuakes()
    }
    
    //MARK: - Helper functions
    
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
                    
                    self.getAllQuakes()
            })
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func getAllQuakes() {
        
        //By default, download the quake data.
        var shouldDownloadQuakeData = true
        
        //If data has been downloaded in the past...
        if let dateQuakesLastChecked = NSUserDefaults.standardUserDefaults().objectForKey(DateQuakesLastCheckedKey) as? NSDate {
            
            //...check to see if that was in the last 15 minutes...
            let dateNow = NSDate()
            if dateNow.timeIntervalSinceDate(dateQuakesLastChecked) < 900 { //900 seconds == 15 minutes, the refresh time of the USGS feed.
                
                //...and if so don't re-download identical data.
                shouldDownloadQuakeData = false
            }
        }
        
        if shouldDownloadQuakeData {
            
            downloadQuakeData({
                success in
                
                if success {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.tableView.reloadData()
                    })
                }
            })
        }
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
                    
                    self.alertUserWithTitle("Something went wrong getting the quake data.", message: "Tap to retry.", retry: true)
                })
                
                //...and call the completion handler.
                completionHandler(success: false)
            }
        })
    }
    
    func configureCell(cell: EarthquakeTableViewCell, earthquake: Earthquake) {
        
        //Set cell properties.
        cell.titleLabel.text = earthquake.title
        cell.subtitleLabel.text = earthquake.subtitle
        cell.cellImageView.image = nil
        
        //Set cell UI prettiness.
        cell.cellImageView.layer.cornerRadius = 12
        cell.cellImageView.layer.masksToBounds = true
        cell.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        cell.titleLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        cell.subtitleLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
        cell.selectionStyle = .None
        
        //If there isn't already a map snapshot...
        if earthquake.mapThumbnailImage == nil {
            
            //...animate activity indicator...
            cell.activityIndicator.startAnimating()
            
            //...and attempt to get map snapshot.
            QuakeMapperClient.sharedInstance.getMapSnapshotForQuake(earthquake, withCompletion: {
                success, error in
                
                if success {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        //If successful, update cell...
                        cell.activityIndicator.stopAnimating()
                        cell.cellImageView.image = earthquake.mapThumbnailImage
                    })
                } else {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        //...if not, add placeholder image.
                        cell.activityIndicator.stopAnimating()
                        cell.cellImageView.image = UIImage(named: "earthquake-512")
                    })
                }
            })
        } else {
            
            //Set cell to show stored image.
            cell.cellImageView.image = earthquake.mapThumbnailImage
        }
    }
}

//MARK: - UITableViewDataSource

extension EarthquakeTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "EarthquakeTableViewCell"
        
        //Get correct earthquake and cell...
        let earthquake = fetchedResultsController.objectAtIndexPath(indexPath) as! Earthquake
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! EarthquakeTableViewCell
        
        // and configure it.
        configureCell(cell, earthquake: earthquake)
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return fetchedResultsController.sections!.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let titles = ["Recent Quakes", "Older Quakes"]
        
        return titles[section]
    }
}

//MARK: - UITableViewDelegate

extension EarthquakeTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //Get earthquake tapped on...
        let earthquake = fetchedResultsController.objectAtIndexPath(indexPath) as! Earthquake
        
        //...get the right view controller to pass it to...
        let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("QuakeDetailTabBarController") as! UITabBarController
        let childVC = nextVC.viewControllers?.first as! UINavigationController
        let grandchildVC = childVC.topViewController as! TweetTableViewController
        
        //...pass it...
        grandchildVC.earthquake = earthquake
        
        //...and present to the user.
        presentViewController(nextVC, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        //Customise colours of header views.
        let header = view as! UITableViewHeaderFooterView
        
        header.tintColor = UIColor.blackColor()
        header.textLabel.textColor = UIColor(white: 0.9, alpha: 1.0)
    }
}

//MARK: - NSFetchedResultsControllerDelegate

extension EarthquakeTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!)! as! EarthquakeTableViewCell
            let earthquake = controller.objectAtIndexPath(indexPath!) as! Earthquake
            
            configureCell(cell, earthquake: earthquake)
            
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        tableView.endUpdates()
    }
}
