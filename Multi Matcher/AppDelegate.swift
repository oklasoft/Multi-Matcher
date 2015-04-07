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
class AppDelegate: NSObject, NSApplicationDelegate, ShellWrapperDelegate {

    let mmatcherPath = NSBundle.mainBundle().pathForResource("mmatcher", ofType: "x86_64")
    var mmatcher : ShellWrapper?
    var mmatcherRunning = false

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var caseFileField: NSTextField!
    @IBOutlet weak var controlFileField: NSTextField!
    @IBOutlet weak var outputFileField: NSTextField!
    @IBOutlet weak var keyField: NSTextField!
    @IBOutlet weak var allowedMatches: NSTextField!
    @IBOutlet weak var verboseOutput: NSButton!
    @IBOutlet weak var includeHeaders: NSButton!
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
        if mmatcherRunning {
            mmatcher?.stop()
            return
        }
        mmatcherRunning = true
        
        results.string = ""
        if !checkReadyToRun() {
            results.string = "Not enough parameters"
            return
        }
        
        var args = [String]()
        if NSOnState == verboseOutput.state {
            args.append("-v")
        }
        if NSOnState == includeHeaders.state {
            args.append("-h")
        }
        if allowedMatches.integerValue > 0 {
            args.append("-m")
            args.append(String(allowedMatches.integerValue))
        }
        if "" != outputFileField.stringValue {
            args.append("-o")
            args.append(outputFileField.stringValue)
        } else {
            args.append("--out-separator")
            args.append("\t")
        }
        args.append(parseKeys(keyField.stringValue))
        args.append(caseFileField.stringValue)
        args.append(controlFileField.stringValue)

        mmatcher = ShellWrapper(path: mmatcherPath!, args: args)
        mmatcher?.delegate = self
        mmatcher?.start()
    }

    func parseKeys(k: String) -> String {
        return join(",",k.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).filter({!Swift.isEmpty($0)}))
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        allowedMatches.stringValue = "1"
        results.richText = false
        results.textContainer!.widthTracksTextView    =   false
        results.textContainer!.containerSize          =   CGSize(width: CGFloat.max, height: CGFloat.max)
        results.typingAttributes = NSDictionary(object: NSFont(name: "Menlo", size: 11)!, forKey: NSFontAttributeName)
        
        let style = NSMutableParagraphStyle()
        style.defaultTabInterval = 8
        results.defaultParagraphStyle = style
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
            keyField.stringValue != ""
    }
    
    func enableRunIfReady() {
        runButton.enabled = checkReadyToRun()
    }
    
    // ShellWrapperDelegate
    func appendStdOut(wrapper: ShellWrapper, output: String) {
//        dispatch_async(dispatch_get_main_queue()) {
//            self.results.textStorage?.appendAttributedString(NSAttributedString(string:output))
        self.results.string = self.results.string! + output
            self.results.scrollRangeToVisible(NSRange(location: countElements(self.results.string!), length: 0))
//        }
    }
    
    func appendStdErr(wrapper: ShellWrapper, err: String) {
//        dispatch_async(dispatch_get_main_queue()) {
//            self.results.textStorage?.appendAttributedString(NSAttributedString(string:err))
        self.results.string = self.results.string! + err

            self.results.scrollRangeToVisible(NSRange(location: countElements(self.results.string!), length: 0))
//        }
    }
    
    func processStarted(wrapper: ShellWrapper) {
        statusSpinner.startAnimation(self)
        runButton.title = "Stop"
        mmatcherRunning = true
    }
    
    func processFinished(wrapper: ShellWrapper, status: Int) {
        statusSpinner.stopAnimation(self)
        runButton.title = "Run"
        mmatcherRunning = false
    }

    
}

