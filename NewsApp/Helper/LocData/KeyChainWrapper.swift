//
//  KeyChainWrapper.swift
//  NewsApp
//
//  Created by Apple on 26/05/23.
//

import Foundation
import UIKit
import Security

class KeyChainWrapper {
    
    class func retriveValue(id:String) -> String {
        var result = ""
        if let UserId = KeyChainWrapper.load(key: id) {
            result = KeyChainWrapper.NSDATAtoString(data: UserId)
        }
        return result
    }
        
        
    class func save(key: String, data: NSData) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func load(key: String) -> NSData? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]
        
        var dataTypeRef:AnyObject? = nil
        
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr {
            return (dataTypeRef! as! NSData)
        } else {
            return nil
        }
    }
    
    public class func Delete(key: String)  {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
      }
    
    class func stringToNSDATA(string : String)->NSData{
        let _Data = (string as NSString).data(using: NSUTF8StringEncoding)
        return _Data! as NSData
        
    }
    class func NSDATAtoString(data: NSData)->String{
        let returned_string : String = NSString(data: data as Data, encoding: NSUTF8StringEncoding)! as String
        return returned_string
    }
    
    class func intToNSDATA(r_Integer : Int)->NSData{
        var SavedInt: Int = r_Integer
        let _Data = withUnsafeBytes(of: SavedInt) { Data($0) }
        return _Data as NSData
        
    }
        
    class func NSDATAtoInteger(_Data : NSData) -> Int{
        var RecievedValue : Int = Data(referencing: _Data).withUnsafeBytes {
            $0.load(as: Int.self)
        }
        return RecievedValue
    }
}
