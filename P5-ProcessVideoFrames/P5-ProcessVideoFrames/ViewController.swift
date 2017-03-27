//
//  ViewController.swift
//  P1-DisplayCameraFeed
//
//  Created by Daniel Pink on 25/2/17.
//  Copyright © 2017 Daniel Pink. All rights reserved.
//

import Cocoa
import AVFoundation

/*
 This file holds all the code for this example. Everything is done in the ViewController object. The high level summry of what is required is as follows
 
 Select a AVCaptureDevice that represents the camera we are going to view from. From that device get an AVCaptureInputDevice and add it to our AVCaptureSession. Then ask the session for a CALayer that contains the preview of the video stream. Set that as the layer for the NSView that we have placed in the UI for viewing. Tell the session to start running.
 
 The code below has the details. The other steps that were required to get the project to run are listed below.
 
 IB
 - Drag a custom view out into your view controller
 - Make it fill the whole view controller
 - Set the constraints such that it fills the entire area even when it resizes.
 - Set it such that the view can't get too small
 - In the View Effects inspector, set the Core Animation Layer to be the Custom View rather than the View.
 - Link the custom view to the cameraView IBOutlet
 
 Project settings
 - Link the AVFoundation and AVKit frameworks
 
 Links
 - https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/00_Introduction.html
 - Discussions about CALayers and NSView items https://www.objc.io/issues/14-mac/appkit-for-uikit-developers/
 */

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: NSView!
    @IBOutlet weak var imageView: NSImageView!
    
    // Still and Video Media Capture
    // Recording input from cameras and microphones is managed by a capture session. A capture session coordinates the flow of data from input devices to outputs such as a movie file. You can configure multiple inputs and outputs for a single session, even when the session is running. You send messages to the session to start and stop data flow.
    
    // We need to ask the system for what AVCaptureDevices there are available. Select one. Grab its
    // AVCaptureDeviceInput and give it to the session object (after removing the previous one).
    
    let session: AVCaptureSession = AVCaptureSession()
    var firstTimeStamp: CMTime?
    var videoDeviceInput: AVCaptureDeviceInput?
    var videoDeviceOutput: AVCaptureVideoDataOutput?
    var videoDevice: AVCaptureDevice? {
        get {
            return videoDeviceInput?.device
        }
        set {
            session.beginConfiguration()
            firstTimeStamp = nil
            
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
            
            
            // Remove the old device input from the session
            if let exisiting = videoDeviceOutput {
                session.removeOutput(exisiting)
                videoDeviceOutput = nil
            }
            // Create a new videoDataOutput
            videoDeviceOutput = AVCaptureVideoDataOutput()
            
            let availablePixelFormats: Array<OSTypedEnum> = videoDeviceOutput!.availableVideoCVPixelFormatTypedEnums
            if availablePixelFormats.contains(.ARGB32) {
                let newSettings: [AnyHashable: Any]! = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: OSTypedEnum.ARGB32.rawValue, AnyHashable("AVVideoScalingModeKey"): AVVideoScalingModeFit]
                videoDeviceOutput?.videoSettings = newSettings
                
                videoDeviceOutput?.alwaysDiscardsLateVideoFrames = true
                let videoDataOutputQueue = DispatchQueue(label: "VideoDataoutputQueue")
                videoDeviceOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
                
                if session.canAddOutput(videoDeviceOutput) {
                    session.addOutput(videoDeviceOutput)
                }
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
        
        videoDevice = defaultVideoDevice
        let newCameraViewLayer = AVCaptureVideoPreviewLayer(session: session)!
        
        newCameraViewLayer.frame = cameraView.bounds
        newCameraViewLayer.backgroundColor = .black
        newCameraViewLayer.autoresizingMask = [.layerWidthSizable,.layerHeightSizable]
        
        cameraView.layer = newCameraViewLayer
        cameraView.wantsLayer = true
        
        session.startRunning()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window!.title = "Video Preview"
    }
    
    override func viewWillDisappear() {
        session.stopRunning()
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        // https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/06_MediaRepresentations.html#//apple_ref/doc/uid/TP40010188-CH2-SW16

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let decodeTime = CMSampleBufferGetDecodeTimeStamp(sampleBuffer)
        
        if firstTimeStamp == nil {
            firstTimeStamp = presentationTime
        }
        
        let timeSinceVideoLaunch = CMTimeSubtract(presentationTime, firstTimeStamp!)
        let timeIntervalSinceVideoLaunch = TimeInterval(Double(timeSinceVideoLaunch.value) / Double(timeSinceVideoLaunch.timescale))
        print(timeIntervalSinceVideoLaunch)
        
        let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    
    func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> NSImage {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        // Create a device-dependent RGB color space
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()

        // Create a bitmap graphics context with the sample buffer data
        let context: CGContext = CGContext(data: baseAddress,
                                           width: width,
                                           height: height,
                                           bitsPerComponent: 8,
                                           bytesPerRow: bytesPerRow,
                                           space: colorSpace,
                                           bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage: CGImage = context.makeImage()!
        
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue:0))
        
        // Create an image object from the Quartz image
        let image: NSImage = NSImage(cgImage: quartzImage, size: NSZeroSize)
        
        return(image)
    }
}


