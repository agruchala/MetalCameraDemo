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
    
    var context: CIContext!
    var queue: MTLCommandQueue!
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var image: CIImage? {
        didSet {
            DispatchQueue.main.async {
                self.drawCIImge()
            }
        }
    }

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
        guard let image = image else { return }
        let drawable = currentDrawable!
        let buffer = queue.makeCommandBuffer()!
        
        let widthScale = drawableSize.width / image.extent.width
        let heightScale = drawableSize.height / image.extent.height
        
        let scale = min(widthScale, heightScale)
        
        let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let yPos = drawableSize.height / 2 - scaledImage.extent.height / 2
        
        let bounds = CGRect(x: 0, y: -yPos, width: drawableSize.width, height: drawableSize.height)
        
        
        context.render(scaledImage,
                       to: drawable.texture,
                       commandBuffer: buffer,
                       bounds: bounds,
                       colorSpace: colorSpace)
        
        buffer.present(drawable)
        buffer.commit()
        setNeedsDisplay()
    }
}
