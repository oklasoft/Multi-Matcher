//
//  AppDelegate.swift
//  Multi Matcher
//
//  Created by Stuart Glenn on 2015-03-27.
//  Copyright (c) 2015 Stuart Glenn, Oklahoma Medical Research Foundation. 
//  All rights reserved.
//  Use of this source code is governed by a 3 clause BSD style license.
//  Full details can be found in the LICENSE file distributed with this software
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let mmatcherPath = NSBundle.mainBundle().pathForResource("mmatcher", ofType: "x86_64")

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var caseFileField: NSTextField!
    @IBOutlet weak var controlFileField: NSTextField!
    @IBOutlet weak var outputFileField: NSTextField!
    @IBOutlet weak var keyField: NSTextField!
    @IBOutlet var results: NSTextView!
    @IBOutlet weak var statusSpinner: NSProgressIndicator!
    @IBOutlet weak var runButton: NSButton!

    //Select an input file for the A file (cases)
    @IBAction func doSelectCases(sender: AnyObject) {
        selectFileDialog("Choose", message: "Select CSV file containing cases", target: caseFileField)
    }
    
    //Select an input for the B file (controls)
    @IBAction func doSelectControls(sender: AnyObject) {
        selectFileDialog("Choose", message: "Select CSV file containing controls", target: controlFileField)
    }
    
    //Select save destination
    @IBAction func doSelectOutput(sender: AnyObject) {
        var panel = NSSavePanel()
        panel.message = "Select destination file to save matches"
        panel.allowedFileTypes = ["csv"]
        panel.beginSheetModalForWindow(window) {
            (result : Int) in
            if NSFileHandlingPanelOKButton == result {
                var theURL = panel.URL
                self.outputFileField.stringValue = theURL!.path!
                self.enableRunIfReady()
            }
        }
        
    }
    
    //Fire of the actual mmatcher run
    @IBAction func runMatch(sender: AnyObject) {
        results.string = ""
        if !checkReadyToRun() {
            results.string = "Not enough parametersgopkg.in/alecthomas/kingpin.v1"
            return
        }
        statusSpinner.startAnimation(self)
        runButton.title = "Stop"
        results.string = "Running... \(mmatcherPath!)"
        statusSpinner.stopAnimation(self)
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
    }

    func applicationWillTerminate(aNotification: NSNotification) {
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    //Delegation for input text fields to enable/disable Run button
    override func controlTextDidChange(obj: NSNotification) {
        enableRunIfReady()
    }
    
    //Prompt for a CSV file
    func selectFileDialog(prompt: String, message: String, target: NSTextField) {
        var panel = NSOpenPanel()
        
        panel.prompt = prompt
        panel.message = message
        panel.allowedFileTypes = ["csv"]
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModalForWindow(window) {
            (result : Int) in
            if NSFileHandlingPanelOKButton == result {
                var theURL = panel.URL
                target.stringValue = theURL!.path!
                self.enableRunIfReady()
            }
        }
    }

    //We can run if there are two input files, a selection of column & an output filename
    func checkReadyToRun() -> Bool {
        return caseFileField.stringValue != "" && controlFileField.stringValue != "" &&
            outputFileField.stringValue != "" && keyField.stringValue != ""
    }
    
    func enableRunIfReady() {
        runButton.enabled = checkReadyToRun()
    }
    
}

