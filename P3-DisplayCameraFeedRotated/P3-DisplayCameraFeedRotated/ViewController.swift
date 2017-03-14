//
//  ViewController.swift
//  P3-DisplayCameraFeedRotated
//
//  Created by Daniel Pink on 14/3/17.
//  Copyright © 2017 Daniel Pink. All rights reserved.
//

import Cocoa

import AVFoundation

/*
 This file holds all the code for this example. Everything is done in the ViewController object. The high level summry of what is required is as follows
 
 Select a AVCaptureDevice that represents the camera we are going to view from. From that device get an AVCaptureInputDevice and add it to our AVCaptureSession. Then ask the session for a CALayer that contains the preview of the video stream. Set that as the layer for the NSView that we have placed in the UI for viewing. Tell the session to start running.
 
 Use the NSView function rotate(byDegrees:) to perform the rotation.
 
 The code below has the details. The other steps that were required to get the project to run are listed below.
 
 IB
 - Drag a custom view out into your view controller
 - Make it fill the whole view controller
 - Set the constraints such that it fills the entire area even when it resizes.
 - Set it such that the view can't get too small
 - In the View Effects inspector, set the Core Animation Layer to be the Custom View as well as the View.
 - Link the custom view to the cameraView IBOutlet
 
 Project settings
 - Link the AVFoundation and AVKit frameworks
 
 Links
 - https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html
 - Discussions about CALayers and NSView items https://www.objc.io/issues/14-mac/appkit-for-uikit-developers/
 */

class ViewController: NSViewController {
    
    @IBOutlet weak var cameraView: NSView!
    
    let session: AVCaptureSession = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput?
    var videoDevice: AVCaptureDevice? {
        get {
            return videoDeviceInput?.device
        }
        set {
            session.beginConfiguration()
            
            // Remove the old device input from the session
            if let exisiting = videoDeviceInput {
                session.removeInput(exisiting)
                videoDeviceInput = nil
            }
            
            // Create a device input for the device and add it to the session
            if let newDevice = newValue {
                do {
                    // Check that the AVCaptureDevice can provide an AVDeviceCaptureInput object
                    let newVideoDeviceInput = try AVCaptureDeviceInput(device: newDevice)
                    
                    //
                    if(!newDevice.supportsAVCaptureSessionPreset(session.sessionPreset)) {
                        session.sessionPreset = AVCaptureSessionPresetHigh
                    }
                    session.addInput(newVideoDeviceInput)
                    videoDeviceInput = newVideoDeviceInput
                } catch {
                    print("The supplied AVCaptureDevice \(newDevice) can't provide an AVCaptureDeviceInput")
                    videoDeviceInput = nil
                }
            } else {
                print("No AVCaptureDevice provided")
                videoDeviceInput = nil
            }
            
            session.commitConfiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        // Get an AVCaptureDevice that represents a camera. The code below grabs the default camera
        guard let defaultVideoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            // Or you can select from a list of all available devices on the system.
            let foundVideoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
            let foundMuxed = AVCaptureDevice.devices(withMediaType: AVMediaTypeMuxed) as! [AVCaptureDevice]
            let videoDevices = foundVideoDevices + foundMuxed
            print("We didn't find a default video media device so we are going to crash. Could have used \(videoDevices)")
            fatalError()
        }
        
        videoDevice = defaultVideoDevice // View the setter above for the code that actually
        // sets up the AVCaptureDeviceInput for the session.
        
        let newCameraViewLayer = AVCaptureVideoPreviewLayer(session: session)!
        
        newCameraViewLayer.frame = cameraView.bounds
        newCameraViewLayer.backgroundColor = .black
        newCameraViewLayer.autoresizingMask = [.layerWidthSizable,.layerHeightSizable]
        
        cameraView.layer = newCameraViewLayer
        cameraView.wantsLayer = true
        
        // The line below rotates the video feed by 90 degrees. You can rotate it by whatever angle you like. Note that you need to have selected the checkbox for the View and CameraView options in the Core Animation Layer of the View Effects Layer for the Custom view in the Main storyboard for this to work (if you don't check the View option you get some pretty weird behaviour).
        cameraView.rotate(byDegrees: 90)
        // If you want to know what the current rotation is you can use the following.
        print(cameraView.boundsRotation)
        
        session.startRunning()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window!.title = "Rotated"
    }
    
    override func viewWillDisappear() {
        session.stopRunning()
    }
}
