//
//  CountdownTableViewController.swift
//  Sleeps
//
//  Created by Josh Asch on 21/07/2015.
//  Copyright © 2015 Bearhat. All rights reserved.
//

import UIKit

class CountdownTableViewController: UITableViewController {
    
    /// Persistence controller passed in from the AppDelegate at launch.
    var persistenceController: PersistenceController?
    
    /// Array of Countdown objects from the database, used as the data for the table view.
    var countdowns = [Countdown]() {
        
        didSet {
            // Whenever our array of countdowns changes, reload the table view data, as long as an
            // edit isn't in progress.
            if !modifying {
                tableView?.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
            }
        }
        
    }
    
    /// Is a countdown currently being deleted?
    var modifying = false
    
    /// Which countdown was tapped?
    var selectedCountdown: Int?
    
    /// Has a countdown been deleted on the edit screen?
    var deletedCountdown = false
    
    /// Timer used to refresh data at midnight.
    var timer: NSTimer?
    
    
    /// Called when the new countdown button is tapped. Creates a new countdown object with
    /// placeholder values.
    @IBAction func newTapped(sender: UIBarButtonItem) {
        if let persistenceController = persistenceController {
            if let objectContext = persistenceController.managedObjectContext {
                let newCountdown = Countdown.createObjectInContext(objectContext)
                newCountdown.icon = 0
                newCountdown.colour = 0
                newCountdown.name = ""
                newCountdown.date = NSDate.midnightOnDate(NSDate())
                newCountdown.setRepeatInterval(.Never)
                
                // Add the new countdown to the list, save the object context, and then return.
                modifying = true
                countdowns.insert(newCountdown, atIndex: 0)
                persistenceController.save()
                modifying = false
                
                // Automatically enter the edit view, because there's no point having a countdown
                // that just says "New Countdown".
                performSegueWithIdentifier(kNewCountdownSegueIdentifier, sender: self)
                
                // Return so that the error condition code is not reached.
                return
            }
        }
        
        // If we reach this point, the database is catastrophically broken.
        NSLog("No managed object context available to create new countdown")
    }
    
    
    
    /// Set a timer to fire at midnight to refresh the data.
    func refreshViewAtMidnight() {
        // The date used here is actually 00:00:01, because NSTimer has a resolution of 50-100ms.
        // If exactly 00:00:00 is used, there's a chance it will be called at 23:59:59, and the data
        // won't change.
        let fireDate = NSDate.startOfDayTomorrow().dateByAddingTimeInterval(1)
        timer = NSTimer(fireDate: fireDate, interval: 0, target: self, selector: "reloadData", userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    
    
    
    /// Cancel the timer set for midnight.
    func cancelTimer() {
        timer?.invalidate()
    }
    
    
    
    // MARK: - Database
    
    /// Get all the countdowns from the persistence controller and store them in the countdowns
    /// array. This function only does anything if the persistence controller exists.
    func reloadData() {
        print("Reloaded! \(NSDate())")
        // Use FetchRequestController to get all the countdowns from the database. If no error
        // occurs, set `self.countdowns` to the returned results, which will trigger the collection
        // view to refresh itself.
        if let persistenceController = persistenceController {
            if let fetchedCountdowns = FetchRequestController.getAllObjectsOfType(Countdown.self, fromPersistenceController: persistenceController) {
                var sortedCountdowns = fetchedCountdowns
                sortedCountdowns.sortInPlace(Countdown.isBefore)
                self.countdowns = sortedCountdowns
            }
        }
    }
    
    
    /// Delete the countdown at `index` in the array of countdowns.
    func deleteCountdownAtIndex(index: Int) {
        if let persistenceController = persistenceController {
            if let objectContext = persistenceController.managedObjectContext {
                modifying = true
                objectContext.deleteObject(countdowns[index])
                countdowns.removeAtIndex(index)
                tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
                persistenceController.save()
                modifying = false
            }
        }
    }
    
    
    /// Update past countdowns by either updating their date if they repeat, or deleting them if
    /// they don't.
    func updatePastCountdowns() {
        var toDelete = [Int]()
        var update = false
        
        modifying = true
        
        for (index, countdown) in countdowns.enumerate() {
            if countdown.daysFromNow() < 0 {
                if countdown.getRepeatInterval() == .Never {
                    toDelete.append(index)
                    update = true
                }
                else {
                    countdown.modifyDateForRepeat()
                    update = true
                }
            }
        }
        
        // Delete any countdowns we found that had a repeat interval of .Never.
        if let objectContext = persistenceController?.managedObjectContext {
            for index in toDelete {
                objectContext.deleteObject(countdowns[index])
                countdowns.removeAtIndex(index)
            }
            
            if toDelete.count > 0 {
                let indexPaths = toDelete.map { index in return NSIndexPath(forRow: index, inSection: 0) }
                tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
            
            if update {
                persistenceController?.save()
            }
        }
        
        reloadData()
        
        modifying = false
    }
    
    
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // If a countdown was "deleted" on the edit view, delete it now.
        if deletedCountdown {
            if let selectedCountdown = selectedCountdown {
                deleteCountdownAtIndex(selectedCountdown)
            }
        }
        // Otherwise, just load the latest data.
        else {
            reloadData()
            updatePastCountdowns()
        }
        
        deletedCountdown = false
        selectedCountdown = nil
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    // MARK: - Navigation controller
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Choose what to do based on the segue being performed.
        if segue.identifier! == kNewCountdownSegueIdentifier {
            // The New button was tapped. Assume that the new countdown was added at the front of
            // the array of countdowns.
            let editViewController = segue.destinationViewController as! EditTableViewController
            editViewController.countdown = countdowns[0]
            editViewController.persistenceController = persistenceController
            
            // The countdown should be deleted if the edit screen exits early.
            editViewController.deleteOnExit = true
        }
        else if segue.identifier == kEditCountdownSegueIdentifier {
            // Note which countdown was tapped.
            selectedCountdown = tableView.indexPathForSelectedRow?.row
            
            // Get the countdown object from the table cell and pass it to the edit view.
            let cell = sender as! CountdownTableCell
            let editViewController = segue.destinationViewController as! EditTableViewController
            editViewController.countdown = cell.countdown
            editViewController.persistenceController = persistenceController
            
            // This is an existing countdown, so don't delete it on exit.
            editViewController.deleteOnExit = false
        }
    }
    
    
    @IBAction func unwindToViewController (sender: UIStoryboardSegue) {
        // There's a bug in iOS which means that using an exit segue doesn't automatically exit from
        // the presented view controller, so dismiss it manually.
        dismissViewControllerAnimated(true, completion: nil)
    }

    
    
    
    
    // MARK: - Table view

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // There is always only one section.
        return 1
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // There is one row for each countdown.
        return countdowns.count
    }
    

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Get a countdown cell.
        let cell = tableView.dequeueReusableCellWithIdentifier(kCountdownTableCellIdentifier, forIndexPath: indexPath) as! CountdownTableCell

        // Give the cell a countdown to display.
        cell.countdown = countdowns[indexPath.row]

        return cell
    }
    
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the countdown from the row being deleted.
            deleteCountdownAtIndex(indexPath.row)
        }
    }

}
