//
//  WebcamCollectionViewController.swift
//  QuakeMapper
//
//  Created by Paul Miller on 24/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import CoreData
import UIKit

class WebcamCollectionViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var collectionView:              UICollectionView!
    @IBOutlet weak var doneBarButton:               UIBarButtonItem!
    @IBOutlet weak var activityIndicator:           UIActivityIndicatorView!
    @IBOutlet weak var noWebcamsAvailableView:      UIView!
    @IBOutlet weak var noWebcamsAvailableImageView: UIImageView!
    @IBOutlet weak var noWebcamsAvailableLabel:     UILabel!
    
    //MARK: Temporary storage properties
    
    var selectedIndexes   = [NSIndexPath]() //Arrays to keep track of selected or changed collection view cells.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths:  [NSIndexPath]!
    var updatedIndexPaths:  [NSIndexPath]!
    
    //MARK: Computed properties
    
    var earthquake: Earthquake {
        
        //Retrieve earthquake object from TweetTableViewController.
        let navVC = self.tabBarController?.viewControllers![0] as! UINavigationController
        let tweetTableVC = navVC.topViewController as! TweetTableViewController
        
        return tweetTableVC.earthquake
    }
    
    //MARK: Core Data Convenience
    
    var sharedContext = CoreDataStackManager.sharedInstance.managedObjectContext!
    
    //MARK: Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Webcam")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "webcamID", ascending: false)]
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
        
        setupCollectionView()
        fetchExistingWebcams()
        
        //If there are no existing webcams, download some.
        if fetchedResultsController.fetchedObjects?.count == 0 {
            
            activityIndicator.startAnimating()
            getWebcamsForEarthquake(earthquake)
        }
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
        
        //Delete the old webcams.
        for webcam in fetchedResultsController.fetchedObjects as! [Webcam] {
            
            sharedContext.deleteObject(webcam)
        }
        
        //Save the context.
        CoreDataStackManager.sharedInstance.saveContext()
        
        //Start activity indicator and try downloading new webcams.
        activityIndicator.startAnimating()
        noWebcamsAvailableView.hidden = true
        getWebcamsForEarthquake(earthquake)
    }

    //MARK: - Helper methods
    
    func getWebcamsForEarthquake(earthquake: Earthquake) {
        
        //Make request for webcams.
        QuakeMapperClient.sharedInstance.getWebcamsForEarthquake(earthquake, withCompletion: {
            success, error in
            
            if success {
                
                //If successful, save the new webcams and reload.
                dispatch_async(dispatch_get_main_queue(), {
                    
                    CoreDataStackManager.sharedInstance.saveContext()
                    self.activityIndicator.stopAnimating()
                    self.collectionView.reloadData()
                    
                    if self.fetchedResultsController.fetchedObjects?.count == 0 {
                        
                        self.noWebcamsAvailableView.hidden = false
                    }
                })
            } else {
                
                //Give user option to retry.
                self.alertUserWithTitle("Something went wrong getting the webcams.", message: error!.localizedDescription, retry: true)
                self.activityIndicator.stopAnimating()
            }
        })
    }
    
    func configureCell(cell: WebcamCollectionViewCell, webcam: Webcam) {
        
        //Set cell properties.
        cell.cellImageView.image = nil
        
        //Set cell UI prettiness.
        cell.cellImageView.layer.cornerRadius = 12
        cell.cellImageView.layer.masksToBounds = true
        
        //If there isn't already a preview image...
        if webcam.previewImage == nil {
            
            //...animate the activity indicator...
            cell.activityIndicator.startAnimating()
            
            //...and attempt to get the preview image.
            QuakeMapperClient.sharedInstance.getPreviewImageForWebcam(webcam, withCompletion: {
                success, error in
                
                if success {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        //If successful, update cell...
                        cell.activityIndicator.stopAnimating()
                        cell.cellImageView.image = webcam.previewImage
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
            cell.cellImageView.image = webcam.previewImage
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
                    
                    self.getWebcamsForEarthquake(self.earthquake)
            })
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func fetchExistingWebcams() {
        
        //Perform fetch, alert user if something goes wrong.
        do {
            try fetchedResultsController.performFetch()
            
        } catch let error as NSError {
            
            alertUserWithTitle("Something went wrong.",
                message: "If you keep seeing this you might have to reinstall. \(error.localizedDescription)",
                retry: false)
        }
    }
    
    func setupCollectionView() {
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Set the collection view cells to be 1/3 the screen width with a small space between them.
        let layout = UICollectionViewFlowLayout()
        
        layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = (floor(CGRectGetWidth(UIScreen.mainScreen().bounds) / 3)) - 7
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
}

//MARK: - UICollectionViewDataSource

extension WebcamCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections?[section]
        
        return sectionInfo!.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellIdentifier = "WebcamCollectionViewCell"
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! WebcamCollectionViewCell
        let webcam = fetchedResultsController.objectAtIndexPath(indexPath) as! Webcam
        
        configureCell(cell, webcam: webcam)
        
        return cell
    }
}

//MARK: - UICollectionViewDelegate

extension WebcamCollectionViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! WebcamCollectionViewCell
        
        //Disallow selection if cell is waiting for its image.
        if cell.activityIndicator.isAnimating() {
            
            return false
        }
        
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        //Get webcam and next view controller, set the webcam and present to the user.
        let webcam = fetchedResultsController.objectAtIndexPath(indexPath) as! Webcam
        let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        
        nextVC.webcam = webcam
        
        presentViewController(nextVC, animated: true, completion: nil)
    }
}

//MARK: - NSFetchedResultsControllerDelegate

extension WebcamCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        //Prepare for changed content from Core Data.
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths  = [NSIndexPath]()
        updatedIndexPaths  = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        //Add the indexPath of the changed objects to the appropriate array, depending on the type of change.
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            
        case .Update:
            updatedIndexPaths.append(indexPath!)
            
        case .Move:
            //.Move shouldn't appear in this app, it is here for completeness.
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //Make the relevant updates to the collectionView once Core Data has finished its changes.
        collectionView.performBatchUpdates({
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
}
