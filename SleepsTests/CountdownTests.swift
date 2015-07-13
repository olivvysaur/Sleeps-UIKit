//
//  CountdownTests.swift
//  Sleeps
//
//  Created by Josh Asch on 13/06/2015.
//  Copyright © 2015 Bearhat. All rights reserved.
//

import XCTest
import CoreData

@testable
import Sleeps

class CountdownTests: XCTestCase {
    
    var managedObjectContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create an in-memory Core Data stack which can be used to test interaction with the
        // database, without having to actually store anything on disk.
        if let model = NSManagedObjectModel.mergedModelFromBundles([NSBundle.mainBundle()])
        {
            let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            do
            {
                try storeCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
                managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                managedObjectContext.persistentStoreCoordinator = storeCoordinator
            }
            catch
            {
                XCTFail("Failed to initialise a mock Core Data stack")
            }
        }
        else
        {
            XCTFail("Failed to initialise an object model")
        }
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    /// Check that the daysFromNow() function returns the expected value.
    func testThatDaysFromNowWorks()
    {
        let countdown = Countdown.createObjectInContext(managedObjectContext)
        
        // Create a date 7 days in the future.
        let interval = NSDate().timeIntervalSinceReferenceDate + (86400 * 7)
        let futureDate = NSDate(timeIntervalSinceReferenceDate: interval)
        
        // Set the countdown's date to the newly created date.
        countdown.date = futureDate
        
        
        XCTAssertEqual(countdown.daysFromNow(), 7, "daysFromNow() should return 7")
    }
    
    
    /// Check that daysFromNow() returns the expected zero if the countdown's date is today.
    func testThatDaysFromNowReturnsZeroForToday()
    {
        let countdown = Countdown.createObjectInContext(managedObjectContext)
        
        // Get today's date and create a new date set to midnight on the same day, month, and year.
        let interval = NSDate().timeIntervalSinceReferenceDate
        let midnightInterval = interval - (interval % 86400)
        let newDate = NSDate(timeIntervalSinceReferenceDate: midnightInterval)
        
        // Set the countdown's date to the newly created date, and check that daysFromNow() returns
        // 0 as expected.
        countdown.date = newDate
        XCTAssertEqual(countdown.daysFromNow(), 0, "daysFromNow() should return 0")
    }
    
    
    /// Check that daysFromNow() returns the expected zero if the countdown's date is today and the
    /// time component is in the past.
    func testThatDaysFromNowReturnsZeroForTodayInPast()
    {
        let countdown = Countdown.createObjectInContext(managedObjectContext)
        
        // Set the date to be one second ago. If that puts the date over the boundary, keep trying
        // until both dates occur on the same day.
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let units: NSCalendarUnit = [.Day]
        
        var nowComponents: NSDateComponents
        var dateComponents: NSDateComponents
        var date: NSDate
        
        repeat
        {
            let now = NSDate()
            nowComponents = calendar!.components(units, fromDate: now)
            date = NSDate(timeIntervalSinceNow: -1)
            dateComponents = calendar!.components(units, fromDate: date)
        }
            while dateComponents.day != nowComponents.day
        
        countdown.date = date
        XCTAssertEqual(countdown.daysFromNow(), 0)
    }
    
    
    /// Check that if a countdown is set to repeat, then calling modifyDateForRepeat() works.
    func testThatRepeatingCountdownsRepeatCorrectly()
    {
        let countdown = Countdown.createObjectInContext(managedObjectContext)
        var dateDiff: NSTimeInterval
        
        // Check that a yearly repeating countdown adds a year to its date.
        countdown.date = NSDate.bhat_dateWithYear(2015, month: 7, day: 12)
        countdown.setRepeatInterval(.Yearly)
        countdown.modifyDateForRepeat()
        dateDiff = countdown.date.timeIntervalSinceDate(NSDate.bhat_dateWithYear(2016, month: 7, day: 12))
        XCTAssertEqual(dateDiff, 0, "Date should have been moved by a year")
        
        // Check that a monthly repeating countdown adds a month to its date.
        countdown.date = NSDate.bhat_dateWithYear(2015, month: 7, day: 12)
        countdown.setRepeatInterval(.Monthly)
        countdown.modifyDateForRepeat()
        dateDiff = countdown.date.timeIntervalSinceDate(NSDate.bhat_dateWithYear(2015, month: 8, day: 12))
        XCTAssertEqual(dateDiff, 0, "Date should have been moved by a month")
        
        // Check that a weekly repeating countdown adds a week to its date.
        countdown.date = NSDate.bhat_dateWithYear(2015, month: 7, day: 12)
        countdown.setRepeatInterval(.Weekly)
        countdown.modifyDateForRepeat()
        dateDiff = countdown.date.timeIntervalSinceDate(NSDate.bhat_dateWithYear(2015, month: 7, day: 19))
        XCTAssertEqual(dateDiff, 0, "Date should have been moved by a week")
        
        // Check that non-repeating countdown doesn't modify its date.
        countdown.date = NSDate.bhat_dateWithYear(2015, month: 7, day: 12)
        countdown.setRepeatInterval(.Never)
        countdown.modifyDateForRepeat()
        dateDiff = countdown.date.timeIntervalSinceDate(NSDate.bhat_dateWithYear(2015, month: 7, day: 12))
        XCTAssertEqual(dateDiff, 0, "Date should not have moved")
    }
    
}