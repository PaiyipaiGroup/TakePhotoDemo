//
//  ViewController.swift
//  TakePhotoDemo
//
//  Created by Erickson on 16/3/23.
//  Copyright © 2016年 paiyipai. All rights reserved.
//

import UIKit
import AVFoundation
class ViewController: UIViewController {

    @IBOutlet weak var previewView: PYPPreviewView!

    var manager : PYPSessionMananger!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        
        
        manager = PYPSessionMananger(previewView: previewView)
        manager.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        manager.sessionStart()
    }
    
    override func viewWillDisappear(animated: Bool) {
        manager.sessionStop()
    }

    
    @IBAction func enterLibrary(sender: AnyObject) {
        
        
    }
    
    
    @IBAction func takePhoto(sender: AnyObject) {
        
        manager.snapStillImage { (image) in
            UIImageWriteToSavedPhotosAlbum(image,nil, nil, nil)
        }
    }

}

extension ViewController : PYPSessionManangerDelegate {
    func sessionManangerCameraNotAuthorizedHandle() {
        let delegat = UIApplication.sharedApplication().delegate as! AppDelegate
        let vc = delegat.window?.rootViewController
        let notAuthVc = NotAuthorizedViewController(nibName: "NotAuthorizedViewController", bundle: nil)
        notAuthVc.delegate = self
        vc?.presentViewController(notAuthVc, animated: true, completion: nil)
        print("木有权限")
    }
}


extension ViewController : NotAuthorizedViewControllerDelegate {
    func cancelAuthorizedAction() {
        
        navigationController?.popViewControllerAnimated(true)
    }
}
