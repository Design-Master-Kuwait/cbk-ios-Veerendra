//
//  AlertClass.swift
//  Daftar
//
//  Created by Pro on 15/02/21.
//  Copyright © 2021 Abhishek Rana. All rights reserved.
//

import Foundation
import UIKit

// MARK:- Alert Class

class AlertClass {
    
    class func startAlert(msg:String) {
        
        let alertController = UIAlertController(title: APPNAME, message:msg, preferredStyle: .alert)
        alertController.view.tintColor = UIColor.black
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
        }))
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    
    class func startAlertForArabic(msg:String, AppName:String, ok:String) {
        
        let alertController = UIAlertController(title: AppName, message:msg, preferredStyle: .alert)
        alertController.view.tintColor = UIColor.black
        alertController.addAction(UIAlertAction(title: ok, style: .default, handler: {action in
        }))
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    class func alert(title: String, message: String, okActionTitle: String) {
        let alertView = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
        let okAction = UIAlertAction(title: okActionTitle, style: .default)
        alertView.addAction(okAction)
        UIApplication.shared.windows.first?.rootViewController?.present(alertView, animated: true)
    }
    
 
    
}


class CustomAlertClass {
    
    class func CustomstartAlert(title:String ,msg: String)
    {
        let alertController = UIAlertController(title: APPNAME, message:msg, preferredStyle: .alert)
        alertController.view.tintColor = UIColor.black
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
        }))
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}

extension UIViewController {
    
    func presentAlert(withTitle title: String, message : String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            print("You've pressed OK Button")
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
}


