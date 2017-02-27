//
//  ViewController.swift
//  P1-DisplayCameraFeed
//
//  Created by Daniel Pink on 25/2/17.
//  Copyright © 2017 Daniel Pink. All rights reserved.
//

import Cocoa
import AVFoundation

// IB
// - Drag a custom view out into your view controller
// - Make it fill the whole view controller
// - Set the constraints such that it fills the entire area even when it resizes.
// - Set it such that the view can't get too small
// - In the View Effects inspector, set the Core Animation Layer to be the Custom View rather than the View.
// - Link the custom view to the cameraView IBOutlet
// Now using a subclass of NSView called CameraPreview. It is at the bottom of this file. This is so that I can get access to the CALayer backing the view reliably. Previously I was only getting access to it 50% of the time. The objc.io link below gives details.

// Project settings
// - Link the AVFoundation and AVKit frameworks

// Links
// - https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html
// - Discussions about CALayers and NSView items https://www.objc.io/issues/14-mac/appkit-for-uikit-developers/

class ViewController: NSViewController {

    @IBOutlet weak var cameraView: NSView!
    
    // Still and Video Media Capture
    // Recording input from cameras and microphones is managed by a capture session. A capture session coordinates the flow of data from input devices to outputs such as a movie file. You can configure multiple inputs and outputs for a single session, even when the session is running. You send messages to the session to start and stop data flow.
    
    let session: AVCaptureSession = AVCaptureSession()
    var videoDeviceInput: AVCaptureDeviceInput?
    var videoDevice: AVCaptureDevice? {
        get {
            return videoDeviceInput?.device
        }
        set {
            session.beginConfiguration()
            if let vdi = videoDeviceInput {
                // Remove the old device input from the session
                session.removeInput(vdi)
                videoDeviceInput = nil
            }
            
            // Create a device input for the device and add it to the session
            if let existing = newValue {
                do {
                    let newVideoDeviceInput = try AVCaptureDeviceInput(device: existing)
                    if(!existing.supportsAVCaptureSessionPreset(session.sessionPreset)) {
                        session.sessionPreset = AVCaptureSessionPresetHigh
                    }
                    session.addInput(newVideoDeviceInput)
                    videoDeviceInput = newVideoDeviceInput
                } catch {
                    print("I don't know what I'm doing")
                }
            } else {
                videoDeviceInput = nil
            }
            session.commitConfiguration()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Get an AVCaptureDevice that represents a camera. You can use the following to 
        // get a list of all available on the system.
        let foundVideoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        let foundMuxed = AVCaptureDevice.devices(withMediaType: AVMediaTypeMuxed) as! [AVCaptureDevice]
        let videoDevices = foundVideoDevices + foundMuxed
        
        // Or you can use the following code to grab the default camera
        guard let vd = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            print("We didn't find a default video media device so we are going to crash")
            fatalError()
        }
        
        videoDevice = vd
        
        // Using a layer-hosting view to display the preview from the camera. 
        // First up get a Video Preview layer from the session. Set its bounds,
        // background and auto-resizing behaviour.
        let newCameraViewLayer = AVCaptureVideoPreviewLayer(session: session)!
        
        newCameraViewLayer.frame = cameraView.bounds
        newCameraViewLayer.backgroundColor = .black
        newCameraViewLayer.autoresizingMask = [.layerWidthSizable,.layerHeightSizable]
        
        cameraView.layer = newCameraViewLayer
        cameraView.wantsLayer = true
        
        session.startRunning()
    }
    
    override func viewWillDisappear() {
        session.stopRunning()
    }
}
