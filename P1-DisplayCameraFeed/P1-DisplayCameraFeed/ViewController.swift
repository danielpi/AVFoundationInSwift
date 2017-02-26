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

// Project settings
// - Link the AVFoundation and AVKit frameworks

class ViewController: NSViewController {

    @IBOutlet weak var cameraView: NSView!
    
    let session: AVCaptureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
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
        if let vd = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) {
            videoDevice = vd
        } else {
            if let vd = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeMuxed) {
                videoDevice = vd
            }
        }
        
        
        
        
        if let cameraViewLayer = cameraView.layer {
            cameraViewLayer.backgroundColor = CGColor.black
            previewLayer = createNewCameraViewLayer(session: session, cameraViewLayer: cameraViewLayer)!
            session.startRunning()
        }
        
        
    }
    
    override func viewWillDisappear() {
        session.stopRunning()
    }

    func createNewCameraViewLayer(session: AVCaptureSession, cameraViewLayer: CALayer) -> AVCaptureVideoPreviewLayer? {
        if let newCameraViewLayer = AVCaptureVideoPreviewLayer(session: session) {
            newCameraViewLayer.frame = cameraViewLayer.bounds
            let autoresizingMask: CAAutoresizingMask = [.layerWidthSizable,.layerHeightSizable]
            newCameraViewLayer.autoresizingMask = autoresizingMask
            cameraViewLayer.addSublayer(newCameraViewLayer)
            
            return newCameraViewLayer
        } else {
            return nil
        }
    }
}

