//
//  Tweet.swift
//  QuakeMapper
//
//  Created by Paul Miller on 14/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import Foundation
import CoreData
import TwitterKit

@objc(Tweet)

class Tweet: NSManagedObject {
    
    //MARK: - Properties
    
    @NSManaged var tweet:   TWTRTweet
    @NSManaged var tweetID: String
    
    //MARK: Relationships
    
    @NSManaged var earthquake: Earthquake
    
    //MARK: - Initialisers
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(tweet: TWTRTweet, quake: Earthquake, context: NSManagedObjectContext) {
        
        //Core Data
        let entity = NSEntityDescription.entityForName("Tweet", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.tweet = tweet
        self.tweetID = tweet.tweetID
        self.earthquake = quake
    }
}
