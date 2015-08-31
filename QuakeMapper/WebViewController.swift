//
//  WebViewController.swift
//  QuakeMapper
//
//  Created by Paul Miller on 25/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {

    //MARK: - Properties
    
    @IBOutlet weak var webView:       UIWebView!
    @IBOutlet weak var backButton:    UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!
    
    var webcam:   Webcam?
    var tweetURL: NSURL?
    
    //MARK: - Overrides
    //MARK: View methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        setupWebView()
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - IB methods
    
    @IBAction func doneButtonPressed(sender: UIBarButtonItem) {
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func backButtonPressed(sender: UIBarButtonItem) {
        
        if webView.canGoBack {
            
            webView.goBack()
        }
    }
    
    @IBAction func forwardButtonPressed(sender: UIBarButtonItem) {
        
        if webView.canGoForward {
            
            webView.goForward()
        }
    }

    //MARK: - Helper functions
    
    func setupWebView() {
        
        //Set webview properties.
        webView.delegate = self
        webView.scalesPageToFit = true
        
        checkBackAndForwardButtons()
        
        let request: NSURLRequest
        
        //Make different request depending on which view controller presented this webView.
        if let urlString = webcam?.urlMobile {
            
            let url = NSURL(string: urlString)!
            request = NSURLRequest(URL: url)
            
        } else if let tweetURL = tweetURL {
            
            request = NSURLRequest(URL: tweetURL)
            
        } else {
            
            let url = NSURL(string: "https://www.google.com")! //Default to stop the compiler complaining. Should never occur.
            request = NSURLRequest(URL: url)
        }
        
        webView.loadRequest(request)
    }
    
    func checkBackAndForwardButtons() {
        
        //Enable or disable the back and forward buttons as necessary.
        backButton.enabled = webView.canGoBack
        forwardButton.enabled = webView.canGoForward
    }
}

extension WebViewController: UIWebViewDelegate {
    
    func webViewDidStartLoad(webView: UIWebView) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        checkBackAndForwardButtons()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        checkBackAndForwardButtons()
    }
}
