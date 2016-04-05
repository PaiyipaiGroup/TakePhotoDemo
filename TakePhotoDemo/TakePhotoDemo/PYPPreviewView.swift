//
//  PYPPreviewView.swift
//  TakePhotoDemo
//
//  Created by Erickson on 16/3/23.
//  Copyright © 2016年 paiyipai. All rights reserved.
//

import UIKit
import AVFoundation

class PYPPreviewView: UIView {

    override class func layerClass()->AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func session () -> AVCaptureSession {
        return (self.layer as! AVCaptureVideoPreviewLayer).session
    }
    
    func setSession(session : AVCaptureSession){
        (self.layer as! AVCaptureVideoPreviewLayer).session = session
    }
  
    func setVideoFillMode(fillMode: String) {
        let layer: AVCaptureVideoPreviewLayer = self.layer as! AVCaptureVideoPreviewLayer
        layer.videoGravity = fillMode as String
    }
    
    func videoFillMode() -> String {
        let layer: AVCaptureVideoPreviewLayer = self.layer as! AVCaptureVideoPreviewLayer
        return layer.videoGravity
    }
}
