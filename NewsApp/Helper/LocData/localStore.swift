


import Foundation

class LocalStore {
    
    // Shared instance
    static let shared = LocalStore()
    // Auth Session Access Token
    var engTrueArabicFalse: Bool!
    {
        get {
            return UserDefaults.standard.value(forKey: "engTrueArabicFalse") as? Bool
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "engTrueArabicFalse")
        }
        
    }
}
