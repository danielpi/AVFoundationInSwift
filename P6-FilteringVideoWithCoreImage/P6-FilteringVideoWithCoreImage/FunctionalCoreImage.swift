//
//  FunctionalCoreImage.swift
//  P6-FilteringVideoWithCoreImage
//
//  Created by Daniel Pink on 22/6/17.
//  Copyright © 2017 Daniel Pink. All rights reserved.
//
//  Code taken and adapted from
//  Created by Chris Eidhof on 03/04/15.
//  Copyright (c) 2015 objc.io. All rights reserved.

import Cocoa

typealias Filter = (CIImage) -> CIImage

func blur(radius: Double) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIGaussianBlur",
                              withInputParameters: parameters)!
        return filter.outputImage!
    }
}

func colorGenerator(color: NSColor) -> Filter {
    return { _ in
        let parameters: [String: Any] = [kCIInputColorKey: color]
        let filter = CIFilter(name: "CIConstantColorGenerator",
                              withInputParameters: parameters)!
        return filter.outputImage!
    }
}

func hueAdjust(angleInRadians: Float) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputAngleKey: angleInRadians,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIHueAdjust",
                              withInputParameters: parameters)!
        return filter.outputImage!
    }
}

func pixellate(scale: Float) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputImageKey:image,
            kCIInputScaleKey:scale
        ]
        return CIFilter(name: "CIPixellate", withInputParameters: parameters)!.outputImage!
    }
}

func kaleidoscope() -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputImageKey:image,
            ]
        return CIFilter(name: "CITriangleKaleidoscope", withInputParameters: parameters)!.outputImage!.cropping(to: image.extent)
    }
}


func vibrance(amount: Float) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputImageKey: image,
            "inputAmount": amount
        ]
        return CIFilter(name: "CIVibrance", withInputParameters: parameters)!.outputImage!
    }
}

func compositeSourceOver(overlay: CIImage) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputBackgroundImageKey: image,
            kCIInputImageKey: overlay
        ]
        let filter = CIFilter(name: "CISourceOverCompositing",
                              withInputParameters: parameters)!
        let cropRect = image.extent
        return filter.outputImage!.cropping(to: cropRect)
    }
}

func radialGradient(center: CGPoint, radius: CGFloat) -> CIImage {
    let params: [String: Any] = [
        "inputColor0": CIColor(red: 1, green: 1, blue: 1),
        "inputColor1": CIColor(red: 0, green: 0, blue: 0),
        "inputCenter": CIVector(cgPoint: center),
        "inputRadius0": radius,
        "inputRadius1": (radius + 1.0)
    ]
    return CIFilter(name: "CIRadialGradient", withInputParameters: params)!.outputImage!
}

func blendWithMask(background: CIImage, mask: CIImage) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: mask,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIBlendWithMask",
                              withInputParameters: parameters)!
        let cropRect = image.extent
        return filter.outputImage!.cropping(to: cropRect)
    }
}

func colorOverlay(color: NSColor) -> Filter {
    return { image in
        let overlay = colorGenerator(color: color)(image)
        return compositeSourceOver(overlay: overlay)(image)
    }
}


infix operator >>> :
func >>> (filter1: @escaping Filter, filter2: @escaping Filter) -> Filter {
    return { img in filter2(filter1(img)) }
}
