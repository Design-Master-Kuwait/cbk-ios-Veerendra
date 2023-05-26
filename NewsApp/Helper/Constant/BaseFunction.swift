

import Foundation
import UIKit
import CoreLocation
//import NVActivityIndicatorView
//import FirebaseAnalytics
//import SwiftyGif



func isNilValue(assignValue: String?) -> String {
    if assignValue != nil {
        return assignValue!
    } else {
        return ""
    }
}

func isNilValueInt(assignValue: Int?) -> Int {
    if assignValue != nil {
        return assignValue!
    } else {
        return 0
    }
}


func isNilValueArray(assignValue: [Any]?) -> [Any] {
    if assignValue != nil {
        return assignValue!
    } else {
        return []
    }
}

func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}

extension UIView {
    
    func addShadowToView(){
        let view = self
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 5
        view.layer.cornerRadius = 7
    }
}
extension UIButton{
    func addShadowToButton(){
        let button = self
        button.layer.shadowColor = UIColor.lightGray.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowOffset = .zero
        button.layer.shadowRadius = 5
        button.layer.cornerRadius = 7
    }
}

