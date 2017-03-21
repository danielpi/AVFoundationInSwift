//
//  ViewController.swift
//  P4-CaptureImageWithVideoPreviewRunning
//
//  Created by Daniel Pink on 14/3/17.
//  Copyright © 2017 Daniel Pink. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    @IBOutlet weak var cameraView: NSView!
    @IBOutlet weak var imageView: NSImageView!
    
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
        
        newCameraViewLayer.connection.automaticallyAdjustsVideoMirroring = false
        newCameraViewLayer.connection.isVideoMirrored = true
        
        newCameraViewLayer.frame = cameraView.bounds
        newCameraViewLayer.backgroundColor = .black
        newCameraViewLayer.autoresizingMask = [.layerWidthSizable,.layerHeightSizable]
        
        cameraView.layer = newCameraViewLayer
        cameraView.wantsLayer = true
        
        let when = DispatchTime.now() + 1.0
        DispatchQueue.main.asyncAfter(deadline: when) {
            self.captureImage()
        }
        
        session.startRunning()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window!.title = "Mirrored"
    }
    
    override func viewWillDisappear() {
        session.stopRunning()
    }
    
    func captureImage() {
        
        /*
         AVCaptureSession *captureSession = <#Get a capture session#>;
         AVCaptureMovieFileOutput *movieOutput = <#Create and configure a movie output#>;
         if ([captureSession canAddOutput:movieOutput]) {
            [captureSession addOutput:movieOutput];
         }
         else {
            // Handle the failure.
         }

        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG};
        [stillImageOutput setOutputSettings:outputSettings];
         
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in stillImageOutput.connections) {
            for (AVCaptureInputPort *port in [connection inputPorts]) {
                if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection) { break; }
        }
 
        [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
            ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
            CFDictionaryRef exifAttachments =
            CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
            if (exifAttachments) {
            // Do something with the attachments.
            }
            // Continue as appropriate.
            }];
        */
        /*session.beginConfiguration()
        
        let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
        let outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        stillImageOutput.outputSettings = outputSettings
        
        session.addOutput(stillImageOutput)
        session.commitConfiguration()
        
        var videoConnection: AVCaptureConnection? = nil
        for connection in stillImageOutput.connections {
            for port in (connection as! AVCaptureConnection).inputPorts {
                if (port as! AVCaptureInputPort).mediaType == AVMediaTypeVideo {
                    videoConnection = (connection as! AVCaptureConnection)
                    break
                }
            }
            if (videoConnection != nil) {
                break
            }
        }
        
        print(videoConnection)
        */
        session.beginConfiguration()
        let stillCameraOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
        
        session.addOutput(stillCameraOutput)
        session.commitConfiguration()
        let connection = stillCameraOutput.connection(withMediaType: AVMediaTypeVideo)
        
        print("Position:\(videoDevice?.position)")
        print("Manufacturer:\(videoDevice?.manufacturer)")
        print("Exposure Mode:\(videoDevice?.exposureMode)")
        print("Focus Mode:\(videoDevice?.focusMode)")
        
        stillCameraOutput.captureStillImageAsynchronously(from: connection) { (sampleBuffer, error) -> Void in
            //print(sampleBuffer)
            let jpeg: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) as NSData
            //print(jpeg)
            let image: NSImage = NSImage(data: jpeg as Data)!
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
        
    }
}