func allPixelFormats() {
    let pixelFormatDescriptionsArray: CFArray = CVPixelFormatDescriptionArrayCreateWithAllPixelFormatTypes(nil)!
    let pixelFormatDescriptions: Array<OSType> = pixelFormatDescriptionsArray as! Array<OSType>
    
    print("Core Video Supported Pixel Format Types: ")
    for format in pixelFormatDescriptions {
        
        if format <= 0x28 {
            print("Core Video Pixel Format Type: \(format)")
        } else {
            let characterOne = Character(UnicodeScalar(shiftMask(format, n: 24)))
            let characterTwo = Character(UnicodeScalar(shiftMask(format, n: 16)))
            let characterThree = Character(UnicodeScalar(shiftMask(format, n: 8)))
            let characterFour = Character(UnicodeScalar(shiftMask(format, n: 0)))
            print("Core Video Pixel Format Type (FourCC): \(characterOne)\(characterTwo)\(characterThree)\(characterFour)")
        }
    }
}

func shiftMask(_ input: UInt32, n: UInt32) -> UInt8 {
    let shift: UInt32 = input >> n
    let result: UInt8 = UInt8(shift & 0xFF)
    return result
}

extension AVCaptureVideoDataOutput {
    var availableVideoCVPixelFormatTypedEnums: [OSTypedEnum] {
        let availablePixelFormatDescriptions: Array<OSType> = self.availableVideoCVPixelFormatTypes as! Array<OSType>
        let availablePixelFormats: Array<OSTypedEnum> = availablePixelFormatDescriptions.map { OSTypedEnum(rawValue: $0)! }
        return availablePixelFormats
    }
}

enum OSTypedEnum: OSType {
    case monochrome1 = 1
    case indexed2 = 2
    case indexed4 = 4
    case indexed8 = 8
    case indexedGray_WhiteIsZero1 = 33
    case indexedGray_WhiteIsZero2 = 34
    case indexedGray_WhiteIsZero4 = 36
    case indexedGray_WhiteIsZero8 = 40
    case BE16BE555 = 16
    case LE16LE555 = 1278555445
    case LE16LE5551 = 892679473
    case BE16BE565 = 1110783541
    case LE16LE565 = 1278555701
    case RGB24 = 24
    case BGR24 = 842285639
    case ARGB32 = 32
    case BGRA32 = 1111970369
    case ABGR32 = 1094862674
    case RGBA32 = 1380401729
    case ARGB64 = 1647719521
    case RGB48 = 1647589490
    case alphaGray32 = 1647522401
    case gray16 = 1647392359
    case RGB30 = 1378955371
    case YpCbCr8_422 = 846624121
    case YpCbCrA8_4444 = 1983131704
    case YpCbCrA8R_4444 = 1916022840
    case AYpCbCr8_4444 = 2033463352
    case AYpCbCr16_4444 = 2033463606
    case YpCbCr8_444 = 1983066168
    case YpCbCr16_422 = 1983000886
    case YpCbCr10_422 = 1983000880
    case YpCbCr10_444 = 1983131952
    case YpCbCr8Planar_420 = 2033463856
    case YpCbCr8PlanarFullRange_420 = 1714696752
    case YpCbCr_4A_8BiPlanar_422 = 1630697081
    case YpCbCr8BiPlanarVideoRange_420 = 875704438
    case YpCbCr8BiPlanarFullRange_420 = 875704422
    case YpCbCr8_yuvs_422 = 2037741171
    case YpCbCr8FullRange_422 = 2037741158
    case oneComponent8 = 1278226488
    case twoComponent8 = 843264056
    case RGBLEPackedWideGamut30 = 1999843442
    case oneComponent16Half = 1278226536
    case oneComponent32Float = 1278226534
    case twoComponent16Half = 843264104
    case twoComponent32Float = 843264102
    case RGBAHalf64 = 1380411457
    case RGBAFloat128 = 1380410945
    case bayer_GRBG14 = 1735549492
    case bayer_RGGB14 = 1919379252
    case bayer_BGGR14 = 1650943796
    case bayer_GBRG14 = 1734505012
    
