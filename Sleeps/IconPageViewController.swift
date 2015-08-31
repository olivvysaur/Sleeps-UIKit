//
//  IconPageViewController.swift
//  Sleeps
//
//  Created by Josh Asch on 30/08/2015.
//  Copyright © 2015 Bearhat. All rights reserved.
//

import UIKit

class IconPageViewController: UIViewController {
    
    /// The 9 visible views which each contain an icon.
    @IBOutlet var iconViews: [CircularImageView]!
    
    /// The icons to display in the iconViews.
    var icons: [UIImage?]! {
        didSet {
            updateIconViews()
        }
    }
    
    
    
    
    // MARK: - Functions
    
    /// Update all the icon views with the icons passed in.
    func updateIconViews() {
        guard let icons = icons else { return }
        guard let iconViews = iconViews else { return }
        
        for (index, view) in iconViews.enumerate() {
            if index < icons.count {
                view.image = icons[index]
            }
        }
    }
    
    
    
    
    // MARK: - View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
