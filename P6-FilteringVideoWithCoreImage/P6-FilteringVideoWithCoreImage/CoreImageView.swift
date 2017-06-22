//
//  CoreImageView.swift
//  P6-FilteringVideoWithCoreImage
//
//  Created by Daniel Pink on 21/6/17.
//  Copyright © 2017 Daniel Pink. All rights reserved.
//

//
//  CoreImageView.swift
//  CoreImageVideo
//
//  Created by Chris Eidhof on 03/04/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import Foundation
import MetalKit

class CoreImageView: MTKView {
    var image: CIImage? {
        didSet {
            display()
        }
    }
    
    let coreImageContext: CIContext = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    
    convenience init(frame: CGRect) {
        let device = MTLCreateSystemDefaultDevice()
        self.init(frame: frame, device: device)
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        //coreImageContext = CIContext(mtlDevice: device!)
        super.init(frame: frameRect, device: device)
        // We will be calling display() directly, hence this needs to be false
        enableSetNeedsDisplay = false
        isPaused = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        if let img = image {
            //let scale = self.window?.screen.scale ?? 1.0
            //let destRect = CGRectApplyAffineTransform(bounds, CGAffineTransformMakeScale(scale, scale))
            coreImageContext.draw(img, in: rect, from: img.extent)
            //coreImageContext.drawImage(img, inRect: rect, fromRect: img.extent())
        }
    }
}
