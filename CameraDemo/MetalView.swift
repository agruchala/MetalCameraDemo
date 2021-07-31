//
//  MetalView.swift
//  metalDemo
//
//  Created by Artur Gruchała on 30/07/2021.
//

import UIKit
import MetalKit
import CoreGraphics
import CoreImage

class MetalView: MTKView {
    // 1
    private enum Constants {
        static let roundingFactor2x: CGFloat = 500
        static let roundingFactor3x: CGFloat = 1000
    }
    
    var context: CIContext? // 2
    var queue: MTLCommandQueue? // 3
    var commandBuffer: MTLCommandBuffer? // 4
    let colorSpace = CGColorSpaceCreateDeviceRGB() // 5
    var image: CIImage? { // 6
        didSet {
            DispatchQueue.main.async {
                self.drawCIImge()
            }
        }
    }

    // 7
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.isOpaque = false
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("darn")
            return
        }
        self.device = device
        self.framebufferOnly = false
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        self.context = CIContext(mtlDevice: device)
        self.queue = device.makeCommandQueue()
    }
    
    init()  {
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
        self.isOpaque = false
        self.framebufferOnly = false
        self.enableSetNeedsDisplay = true
        self.context = CIContext(mtlDevice: device!)
        self.queue = device!.makeCommandQueue()
    }
    
    private func drawCIImge() {
        guard let image = image,
            let texture = currentDrawable?.texture,
            let buffer = queue?.makeCommandBuffer()
            else { return }
        // 8
        let imageSize = image.extent.size
        let sizeScale = bounds.width / imageSize.width * layer.contentsScale
        let roundingFactor = layer.contentsScale == 2 ? Constants.roundingFactor2x : Constants.roundingFactor3x
        let sizeScaleRounded = CGFloat(ceil(sizeScale * roundingFactor) / roundingFactor)
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: sizeScaleRounded, y: sizeScaleRounded))
        let xPos = 0
        let yPos = 0
        // 9
        self.context!.render(scaledImage,
                             to: texture,
                             commandBuffer: buffer,
                             bounds: CGRect(origin: CGPoint(x: xPos, y: yPos),
                                            size: self.drawableSize),
                             colorSpace: colorSpace)
        guard let drawable = self.currentDrawable else { return }
        // 10
        buffer.present(drawable)
        buffer.commit()
        setNeedsDisplay()
    }
}
