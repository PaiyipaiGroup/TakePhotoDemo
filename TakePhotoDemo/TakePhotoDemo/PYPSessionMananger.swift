//
//  PYPSessionMananger.swift
//  TakePhotoDemo
//
//  Created by Erickson on 16/3/23.
//  Copyright © 2016年 paiyipai. All rights reserved.
//

import UIKit
import AVFoundation

private var CapturingStillImageContext = "CapturingStillImageContext"
private var SessionRunningContext = "SessionRunningContext"


protocol PYPSessionManangerDelegate: class {
    func sessionManangerCameraNotAuthorizedHandle()

}


enum AVCamSetupResult{
    case Success,CameraNotAuthorized
}


class PYPSessionMananger: NSObject {
    
    weak var delegate : PYPSessionManangerDelegate?
    
    var sessionQueue : dispatch_queue_t!
    
    let session = AVCaptureSession()
    
    var videoDeviceInput : AVCaptureDeviceInput?
    
    let stillImageOutput = AVCaptureStillImageOutput()
    
    var setupResult : AVCamSetupResult?

    var flashMode:AVCaptureFlashMode = .Auto
    var torchMode:AVCaptureTorchMode = .Auto
    
    var preView : PYPPreviewView?
    
    init(previewView:PYPPreviewView) {
        super.init()
        
        previewView.setVideoFillMode(AVLayerVideoGravityResizeAspect)

        previewView.setSession(session)
        
        preView = previewView

        setupDevice()
    }
    
    func setupDevice() {

        if session.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
            session.canSetSessionPreset(AVCaptureSessionPresetPhoto)
        }
        sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        setupResult = .Success;

        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case .Authorized:
            
            print("granted access to camera")
        case.NotDetermined:

            dispatch_suspend(sessionQueue)
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {[unowned self] (granted) -> Void in
                if !granted {
                   self.setupResult = .CameraNotAuthorized
                }
                dispatch_resume(self.sessionQueue)
            })
            default:
            setupResult = .CameraNotAuthorized
        }
        
        
        //Setup the capture session.
        dispatch_async(sessionQueue) {[unowned self] () -> Void in
            if self.setupResult != .Success {
                return
            }
            let videoDevice = PYPSessionMananger .device(AVMediaTypeVideo, preferringPosition: .Back)

            do {
                self.videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                PYPSessionMananger.setTorchMode(self.torchMode, device: self.videoDeviceInput!.device)

            } catch {
                //error handle
            }
            
            self.session.beginConfiguration()
            
            if self.session.canAddInput(self.videoDeviceInput!) {
                self.session.addInput(self.videoDeviceInput!)
            }

            if self.session.canAddOutput(self.stillImageOutput) {
                self.session.addOutput(self.stillImageOutput)
            }

            self.session.commitConfiguration()
            
            
        }
        
       
    }
    
    func addObservers() {
        session.addObserver(self, forKeyPath: "running", options: .New, context: &SessionRunningContext)
        stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: .New, context: &CapturingStillImageContext)
        
        
    }
    func removeObservers() {
//        NSNotificationCenter.defaultCenter().removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &SessionRunningContext)
        stillImageOutput.removeObserver(self, forKeyPath: "capturingStillImage", context: &CapturingStillImageContext)
        
    }
    func sessionStart() {
        dispatch_async(sessionQueue) { 
            switch self.setupResult! {
            case .Success:
                self.addObservers()
                self.session.startRunning()
                
            case .CameraNotAuthorized:
                dispatch_async(dispatch_get_main_queue(), {
                    self.delegate?.sessionManangerCameraNotAuthorizedHandle()
                })
                
            }
        }
    }
    
    func sessionStop() {
        dispatch_async(sessionQueue) { 
            if self.setupResult == .Success {
                self.session.stopRunning()
                self.removeObservers()
            }
        }
    }
    
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &CapturingStillImageContext {
            let isCapturingStillImage : Bool = change![NSKeyValueChangeNewKey]!.boolValue
        
            if isCapturingStillImage {
                dispatch_async(dispatch_get_main_queue(), {

                    self.preView?.layer.opacity = 0.0
                    UIView.animateWithDuration(0.25, animations: {
                        self.preView?.layer.opacity = 1.0
                    })

                })
            }
        } else if (context == &SessionRunningContext) {
            let isSessionRunning : Bool = change![NSKeyValueChangeNewKey]!.boolValue
            if isSessionRunning {
                dispatch_async(dispatch_get_main_queue(), {
                    //button enabled = isSessionRunning
                })
            }
        }
        
    }
    
    func snapStillImage(stillImage:(UIImage)->()) {
        dispatch_async(sessionQueue) { 
            let connection = self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)
            
            let previewLayer = self.preView?.layer as! AVCaptureVideoPreviewLayer
            
            connection.videoOrientation = previewLayer.connection.videoOrientation
            
            PYPSessionMananger.setFlashMode(self.flashMode, device: self.videoDeviceInput!.device)
            //Flash set to Auto for Still Capture.
            
            // Capture a still image.
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (imageDataSampleBuffer, error) in
                if imageDataSampleBuffer != nil {
                    let imgData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
                    let image = UIImage(data: imgData)
                    stillImage(image!)
                }
            })

        }
    }
    
    
    private class func setTorchMode(torchMode:AVCaptureTorchMode,device:AVCaptureDevice) {
        if device.hasTorch && device.isTorchModeSupported(torchMode) {
            do {
                try device.lockForConfiguration()
                device.torchMode = torchMode
                device.unlockForConfiguration()
            }catch {
                
            }
        }
    }
    
    private class func setFlashMode(flashMode:AVCaptureFlashMode,device:AVCaptureDevice) {
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
            }catch {
                
            }
        }
    }
    
    private class func device(mediaType:String ,preferringPosition:AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType) as! [AVCaptureDevice]
        var captureDevice =  devices.first
        
        for device in devices {
            if device.position == preferringPosition {
                captureDevice = device
                break
            }
        }
        
        return captureDevice!
    
    }
    
    
}


