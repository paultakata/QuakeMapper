//
//  EarthquakeTableViewCell.swift
//  QuakeMapper
//
//  Created by Paul Miller on 18/08/2015.
//  Copyright (c) 2015 PoneTeller. All rights reserved.
//

import UIKit

class EarthquakeTableViewCell: UITableViewCell {
    
    //MARK: - Properties
    
    @IBOutlet weak var cellImageView:     UIImageView!
    @IBOutlet weak var titleLabel:        UILabel!
    @IBOutlet weak var subtitleLabel:     UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //MARK: - Overrides
    //MARK: View methods
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        
        super.setSelected(selected, animated: animated)
    }
}
