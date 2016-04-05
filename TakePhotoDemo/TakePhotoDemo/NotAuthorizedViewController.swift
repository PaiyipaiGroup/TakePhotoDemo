//
//  NotAuthorizedViewController.swift
//  TakePhotoDemo
//
//  Created by Erickson on 16/3/23.
//  Copyright © 2016年 paiyipai. All rights reserved.
//

import UIKit

protocol NotAuthorizedViewControllerDelegate : class{
    func cancelAuthorizedAction()
}

class NotAuthorizedViewController: UIViewController {

    weak var delegate : NotAuthorizedViewControllerDelegate?
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var contentLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appName = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as! String
        
        titleLabel.text = "使用\(appName)拍照"
        contentLabel.text = "允许\(appName)应用使用你的相机拍照"

    }

    @IBAction func allowTakeAction(sender: AnyObject) {
        
        //这是设置权限最快最好的方式，😄
        let bundleId = NSBundle.mainBundle().bundleIdentifier
        let path = "prefs:root=\(bundleId!)"
        UIApplication.sharedApplication().openURL(NSURL(string: path)!)
        
    }
    
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(false, completion: nil)
        delegate?.cancelAuthorizedAction()
    }
    
    
}