    var typeKey: String {
        switch self {
        case .monochrome1:
            return "kCVPixelFormatType_1Monochrome"
        case .indexed2:
            return "kCVPixelFormatType_2Indexed"
        case .indexed4:
            return "kCVPixelFormatType_4Indexed"
        case .indexed8:
            return "kCVPixelFormatType_8Indexed"
        case .indexedGray_WhiteIsZero1:
            return "kCVPixelFormatType_1IndexedGray_WhiteIsZero"
        case .indexedGray_WhiteIsZero2:
            return "kCVPixelFormatType_2IndexedGray_WhiteIsZero"
        case .indexedGray_WhiteIsZero4:
            return "kCVPixelFormatType_4IndexedGray_WhiteIsZero"
        case .indexedGray_WhiteIsZero8:
            return "kCVPixelFormatType_8IndexedGray_WhiteIsZero"
        case .BE16BE555:
            return "kCVPixelFormatType_16BE555"
        case .LE16LE555:
            return "kCVPixelFormatType_16LE555"
        case .LE16LE5551:
            return "kCVPixelFormatType_16LE5551"
        case .BE16BE565:
            return "kCVPixelFormatType_16BE565"
        case .LE16LE565:
            return "kCVPixelFormatType_16LE565"
        case .RGB24:
            return "kCVPixelFormatType_24RGB"
        case .BGR24:
            return "kCVPixelFormatType_24BGR"
        case .ARGB32:
            return "kCVPixelFormatType_32ARGB"
        case .BGRA32:
            return "kCVPixelFormatType_32BGRA"
        case .ABGR32:
            return "kCVPixelFormatType_32ABGR"
        case .RGBA32:
            return "kCVPixelFormatType_32RGBA"
        case .ARGB64:
            return "kCVPixelFormatType_64ARGB"
        case .RGB48:
            return "kCVPixelFormatType_48RGB"
        case .alphaGray32:
            return "kCVPixelFormatType_32AlphaGray"
        case .gray16:
            return "kCVPixelFormatType_16Gray"
        case .RGB30:
            return "kCVPixelFormatType_30RGB"
        case .YpCbCr8_422:
            return "kCVPixelFormatType_422YpCbCr8"
        case .YpCbCrA8_4444:
            return "kCVPixelFormatType_4444YpCbCrA8"
        case .YpCbCrA8R_4444:
            return "kCVPixelFormatType_4444YpCbCrA8R"
        case .AYpCbCr8_4444:
            return "kCVPixelFormatType_4444AYpCbCr8"
        case .AYpCbCr16_4444:
            return "kCVPixelFormatType_4444AYpCbCr16"
        case .YpCbCr8_444:
            return "kCVPixelFormatType_444YpCbCr8"
        case .YpCbCr16_422:
            return "kCVPixelFormatType_422YpCbCr16"
        case .YpCbCr10_422:
            return "kCVPixelFormatType_422YpCbCr10"
        case .YpCbCr10_444:
            return "kCVPixelFormatType_444YpCbCr10"
        case .YpCbCr8Planar_420:
            return "kCVPixelFormatType_420YpCbCr8Planar"
        case .YpCbCr8PlanarFullRange_420:
            return "kCVPixelFormatType_420YpCbCr8PlanarFullRange"
        case .YpCbCr_4A_8BiPlanar_422:
            return "kCVPixelFormatType_422YpCbCr_4A_8BiPlanar"
        case .YpCbCr8BiPlanarVideoRange_420:
            return "kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange"
        case .YpCbCr8BiPlanarFullRange_420:
            return "kCVPixelFormatType_420YpCbCr8BiPlanarFullRange"
        case .YpCbCr8_yuvs_422:
            return "kCVPixelFormatType_422YpCbCr8_yuvs"
        case .YpCbCr8FullRange_422:
            return "kCVPixelFormatType_422YpCbCr8FullRange"
        case .oneComponent8:
            return "kCVPixelFormatType_OneComponent8"
        case .twoComponent8:
            return "kCVPixelFormatType_TwoComponent8"
        case .RGBLEPackedWideGamut30:
            return "kCVPixelFormatType_30RGBLEPackedWideGamut"
        case .oneComponent16Half:
            return "kCVPixelFormatType_OneComponent16Half"
        case .oneComponent32Float:
            return "kCVPixelFormatType_OneComponent32Float"
        case .twoComponent16Half:
            return "kCVPixelFormatType_TwoComponent16Half"
        case .twoComponent32Float:
            return "kCVPixelFormatType_TwoComponent32Float"
        case .RGBAHalf64:
            return "kCVPixelFormatType_64RGBAHalf"
        case .RGBAFloat128:
            return "kCVPixelFormatType_128RGBAFloat"
        case .bayer_GRBG14:
            return "kCVPixelFormatType_14Bayer_GRBG"
        case .bayer_RGGB14:
            return "kCVPixelFormatType_14Bayer_RGGB"
        case .bayer_BGGR14:
            return "kCVPixelFormatType_14Bayer_BGGR"
        case .bayer_GBRG14:
            return "kCVPixelFormatType_14Bayer_GBRG"
        }
    }
    
