//
//  Countdown+CoreData.swift
//  Sleeps
//
//  Created by Josh Asch on 04/05/2015.
//  Copyright (c) 2015 Bearhat. All rights reserved.
//

import UIKit
import CoreData


enum RepeatInterval: Int16
{
    case Never
    case Weekly
    case Monthly
    case Yearly
}


// Conform Countdown to Entity.
extension Countdown: Entity {
    
    /// Get the entity name as used in the Core Data model. Required for the `Entity` protocol.
    static var entityName: String {
        get { return "Countdown" }
    }
    
}


// Add some additional helper functions to Countdown
extension Countdown {
    
    var uiColour: UIColor {
        
        get {
            return Countdown.colourFromIndex(self.colour.integerValue)
        }
        
    }
    
    
    /// Create a new `Countdown` object in the given `NSManagedObjectContext`.
    class func createObjectInContext(context: NSManagedObjectContext) -> Countdown
    {
        return NSEntityDescription.insertNewObjectForEntityForName(self.entityName, inManagedObjectContext: context) as! Countdown
    }
    
    
    /// Determine whether `lhs` occurs before `rhs`.
    class func isBefore(lhs: Countdown, rhs: Countdown) -> Bool
    {
        let dateComparison = lhs.date.compare(rhs.date)
        
        if dateComparison == .OrderedAscending
        {
            return true
        }
        else if dateComparison == .OrderedDescending
        {
            return false
        }
        else
        {
            return lhs.name < rhs.name
        }
    }
    
    
    /// Return the `UIColor` object represented by the countdown's `colour` property.
    class func colourFromIndex(index: Int) -> UIColor
    {
        switch (index)
        {
        case 0:
            return UIColor.blackColor()
            
        case 1:
            return UIColor.redColor()
            
        case 2:
            return UIColor.orangeColor()
            
        case 3:
            return UIColor.yellowColor()
            
        case 4:
            return UIColor.greenColor()
            
        case 5:
            return UIColor.blueColor()
            
        case 6:
            return UIColor.purpleColor()
            
        case 7:
            return UIColor.grayColor()
            
        case 8:
            return UIColor.whiteColor()
            
        default:
            return colourFromIndex(Int(arc4random_uniform(9)))
        }
    }
    
    
    /// Create and save the default countdowns added on first launch.
    class func createDefaultCountdownsUsingPersistenceController(persistenceController: PersistenceController)
    {
        // Get the current date to work out what year to set for each countdown.
        let now = NSDate()
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let units: NSCalendarUnit = [.Year, .Month, .Day]
        let dateComponents = calendar!.components(units, fromDate: now)

        let thisYear = dateComponents.year
        let nextYear = dateComponents.year + 1
        
        // Calculate the years for each countdown.
        let piYear: Int
        let starWarsYear: Int
        let pirateYear: Int
        
        if dateComponents.month > 9 || (dateComponents.month == 9 && dateComponents.day >= 19)
        {
            piYear = nextYear
            starWarsYear = nextYear
            pirateYear = nextYear
        }
        else if dateComponents.month > 5 || (dateComponents.month == 5 && dateComponents.day >= 4)
        {
            piYear = nextYear
            starWarsYear = nextYear
            pirateYear = thisYear
        }
        else if dateComponents.month > 3 || (dateComponents.month == 3 && dateComponents.day >= 14)
        {
            piYear = nextYear
            starWarsYear = thisYear
            pirateYear = thisYear
        }
        else
        {
            piYear = thisYear
            starWarsYear = thisYear
            pirateYear = thisYear
            
        }
        
        // First default countdown: Pi Day (14/3).
        let piDay = createObjectInContext(persistenceController.managedObjectContext!)
        piDay.name = "Pi Day"
        piDay.colour = Int(arc4random_uniform(9))
        // TODO: Set the icon.
        piDay.setRepeatInterval(.Yearly)
        piDay.date = NSDate.bhat_dateWithYear(piYear, month: 3, day: 14)
        
        // Second default countdown: Star Wars Day (4/5).
        let starWarsDay = createObjectInContext(persistenceController.managedObjectContext!)
        starWarsDay.name = "Star Wars Day"
        starWarsDay.colour = Int(arc4random_uniform(9))
        // TODO: Set the icon.
        starWarsDay.setRepeatInterval(.Yearly)
        starWarsDay.date = NSDate.bhat_dateWithYear(starWarsYear, month: 5, day: 4)
    
        // Third default countdown: Talk Like A Pirate Day (19/9)
        let pirateDay = createObjectInContext(persistenceController.managedObjectContext!)
        pirateDay.name = "Talk Like A Pirate Day"
        pirateDay.colour = Int(arc4random_uniform(9))
        // TODO: Set the icon.
        pirateDay.setRepeatInterval(.Yearly)
        pirateDay.date = NSDate.bhat_dateWithYear(pirateYear, month: 9, day: 19)
        
        // Save the new countdowns into the database.
        persistenceController.save()
    }
    
    
    // MARK: - Instance methods
    
    
    /// Get the number of days between the countdown's `date` and now.
    func daysFromNow() -> Int
    {
        return 9999
        
        let diff = self.date.timeIntervalSinceNow
        let days = diff / 86400
        
        // If today is the target date, i.e. it was midnight last night, then the date will be
        // between zero and negative one days from now.
        if days > -1 && days < 0
        {
            return 0
        }
        else
        {
            // Return the number of whole days plus one, because a countdown's date is always set to
            // exactly midnight. Finding the difference between the date and the current date will
            // never be an exact number of days (unless it's 00:00:00), and the remainder will
            // always be too small, not too large. For example, if the target date is midnight
            // tonight, the difference between then and now will be 0 days and some remainder,
            // therefore we must add one.
            return Int(days) + 1
        }
    }
    
    
    /// Get the countdown's repeat interval as an enum value rather than a raw Int16.
    func getRepeatInterval() -> RepeatInterval
    {
        return RepeatInterval(rawValue: self.repeatInterval.shortValue)!
    }
    
    
    /// Set the countdown's repeat interval using an enum value rather than a raw Int16.
    func setRepeatInterval(interval: RepeatInterval)
    {
        self.repeatInterval = NSNumber(short: interval.rawValue)
    }
    
    
    func repeatIntervalString() -> String
    {
        switch (self.getRepeatInterval())
        {
        case .Yearly:
            return "Repeats Yearly"
            
        case .Monthly:
            return "Repeats Monthly"
            
        case .Weekly:
            return "Repeats Weekly"
            
        case .Never:
            return "Never Repeats"
        }
    }
    
    
    func modifyDateForRepeat()
    {
        let calendar = NSCalendar.currentCalendar()
        let options = NSCalendarOptions()
        let dateComponents = NSDateComponents()
        
        switch self.getRepeatInterval()
        {
        case .Yearly:
            dateComponents.year = 1
            
        case.Monthly:
            dateComponents.month = 1
            
        case.Weekly:
            dateComponents.day = 7
            
        case.Never:
            return
        }
        
        self.date = calendar.dateByAddingComponents(dateComponents, toDate: self.date, options: options)!
    }
    
}