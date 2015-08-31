//
//  TweetDetailViewController.swift
//  QuakeMapper
//
//  Created by Paul Miller on 27/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import UIKit
import TwitterKit

class TweetDetailViewController: UIViewController {

    //MARK: - Properties
    
    var receivedTweet: TWTRTweet!
    var tweetView: TWTRTweetView!
    
    //MARK: - Overrides
    //MARK: View methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupTweetView()
        
        self.view.addSubview(tweetView)
    }
    
    //MARK: Memory management

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }

    //MARK: - Helper methods
    
    func setupTweetView() {
        
        tweetView = TWTRTweetView(tweet: receivedTweet, style: .Regular)
        tweetView.showActionButtons = true
        tweetView.delegate = self
        
        //Get the correct size for the view.
        let desiredSize = tweetView.sizeThatFits(CGSizeMake(self.view.bounds.width, CGFloat.max))
        
        //Make the frame for the view with a suitable vertical padding, 72 points in this case.
        tweetView.frame = CGRectMake(0, 72, self.view.bounds.width, desiredSize.height)
        tweetView.center.x = self.view.center.x
    }
}

//MARK: - TWTRTweetViewDelegate

extension TweetDetailViewController: TWTRTweetViewDelegate {
    
    func tweetView(tweetView: TWTRTweetView!, didSelectTweet tweet: TWTRTweet!) {
        
        //Get the tweet's permalink url and open a webview to show it.
        let url = tweet.permalink
        let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        
        nextVC.tweetURL = url
        
        presentViewController(nextVC, animated: true, completion: nil)
    }
    
    func tweetView(tweetView: TWTRTweetView!, didTapURL url: NSURL!) {
        
        //This currently doesn't seem to work due to a bug in Twitter's TWTRTweetView.
        //I'm leaving it in for when they get round to fixing it.
        let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        nextVC.tweetURL = url
        
        presentViewController(nextVC, animated: true, completion: nil)
    }
}