    var description: String {
        switch self {
        case .monochrome1:
            return "1 bit indexed"
        case .indexed2:
            return "2 bit indexed"
        case .indexed4:
            return "4 bit indexed"
        case .indexed8:
            return "8 bit indexed"
        case .indexedGray_WhiteIsZero1:
            return "1 bit indexed gray, white is zero"
        case .indexedGray_WhiteIsZero2:
            return "2 bit indexed gray, white is zero"
        case .indexedGray_WhiteIsZero4:
            return "4 bit indexed gray, white is zero"
        case .indexedGray_WhiteIsZero8:
            return "8 bit indexed gray, white is zero"
        case .BE16BE555:
            return "16 bit BE RGB 555"
        case .LE16LE555:
            return "16 bit LE RGB 555"
        case .LE16LE5551:
            return "16 bit LE RGB 5551"
        case .BE16BE565:
            return "16 bit BE RGB 565"
        case .LE16LE565:
            return "16 bit LE RGB 565"
        case .RGB24:
            return "24 bit RGB"
        case .BGR24:
            return "24 bit BGR"
        case .ARGB32:
            return "32 bit ARGB"
        case .BGRA32:
            return "32 bit BGRA"
        case .ABGR32:
            return "32 bit ABGR"
        case .RGBA32:
            return "32 bit RGBA"
        case .ARGB64:
            return "64 bit ARGB, 16-bit big-endian samples"
        case .RGB48:
            return "48 bit RGB, 16-bit big-endian samples"
        case .alphaGray32:
            return "32 bit AlphaGray, 16-bit big-endian samples, black is zero"
        case .gray16:
            return "16 bit Grayscale, 16-bit big-endian samples, black is zero"
        case .RGB30:
            return "30 bit RGB, 10-bit big-endian samples, 2 unused padding bits (at least significant end)."
        case .YpCbCr8_422:
            return "Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1"
        case .YpCbCrA8_4444:
            return "Component Y'CbCrA 8-bit 4:4:4:4, ordered Cb Y' Cr A"
        case .YpCbCrA8R_4444:
            return "Component Y'CbCrA 8-bit 4:4:4:4, rendering format. full range alpha, zero biased YUV, ordered A Y' Cb Cr"
        case .AYpCbCr8_4444:
            return "Component Y'CbCrA 8-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr."
        case .AYpCbCr16_4444:
            return "Component Y'CbCrA 16-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr, 16-bit little-endian samples."
        case .YpCbCr8_444:
            return "Component Y'CbCr 8-bit 4:4:4"
        case .YpCbCr16_422:
            return "Component Y'CbCr 10,12,14,16-bit 4:2:2"
        case .YpCbCr10_422:
            return "Component Y'CbCr 10-bit 4:2:2"
        case .YpCbCr10_444:
            return "Component Y'CbCr 10-bit 4:4:4"
        case .YpCbCr8Planar_420:
            return "Planar Component Y'CbCr 8-bit 4:2:0.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct"
        case .YpCbCr8PlanarFullRange_420:
            return "Planar Component Y'CbCr 8-bit 4:2:0, full range.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct"
        case .YpCbCr_4A_8BiPlanar_422:
            return "First plane: Video-range Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1; second plane: alpha 8-bit 0-255"
        case .YpCbCr8BiPlanarVideoRange_420:
            return "Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct"
        case .YpCbCr8BiPlanarFullRange_420:
            return "Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct"
        case .YpCbCr8_yuvs_422:
            return "Component Y'CbCr 8-bit 4:2:2, ordered Y'0 Cb Y'1 Cr"
        case .YpCbCr8FullRange_422:
            return "Component Y'CbCr 8-bit 4:2:2, full range, ordered Y'0 Cb Y'1 Cr"
        case .oneComponent8:
            return "8 bit one component, black is zero"
        case .twoComponent8:
            return "8 bit two component, black is zero"
        case .RGBLEPackedWideGamut30:
            return "little-endian RGB101010, 2 MSB are zero, wide-gamut (384-895)"
        case .oneComponent16Half:
            return "16 bit one component IEEE half-precision float, 16-bit little-endian samples"
        case .oneComponent32Float:
            return "32 bit one component IEEE float, 32-bit little-endian samples"
        case .twoComponent16Half:
            return "16 bit two component IEEE half-precision float, 16-bit little-endian samples"
        case .twoComponent32Float:
            return "32 bit two component IEEE float, 32-bit little-endian samples"
        case .RGBAHalf64:
            return "64 bit RGBA IEEE half-precision float, 16-bit little-endian samples"
        case .RGBAFloat128:
            return "128 bit RGBA IEEE float, 32-bit little-endian samples"
        case .bayer_GRBG14:
            return "Bayer 14-bit Little-Endian, packed in 16-bits, ordered G R G R... alternating with B G B G..."
        case .bayer_RGGB14:
            return "Bayer 14-bit Little-Endian, packed in 16-bits, ordered R G R G... alternating with G B G B..."
        case .bayer_BGGR14:
            return "Bayer 14-bit Little-Endian, packed in 16-bits, ordered B G B G... alternating with G R G R..."
        case .bayer_GBRG14:
            return "Bayer 14-bit Little-Endian, packed in 16-bits, ordered G B G B... alternating with R G R G..."

        }
    }
    
