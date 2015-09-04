//
//  TweetTableViewController.swift
//  QuakeMapper
//
//  Created by Paul Miller on 24/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import UIKit
import TwitterKit

class TweetTableViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var tableView:         UITableView!
    @IBOutlet weak var doneBarButton:     UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noTweetsView:      UIView!
    @IBOutlet weak var noTweetsImageView: UIImageView!
    @IBOutlet weak var noTweetsLabel:     UILabel!
    
    var earthquake: Earthquake!
    
    //MARK: Core Data Convenience
    
    var sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext!
    
    //MARK: Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Tweet")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "tweetID", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "earthquake == %@", self.earthquake);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    //MARK: - Overrides
    //MARK: View methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        navigationItem.title = earthquake.placeTitle
        
        setUpTableView()
        checkForTweets()
    }

    //MARK: Memory management
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - IB methods
    
    @IBAction func doneBarButtonPressed(sender: UIBarButtonItem) {
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func refreshBarButtonPressed(sender: UIBarButtonItem) {
        
        //Delete existing tweets, if any.
        for tweet in fetchedResultsController.fetchedObjects as! [Tweet] {
            
            sharedContext.deleteObject(tweet)
        }
        
        //Save the context.
        CoreDataStackManager.sharedInstance.saveContext()
        
        //Show the activity indicator and download new tweets.
        activityIndicator.startAnimating()
        noTweetsView.hidden = true
        getTweetsForEarthquake(earthquake)
    }

    //MARK: - Helper methods
    
    func getTweetsForEarthquake(earthquake: Earthquake) {
        
        //Get dates to search between.
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let sinceDateString = dateFormatter.stringFromDate(earthquake.time)
        
        let untilDate = NSDate(timeInterval: 86400, sinceDate: earthquake.time) //86400 seconds == 24hrs.
        let untilDateString = dateFormatter.stringFromDate(untilDate)
        
        //Make request for tweets.
        QuakeMapperClient.sharedInstance.searchTwitterForLocation(earthquake.coordinate,
            since: sinceDateString,
            until: untilDateString) {
            success, errorString, results in
            
            if success {
                
                //Create TWTRTweet objects...
                if let tweetArray = TWTRTweet.tweetsWithJSONArray(results) as? [TWTRTweet] {
                    
                    //...and store them in Core Data Tweet objects.
                    for tweet in tweetArray {
                        
                        dispatch_async(dispatch_get_main_queue(), {
                        
                            Tweet(tweet: tweet, quake: earthquake, context: self.sharedContext)
                        })
                    }
                    
                    //Save the context and update the UI on the main thread.
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        CoreDataStackManager.sharedInstance.saveContext()
                        self.activityIndicator.stopAnimating()
                        self.tableView.reloadData()
                        
                        //If there are no tweets, inform the user.
                        if self.fetchedResultsController.fetchedObjects?.count == 0 {
                            
                            self.noTweetsView.hidden = false
                        }
                    })
                }
            } else {
                
                //Offer the user the option to retry.
                self.alertUserWithTitle("Something went wrong getting tweets.", message: errorString!, retry: true)
            }
        }
    }
    
    func fetchExistingTweets() {
        
        //Perform fetch, inform the user if something goes wrong.
        let error: NSErrorPointer = nil
        fetchedResultsController.performFetch(error)
        
        if error != nil {
            
            alertUserWithTitle("Something went wrong.", message: "If you keep seeing this you might have to reinstall.", retry: false)
        }
    }
    
    func checkForTweets() {
        
        //If the earthquake happened in the past 7 days...
        if earthquake.tweetsAvailable {
            
            //...try to fetch stored tweets...
            fetchExistingTweets()
            
            //...if there are none, try to download some.
            if fetchedResultsController.fetchedObjects?.count == 0 {
                
                activityIndicator.startAnimating()
                getTweetsForEarthquake(earthquake)
            }
        } else {
            
        //Otherwise, tell the user there aren't any to see.
            noTweetsView.hidden = false
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
                    
                    self.getTweetsForEarthquake(self.earthquake)
            })
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func setUpTableView() {
        
        //Set table view appropriately for displaying TWTRTweetTableViewCells.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
    }
}

//MARK: - UITableViewDataSource

extension TweetTableViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //Get cell and tweet for indexPath.
        let cellIdentifier = "TweetCell"
        let tweet = fetchedResultsController.objectAtIndexPath(indexPath) as! Tweet
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! TWTRTweetTableViewCell
        
        //Configure cell, set delegate and return cell.
        cell.configureWithTweet(tweet.tweet)
        cell.tweetView.showActionButtons = true
        cell.tweetView.theme = .Dark
        cell.tweetView.delegate = self
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let sectionInfo = fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
        
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
}

//MARK: - UITableViewDelegate

extension TweetTableViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        //Get tweet at indexPath, use it to get height for row.
        let tweet = fetchedResultsController.objectAtIndexPath(indexPath) as! Tweet
        let height = TWTRTweetTableViewCell.heightForTweet(tweet.tweet, width: CGRectGetWidth(self.view.bounds), showingActions: true)
        
        return height
    }
}

//MARK: - TWTRTweetViewDelegate

extension TweetTableViewController: TWTRTweetViewDelegate {
    
    func tweetView(tweetView: TWTRTweetView!, didSelectTweet tweet: TWTRTweet!) {
        
        //Navigate to a full size TweetView.
        let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("TweetDetailViewController") as! TweetDetailViewController
        nextVC.receivedTweet = tweet
        
        showViewController(nextVC, sender: self)
    }
    
    func tweetView(tweetView: TWTRTweetView!, didTapURL url: NSURL!) {
        
        //This currently doesn't seem to work due to a bug in Twitter's TWTRTweetView.
        //I'm leaving it in for when they get round to fixing it.
        
        //Navigate to a webview showing the url tapped.
        let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        nextVC.tweetURL = url
        
        presentViewController(nextVC, animated: true, completion: nil)
    }
}

//MARK: - NSFetchedResultsControllerDelegate

extension TweetTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
        case .Update:
            let cell = tableView.cellForRowAtIndexPath(indexPath!)! as! TWTRTweetTableViewCell
            let tweet = controller.objectAtIndexPath(indexPath!) as! Tweet
            
            cell.configureWithTweet(tweet.tweet)
            
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
