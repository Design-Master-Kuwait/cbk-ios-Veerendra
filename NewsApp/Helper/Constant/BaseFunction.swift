

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

extension String
{
    func localalizedString(str:String) -> String
    {
        let path = Bundle.main.path(forResource: str, ofType: "lproj")
        let bundle = Bundle(path: path!)
        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}
extension UIColor {
    
   static func setColor(lightColor: UIColor, darkColor: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor{ (traitCollection) -> UIColor in
                return traitCollection.userInterfaceStyle == .light ? lightColor : darkColor
            }
        } else {
            return lightColor
        }
    }
    
}
extension UINavigationController {
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        switch traitCollection.userInterfaceStyle {
        case .light:
            return .darkContent
        case .dark:
            return .lightContent
        case .unspecified:
            return .default
        @unknown default:
            return.default
        }
    }
}
