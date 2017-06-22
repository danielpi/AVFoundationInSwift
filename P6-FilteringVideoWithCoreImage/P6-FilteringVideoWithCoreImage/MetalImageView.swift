//
//  MetalImageView.swift
//  P6-FilteringVideoWithCoreImage
//
//  Created by Daniel Pink on 22/6/17.
//  Copyright © 2017 Daniel Pink. All rights reserved.
//

import Cocoa
import MetalKit

class MetalImageView: MTKView
{
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    lazy var commandQueue: MTLCommandQueue =
        {
            [unowned self] in
            
            return self.device!.makeCommandQueue()
            }()
    
    lazy var ciContext: CIContext =
        {
            [unowned self] in
            
            return CIContext(mtlDevice: self.device!)
            }()
    
    /// The image to display
    var image: CIImage?
    {
        didSet
        {
            renderImage()
        }
    }
    
    func renderImage()
    {
        guard let
            image = image,
            // https://stackoverflow.com/questions/41916306/metal-texture-not-found
            let targetTexture = currentDrawable?.texture else
        {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
        
        let imageAspect = image.extent.width / image.extent.height
        let drawableAspect = drawableSize.width / drawableSize.height
        
        
        
        let scaleX = drawableSize.width / image.extent.width
        let scaleY = drawableSize.height / image.extent.height
        let scale = min(scaleX, scaleY)
        
        var scaledImage = image
            .applying(CGAffineTransform(scaleX: scale, y: scale))
        
        var originX = scaledImage.extent.origin.x
        var originY = scaledImage.extent.origin.y
        
        if imageAspect > drawableAspect {
            originY = (drawableSize.height - scaledImage.extent.height) / 2.0
        } else {
            originX = (drawableSize.width - scaledImage.extent.width) / 2.0
        }
        
        scaledImage = scaledImage.applying(CGAffineTransform(translationX: originX, y: originY))
        
        ciContext.render(scaledImage,
                         to: targetTexture,
                         commandBuffer: commandBuffer,
                         bounds: bounds,
                         colorSpace: colorSpace)
        
        commandBuffer.present(currentDrawable!)
        
        commandBuffer.commit()
        self.draw()
    }
}
