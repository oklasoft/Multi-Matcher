//
//  ShellWrapper.swift
//  Multi Matcher
//
//  Created by Stuart Glenn on 2015-04-03.
//  Copyright (c) 2015 Stuart Glenn, Oklahoma Medical Research Foundation.
//  All rights reserved.
//  Use of this source code is governed by a 3 clause BSD style license.
//  Full details can be found in the LICENSE file distributed with this software
//

import Foundation

protocol ShellWrapperDelegate {
    func appendStdOut(wrapper: ShellWrapper, output: String)
    func appendStdErr(wrapper: ShellWrapper, err: String)
    func processStarted(wrapper: ShellWrapper)
    func processFinished(wrapper: ShellWrapper, status: Int)
}

class ShellWrapper : NSObject {
    
    enum OutputType {
        case StdOut
        case StdErr
    }
    
    var task: NSTask?
    var delegate: ShellWrapperDelegate?
    var path : String?
    var args : [String]?
    
    var stdout : NSFileHandle?
    var stdoutEmpty = false
    
    var stderr : NSFileHandle?
    var stderrEmpty  = false
    
    var taskTerminated = false
    
    convenience override init() {
        self.init(path:"",args:[])
    }
    
    init(path: String, args: [String]) {
        super.init()
        self.path = path
        self.args = args
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    func start() {
        delegate?.processStarted(self)
        task = NSTask()
        task?.launchPath = self.path!
        task?.arguments = self.args!
        
        task?.standardOutput = NSPipe()
        stdout = task?.standardOutput.fileHandleForReading
        
        task?.standardError = NSPipe()
        stderr = task?.standardError.fileHandleForReading
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataArrived:", name: NSFileHandleReadCompletionNotification,
            object: stdout)
        stdoutEmpty = false
        stdout?.readInBackgroundAndNotify()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataArrived:", name: NSFileHandleReadCompletionNotification,
            object: stderr)
        stderrEmpty = true
        stderr?.readInBackgroundAndNotify()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "taskDidTerminate:", name: NSTaskDidTerminateNotification,
            object: task)
        
        taskTerminated = false
        task?.launch()
    }
    
    func stop() {
        task?.terminate()
    }
    
    func cleanup() {
        var status = -1
        if taskTerminated {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            var data : NSData?
            for data = stdout?.availableData; data?.length > 0; data = stdout?.availableData {
                sendOutput(data!, destination: OutputType.StdOut)
            }
            for data = stderr?.availableData; data?.length > 0; data = stderr?.availableData {
                sendOutput(data!, destination: OutputType.StdOut)
            }
            status = Int(task!.terminationStatus)
        }
        delegate?.processFinished(self, status: status)
        delegate = nil
    }
    
    func sendOutput(data: NSData, destination: OutputType) {
        var msg = NSString(data: data, encoding: NSUTF8StringEncoding)
        switch destination {
        case .StdErr:
            delegate?.appendStdErr(self, err: msg! as String)
        case .StdOut:
            delegate?.appendStdOut(self, output: msg! as String)
        }
    }
    
    func dataArrived(n: NSNotification) {
        let obj = n.object as! NSFileHandle
        let data = n.userInfo!["NSFileHandleNotificationDataItem"] as! NSData
        if data.length > 0 {
            if obj == stdout {
                sendOutput(data, destination: OutputType.StdOut)
                stdoutEmpty = false
            } else if obj == stderr {
                sendOutput(data, destination: OutputType.StdErr)
                stderrEmpty = false
            }
            obj.readInBackgroundAndNotify()
        } else {
            if obj == stdout {
                stdoutEmpty = true
            } else if obj == stderr {
                stderrEmpty = true
            }
            if stdoutEmpty && stderrEmpty && taskTerminated {
                cleanup()
            }
        }
    }
    
    func taskDidTerminate(n: NSNotification) {
        if taskTerminated {
            return
        }
        taskTerminated = true
        if stdoutEmpty && stderrEmpty {
            cleanup()
        }
    }
}