    var fourccRepresentation: String {
        if self.rawValue <= 0x28 {
            return"\(self)"
        } else {
            let characterOne = Character(UnicodeScalar(shiftMask(self.rawValue, n: 24)))
            let characterTwo = Character(UnicodeScalar(shiftMask(self.rawValue, n: 16)))
            let characterThree = Character(UnicodeScalar(shiftMask(self.rawValue, n: 8)))
            let characterFour = Character(UnicodeScalar(shiftMask(self.rawValue, n: 0)))
            return ("\(characterOne)\(characterTwo)\(characterThree)\(characterFour)")
        }
    }
    
}

extension OSType {
    // https://developer.apple.com/library/content/qa/qa1501/_index.html
    static var allDescriptions: [OSType: String] {
        return [kCVPixelFormatType_1Monochrome: "1 bit indexed",
                kCVPixelFormatType_2Indexed: "2 bit indexed",
                kCVPixelFormatType_4Indexed: "4 bit indexed",
                kCVPixelFormatType_8Indexed: "8 bit indexed",
                kCVPixelFormatType_1IndexedGray_WhiteIsZero: "1 bit indexed gray, white is zero",
                kCVPixelFormatType_2IndexedGray_WhiteIsZero: "2 bit indexed gray, white is zero",
                kCVPixelFormatType_4IndexedGray_WhiteIsZero: "4 bit indexed gray, white is zero",
                kCVPixelFormatType_8IndexedGray_WhiteIsZero: "8 bit indexed gray, white is zero",
                kCVPixelFormatType_16BE555: "16 bit BE RGB 555",
                kCVPixelFormatType_16LE555: "16 bit LE RGB 555",
                kCVPixelFormatType_16LE5551: "16 bit LE RGB 5551",
                kCVPixelFormatType_16BE565: "16 bit BE RGB 565",
                kCVPixelFormatType_16LE565: "16 bit LE RGB 565",
                kCVPixelFormatType_24RGB: "24 bit RGB",
                kCVPixelFormatType_24BGR: "24 bit BGR",
                kCVPixelFormatType_32ARGB: "32 bit ARGB",
                kCVPixelFormatType_32BGRA: "32 bit BGRA",
                kCVPixelFormatType_32ABGR: "32 bit ABGR",
                kCVPixelFormatType_32RGBA: "32 bit RGBA",
                kCVPixelFormatType_64ARGB: "64 bit ARGB, 16-bit big-endian samples",
                kCVPixelFormatType_48RGB: "48 bit RGB, 16-bit big-endian samples",
                kCVPixelFormatType_32AlphaGray: "32 bit AlphaGray, 16-bit big-endian samples, black is zero",
                kCVPixelFormatType_16Gray: "16 bit Grayscale, 16-bit big-endian samples, black is zero",
                kCVPixelFormatType_30RGB: "30 bit RGB, 10-bit big-endian samples, 2 unused padding bits (at least significant end).",
                kCVPixelFormatType_422YpCbCr8: "Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1",
                kCVPixelFormatType_4444YpCbCrA8: "Component Y'CbCrA 8-bit 4:4:4:4, ordered Cb Y' Cr A",
                kCVPixelFormatType_4444YpCbCrA8R: "Component Y'CbCrA 8-bit 4:4:4:4, rendering format. full range alpha, zero biased YUV, ordered A Y' Cb Cr",
                kCVPixelFormatType_4444AYpCbCr8: "Component Y'CbCrA 8-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr.",
                kCVPixelFormatType_4444AYpCbCr16: "Component Y'CbCrA 16-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr, 16-bit little-endian samples.",
                kCVPixelFormatType_444YpCbCr8: "Component Y'CbCr 8-bit 4:4:4",
                kCVPixelFormatType_422YpCbCr16: "Component Y'CbCr 10,12,14,16-bit 4:2:2",
                kCVPixelFormatType_422YpCbCr10: "Component Y'CbCr 10-bit 4:2:2",
                kCVPixelFormatType_444YpCbCr10: "Component Y'CbCr 10-bit 4:4:4",
                kCVPixelFormatType_420YpCbCr8Planar: "Planar Component Y'CbCr 8-bit 4:2:0.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct",
                kCVPixelFormatType_420YpCbCr8PlanarFullRange: "Planar Component Y'CbCr 8-bit 4:2:0, full range.  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrPlanar struct",
                kCVPixelFormatType_422YpCbCr_4A_8BiPlanar: "First plane: Video-range Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1; second plane: alpha 8-bit 0-255",
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange: "Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range (luma=[16,235] chroma=[16,240]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct",
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: "Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255]).  baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct",
                kCVPixelFormatType_422YpCbCr8_yuvs: "Component Y'CbCr 8-bit 4:2:2, ordered Y'0 Cb Y'1 Cr",
                kCVPixelFormatType_422YpCbCr8FullRange: "Component Y'CbCr 8-bit 4:2:2, full range, ordered Y'0 Cb Y'1 Cr",
                kCVPixelFormatType_OneComponent8: "8 bit one component, black is zero",
                kCVPixelFormatType_TwoComponent8: "8 bit two component, black is zero",
                kCVPixelFormatType_30RGBLEPackedWideGamut: "little-endian RGB101010, 2 MSB are zero, wide-gamut (384-895)",
                kCVPixelFormatType_OneComponent16Half: "16 bit one component IEEE half-precision float, 16-bit little-endian samples",
                kCVPixelFormatType_OneComponent32Float: "32 bit one component IEEE float, 32-bit little-endian samples",
                kCVPixelFormatType_TwoComponent16Half: "16 bit two component IEEE half-precision float, 16-bit little-endian samples",
                kCVPixelFormatType_TwoComponent32Float: "32 bit two component IEEE float, 32-bit little-endian samples",
                kCVPixelFormatType_64RGBAHalf: "64 bit RGBA IEEE half-precision float, 16-bit little-endian samples",
                kCVPixelFormatType_128RGBAFloat: "128 bit RGBA IEEE float, 32-bit little-endian samples",
                kCVPixelFormatType_14Bayer_GRBG: "Bayer 14-bit Little-Endian, packed in 16-bits, ordered G R G R... alternating with B G B G...",
                kCVPixelFormatType_14Bayer_RGGB: "Bayer 14-bit Little-Endian, packed in 16-bits, ordered R G R G... alternating with G B G B...",
                kCVPixelFormatType_14Bayer_BGGR: "Bayer 14-bit Little-Endian, packed in 16-bits, ordered B G B G... alternating with G R G R...",
                kCVPixelFormatType_14Bayer_GBRG: "Bayer 14-bit Little-Endian, packed in 16-bits, ordered G B G B... alternating with R G R G..."]
    }
    static var allTypeKeys: [OSType: String] {
        return [kCVPixelFormatType_1Monochrome: "kCVPixelFormatType_1Monochrome",
                kCVPixelFormatType_2Indexed: "kCVPixelFormatType_2Indexed",
                kCVPixelFormatType_4Indexed: "kCVPixelFormatType_4Indexed",
                kCVPixelFormatType_8Indexed: "kCVPixelFormatType_8Indexed",
                kCVPixelFormatType_1IndexedGray_WhiteIsZero: "kCVPixelFormatType_1IndexedGray_WhiteIsZero",
                kCVPixelFormatType_2IndexedGray_WhiteIsZero: "kCVPixelFormatType_2IndexedGray_WhiteIsZero",
                kCVPixelFormatType_4IndexedGray_WhiteIsZero: "kCVPixelFormatType_4IndexedGray_WhiteIsZero",
                kCVPixelFormatType_8IndexedGray_WhiteIsZero: "kCVPixelFormatType_8IndexedGray_WhiteIsZero",
                kCVPixelFormatType_16BE555: "kCVPixelFormatType_16BE555",
                kCVPixelFormatType_16LE555: "kCVPixelFormatType_16LE555",
                kCVPixelFormatType_16LE5551: "kCVPixelFormatType_16LE5551",
                kCVPixelFormatType_16BE565: "kCVPixelFormatType_16BE565",
                kCVPixelFormatType_16LE565: "kCVPixelFormatType_16LE565",
                kCVPixelFormatType_24RGB: "kCVPixelFormatType_24RGB",
                kCVPixelFormatType_24BGR: "kCVPixelFormatType_24BGR",
                kCVPixelFormatType_32ARGB: "kCVPixelFormatType_32ARGB",
                kCVPixelFormatType_32BGRA: "kCVPixelFormatType_32BGRA",
                kCVPixelFormatType_32ABGR: "kCVPixelFormatType_32ABGR",
                kCVPixelFormatType_32RGBA: "kCVPixelFormatType_32RGBA",
                kCVPixelFormatType_64ARGB: "kCVPixelFormatType_64ARGB",
                kCVPixelFormatType_48RGB: "kCVPixelFormatType_48RGB",
                kCVPixelFormatType_32AlphaGray: "kCVPixelFormatType_32AlphaGray",
                kCVPixelFormatType_16Gray: "kCVPixelFormatType_16Gray",
                kCVPixelFormatType_30RGB: "kCVPixelFormatType_30RGB",
                kCVPixelFormatType_422YpCbCr8: "kCVPixelFormatType_422YpCbCr8",
                kCVPixelFormatType_4444YpCbCrA8: "kCVPixelFormatType_4444YpCbCrA8",
                kCVPixelFormatType_4444YpCbCrA8R: "kCVPixelFormatType_4444YpCbCrA8R",
                kCVPixelFormatType_4444AYpCbCr8: "kCVPixelFormatType_4444AYpCbCr8",
                kCVPixelFormatType_4444AYpCbCr16: "kCVPixelFormatType_4444AYpCbCr16",
                kCVPixelFormatType_444YpCbCr8: "kCVPixelFormatType_444YpCbCr8",
                kCVPixelFormatType_422YpCbCr16: "kCVPixelFormatType_422YpCbCr16",
                kCVPixelFormatType_422YpCbCr10: "kCVPixelFormatType_422YpCbCr10",
                kCVPixelFormatType_444YpCbCr10: "kCVPixelFormatType_444YpCbCr10",
                kCVPixelFormatType_420YpCbCr8Planar: "kCVPixelFormatType_420YpCbCr8Planar",
                kCVPixelFormatType_420YpCbCr8PlanarFullRange: "kCVPixelFormatType_420YpCbCr8PlanarFullRange",
                kCVPixelFormatType_422YpCbCr_4A_8BiPlanar: "kCVPixelFormatType_422YpCbCr_4A_8BiPlanar",
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange: "kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange",
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: "kCVPixelFormatType_420YpCbCr8BiPlanarFullRange",
                kCVPixelFormatType_422YpCbCr8_yuvs: "kCVPixelFormatType_422YpCbCr8_yuvs",
                kCVPixelFormatType_422YpCbCr8FullRange: "kCVPixelFormatType_422YpCbCr8FullRange",
                kCVPixelFormatType_OneComponent8: "kCVPixelFormatType_OneComponent8",
                kCVPixelFormatType_TwoComponent8: "kCVPixelFormatType_TwoComponent8",
                kCVPixelFormatType_30RGBLEPackedWideGamut: "kCVPixelFormatType_30RGBLEPackedWideGamut",
                kCVPixelFormatType_OneComponent16Half: "kCVPixelFormatType_OneComponent16Half",
                kCVPixelFormatType_OneComponent32Float: "kCVPixelFormatType_OneComponent32Float",
                kCVPixelFormatType_TwoComponent16Half: "kCVPixelFormatType_TwoComponent16Half",
                kCVPixelFormatType_TwoComponent32Float: "kCVPixelFormatType_TwoComponent32Float",
                kCVPixelFormatType_64RGBAHalf: "kCVPixelFormatType_64RGBAHalf",
                kCVPixelFormatType_128RGBAFloat: "kCVPixelFormatType_128RGBAFloat",
                kCVPixelFormatType_14Bayer_GRBG: "kCVPixelFormatType_14Bayer_GRBG",
                kCVPixelFormatType_14Bayer_RGGB: "kCVPixelFormatType_14Bayer_RGGB",
                kCVPixelFormatType_14Bayer_BGGR: "kCVPixelFormatType_14Bayer_BGGR",
                kCVPixelFormatType_14Bayer_GBRG: "kCVPixelFormatType_14Bayer_GBRG"]
    }
    static var allNames: [OSType: String] {
        return [kCVPixelFormatType_1Monochrome: "1Monochrome",
                kCVPixelFormatType_2Indexed: "2Indexed",
                kCVPixelFormatType_4Indexed: "4Indexed",
                kCVPixelFormatType_8Indexed: "8Indexed",
                kCVPixelFormatType_1IndexedGray_WhiteIsZero: "1IndexedGray_WhiteIsZero",
                kCVPixelFormatType_2IndexedGray_WhiteIsZero: "2IndexedGray_WhiteIsZero",
                kCVPixelFormatType_4IndexedGray_WhiteIsZero: "4IndexedGray_WhiteIsZero",
                kCVPixelFormatType_8IndexedGray_WhiteIsZero: "8IndexedGray_WhiteIsZero",
                kCVPixelFormatType_16BE555: "16BE555",
                kCVPixelFormatType_16LE555: "16LE555",
                kCVPixelFormatType_16LE5551: "16LE5551",
                kCVPixelFormatType_16BE565: "16BE565",
                kCVPixelFormatType_16LE565: "16LE565",
                kCVPixelFormatType_24RGB: "24RGB",
                kCVPixelFormatType_24BGR: "24BGR",
                kCVPixelFormatType_32ARGB: "32ARGB",
                kCVPixelFormatType_32BGRA: "32BGRA",
                kCVPixelFormatType_32ABGR: "32ABGR",
                kCVPixelFormatType_32RGBA: "32RGBA",
                kCVPixelFormatType_64ARGB: "64ARGB",
                kCVPixelFormatType_48RGB: "48RGB",
                kCVPixelFormatType_32AlphaGray: "32AlphaGray",
                kCVPixelFormatType_16Gray: "16Gray",
                kCVPixelFormatType_30RGB: "30RGB",
                kCVPixelFormatType_422YpCbCr8: "422YpCbCr8",
                kCVPixelFormatType_4444YpCbCrA8: "4444YpCbCrA8",
                kCVPixelFormatType_4444YpCbCrA8R: "4444YpCbCrA8R",
                kCVPixelFormatType_4444AYpCbCr8: "4444AYpCbCr8",
                kCVPixelFormatType_4444AYpCbCr16: "4444AYpCbCr16",
                kCVPixelFormatType_444YpCbCr8: "444YpCbCr8",
                kCVPixelFormatType_422YpCbCr16: "422YpCbCr16",
                kCVPixelFormatType_422YpCbCr10: "422YpCbCr10",
                kCVPixelFormatType_444YpCbCr10: "444YpCbCr10",
                kCVPixelFormatType_420YpCbCr8Planar: "420YpCbCr8Planar",
                kCVPixelFormatType_420YpCbCr8PlanarFullRange: "420YpCbCr8PlanarFullRange",
                kCVPixelFormatType_422YpCbCr_4A_8BiPlanar: "422YpCbCr_4A_8BiPlanar",
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange: "420YpCbCr8BiPlanarVideoRange",
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: "420YpCbCr8BiPlanarFullRange",
                kCVPixelFormatType_422YpCbCr8_yuvs: "422YpCbCr8_yuvs",
                kCVPixelFormatType_422YpCbCr8FullRange: "422YpCbCr8FullRange",
                kCVPixelFormatType_OneComponent8: "OneComponent8",
                kCVPixelFormatType_TwoComponent8: "TwoComponent8",
                kCVPixelFormatType_30RGBLEPackedWideGamut: "30RGBLEPackedWideGamut",
                kCVPixelFormatType_OneComponent16Half: "OneComponent16Half",
                kCVPixelFormatType_OneComponent32Float: "OneComponent32Float",
                kCVPixelFormatType_TwoComponent16Half: "TwoComponent16Half",
                kCVPixelFormatType_TwoComponent32Float: "TwoComponent32Float",
                kCVPixelFormatType_64RGBAHalf: "64RGBAHalf",
                kCVPixelFormatType_128RGBAFloat: "128RGBAFloat",
                kCVPixelFormatType_14Bayer_GRBG: "14Bayer_GRBG",
                kCVPixelFormatType_14Bayer_RGGB: "14Bayer_RGGB",
                kCVPixelFormatType_14Bayer_BGGR: "14Bayer_BGGR",
                kCVPixelFormatType_14Bayer_GBRG: "14Bayer_GBRG"]
    }
    
    var fourccRepresentation: String {
        if self <= 0x28 {
            return"\(self)"
        } else {
            let characterOne = Character(UnicodeScalar(shiftMask(self, n: 24)))
            let characterTwo = Character(UnicodeScalar(shiftMask(self, n: 16)))
            let characterThree = Character(UnicodeScalar(shiftMask(self, n: 8)))
            let characterFour = Character(UnicodeScalar(shiftMask(self, n: 0)))
            return ("\(characterOne)\(characterTwo)\(characterThree)\(characterFour)")
        }
    }
    
    var name: String {
        guard let name = OSType.allNames[self] else {
            return"\(self)"
        }
        return name
    }
    
    var typeKey: String {
        guard let typeKey = OSType.allTypeKeys[self] else {
            return"\(self)"
        }
        return typeKey
    }
    
    var description: String {
        guard let description = OSType.allDescriptions[self] else {
            return"No description available for OSType \(self)"
        }
        return description
    }
    
    var pixelFormatDescriptionDictionary: [String: AnyObject] {
        let dict = CVPixelFormatDescriptionCreateWithPixelFormatType(nil, self) as! [String: AnyObject]
        
        return dict
    }
}



