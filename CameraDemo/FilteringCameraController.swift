//
//  FilteringCameraController.swift
//

import Foundation
import AVFoundation
import CoreGraphics
import CoreImage
import UIKit

class FilteringCameraController: NSObject {
    
    private var previewView = MetalView()
    
    @objc dynamic private let captureSession = AVCaptureSession()
    private let captureSessionQueue = DispatchQueue(label: "FilteringCameraController_capture_session_queue",
                                                    attributes: [])
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var setupComplete = false
    private var captureVideoOrientation = AVCaptureVideoOrientation.portrait
    
    // 1
    private lazy var filter: CIFilter = {
        let filterInternal = CIFilter(name: "CIComicEffect")!
        return filterInternal
    }()
    
    var flashMode = AVCaptureDevice.FlashMode.auto
    
    // 2
    func prepareCamera(with previewView: UIView) {
        if setupComplete || AVCaptureDevice.authorizationStatus(for: .video) == .denied {
            return
        }
        
        previewView.addSubview(self.previewView)
        self.previewView.frame = previewView.frame
        previewView.bringSubviewToFront(self.previewView)
        
        setupInput(for: .front)
        setupComplete = true
    }
    
    // 3
    private func setupInput(for cameraPosition: AVCaptureDevice.Position) {
        captureSessionQueue.async {
            self.prepareInput(for: cameraPosition)
            self.setupOutputs()
            
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
        }
    }
    
    // 4
    private func prepareInput(for cameraPosition: AVCaptureDevice.Position) {
        
        guard let videoDevice = captureDevice(with: AVMediaType.video.rawValue, position: cameraPosition) else {
            return
        }
        let videoDeviceInput: AVCaptureDeviceInput!
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        if self.captureSession.canAddInput(videoDeviceInput) {
            self.captureSession.addInput(videoDeviceInput)
            self.videoInput = videoDeviceInput
        }
    }
    
    // 5
    private func setupOutputs() {
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: self.captureSessionQueue)
        if self.captureSession.canAddOutput(videoDataOutput) {
            self.captureSession.addOutput(videoDataOutput)
            self.videoOutput = videoDataOutput
        }
    }
    
    // 6
    func startCamera() {
        if !setupComplete {
            return
        }
        
        if captureSession.isRunning {
            return
        }
        
        captureSessionQueue.async { [unowned self] in
            self.captureSession.startRunning()
        }
    }
    
    // 7
    private func captureDevice(with mediaType: String, position: AVCaptureDevice.Position?) -> AVCaptureDevice? {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        let cameras = session.devices
        var captureDevice = cameras.first
        
        if let position = position {
            for device in cameras where device.position == position {
                captureDevice = device
                break
            }
        }
        if position == .back {
            try? captureDevice?.lockForConfiguration()
            captureDevice?.focusMode = .continuousAutoFocus
            captureDevice?.unlockForConfiguration()
        }
        
        return captureDevice
    }
    
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
}

// 8
extension FilteringCameraController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let sourceImage = CIImage(cvPixelBuffer: imageBuffer as CVPixelBuffer)
        filter.setValue(sourceImage, forKey: kCIInputImageKey)
        
        let filteredImage = filter.outputImage!
        
        // 9
        let rotation = -CGFloat.pi
        let translationX: CGFloat = -1
        let rotated = filteredImage
            .transformed(by: CGAffineTransform(rotationAngle: rotation / 2))
            .transformed(by: CGAffineTransform(scaleX: translationX, y: 1))
        
        let transformed = rotated.transformed(by: .init(translationX: -rotated.extent.origin.x,
        y: -rotated.extent.origin.y))
        
        // 10
        previewView.image = transformed
    }
}
