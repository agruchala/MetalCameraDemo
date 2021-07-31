//
//  CameraController.swift
//  CameraDemo
//
//  Created by Artur Gruchała on 31/07/2021.
//

import UIKit
import AVFoundation

final class CameraController: NSObject {
    
    private var captureSession: AVCaptureSession?
    private var frontCamera: AVCaptureDevice?
    private var frontCameraInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput!
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var flashMode = AVCaptureDevice.FlashMode.auto
    
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        
        DispatchQueue(label: "prepare").async { [unowned self] in
            do {
                self.createCaptureSession()
                try self.configureCaptureDevices()
                try self.configureDeviceInputs()
                try self.configurePhotoOutput()
            } catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    private func createCaptureSession() {
        captureSession = AVCaptureSession()
    }
    
    private func configureCaptureDevices() throws {
        
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        let cameras = session.devices
        guard !cameras.isEmpty else { throw CameraControllerError.noCamerasAvailable }
        
        for camera in cameras {
            if camera.position == .front {
                frontCamera = camera
            }
        }
    }
    
    private func configureDeviceInputs() throws {
        guard let captureSession = captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        if let frontCamera = frontCamera {
            frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            if captureSession.canAddInput(frontCameraInput!) {
                captureSession.addInput(frontCameraInput!)
            }
        } else { throw CameraControllerError.noCamerasAvailable }
    }
    
    private func configurePhotoOutput() throws {
        guard let captureSession = captureSession else { throw CameraControllerError.captureSessionIsMissing }
        
        photoOutput = AVCapturePhotoOutput()
        photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])],
                                                  completionHandler: nil)
        
        if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }
        
        captureSession.startRunning()
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(previewLayer!, at: 0)
        previewLayer?.frame = view.bounds
        previewLayer?.connection?.isEnabled = true
    }
    
    func stopCamera() {
        previewLayer?.connection?.isEnabled = false
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
