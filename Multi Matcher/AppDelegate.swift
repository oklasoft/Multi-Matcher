//
//  AppDelegate.swift
//  Multi Matcher
//
//  Created by Stuart Glenn on 2015-03-27.
//  Copyright (c) 2015 Oklahoma Medical Research Foundation. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var caseFileField: NSTextField!
    @IBOutlet weak var controlFileField: NSTextField!
    @IBOutlet weak var outputFileField: NSTextField!
    @IBOutlet weak var keyField: NSTextField!
    @IBOutlet var results: NSTextView!
    @IBOutlet weak var statusSpinner: NSProgressIndicator!
    @IBOutlet weak var runButton: NSButton!


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    

    @IBAction func doSelectCases(sender: AnyObject) {
        selectFileDialog("Choose", message: "Select CSV file containing cases", target: caseFileField)
    }
    
    @IBAction func doSelectControls(sender: AnyObject) {
        selectFileDialog("Choose", message: "Select CSV file containing controls", target: controlFileField)
    }
    
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

    func checkReadyToRun() -> Bool {
        return caseFileField.stringValue != "" && controlFileField.stringValue != "" &&
            outputFileField.stringValue != "" && keyField.stringValue != ""
    }
    
    func enableRunIfReady() {
        runButton.enabled = checkReadyToRun()
    }
    
    @IBAction func runMatch(sender: AnyObject) {
        results.string = ""
        if !checkReadyToRun() {
            results.string = "Not enough parametersgopkg.in/alecthomas/kingpin.v1"
            return
        }
        statusSpinner.startAnimation(self)
        runButton.title = "Stop"
        results.string = "Running..."
        statusSpinner.stopAnimation(self)
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        enableRunIfReady()
    }
}

