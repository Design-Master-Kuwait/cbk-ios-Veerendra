

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

