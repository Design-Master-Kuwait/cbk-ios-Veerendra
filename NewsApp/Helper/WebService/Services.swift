

import Foundation
import UIKit
import SystemConfiguration
import Alamofire
import NVActivityIndicatorView
import SVProgressHUD


class Services: NSObject {
    
    class func headers() -> HTTPHeaders {
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString
        let headers: HTTPHeaders = [ "api-version":"v1"]
        return headers
    }
    
    class func headers2() -> HTTPHeaders {
        
        let token = "\(UserDefaults.standard.value(forKey: "token") ?? "")"
        let  headers2 : HTTPHeaders =  [
            "Authorization": "Bearer \(token)"
        ]
        
        return headers2
    }
    
    // MARK : With header API Post
    class  func postRequest12(url:String,view:UIView,param:[String:Any],shouldAnimateHudd:Bool,refreshControl:UIRefreshControl? = nil, completionBlock: @escaping ( _ responseObject: Data) -> Void) {
        if (InternetReachability.sharedInstance.isInternetAvailable()) {
            if shouldAnimateHudd {
                LoaderClass.startLoader()
            }
            print("url is ====================== \(url)")
            print("Header is =================== \(Services.headers2())")
            print("param is ==================== \(param)")
            print("=============================")
            AF.request(url, method : .post, parameters : param, encoding : JSONEncoding.default , headers : Services.headers2()).responseJSON { (response:DataResponse) in
                print("StatusCode is =============== \(response.response?.statusCode ?? 1100 )")
                print(response)
                if shouldAnimateHudd {
                    LoaderClass.stopLoader()
                }
                
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
                switch(response.result)
                {
                case .success:
                    if let responseData = response.data {
                        do {
                            if response.response?.statusCode == 200 {
                                completionBlock(responseData)
                            }
                            else if response.response?.statusCode == 400 {
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }  else if response.response?.statusCode == 401 {
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }  else if response.response?.statusCode == 500 {
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }  else if response.response?.statusCode == 550 {
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                        }
                    }
                    else {
                        AlertClass.startAlert(msg:response.error?.localizedDescription ?? "" )
                    }
                case .failure(let error):
                    LoaderClass.stopLoader()
                    print(error.localizedDescription)
                    AlertClass.startAlert(msg:error.localizedDescription ?? "")
                }
            }
        }
        else
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
            }
            AlertClass.startAlert(msg: NOINTERNET)
        }
    }
    
    // MARK : Without header API Post
    
    class  func postRequest01(url:String,view:UIView,param:[String:Any],shouldAnimateHudd:Bool,refreshControl:UIRefreshControl? = nil, completionBlock: @escaping ( _ responseObject: Data) -> Void) {
        if (InternetReachability.sharedInstance.isInternetAvailable()) {
            if shouldAnimateHudd {
                SVProgressHUD.show()
            }
            print("url is ====================== \(url)")
            print("param is ==================== \(param)")
            print("=============================")
            AF.request(url, method : .post, parameters : param, encoding : JSONEncoding.default).responseJSON { (response:DataResponse) in
                print("StatusCode is =============== \(response.response?.statusCode ?? 1100 )")
                print(response)
                if shouldAnimateHudd {
                    SVProgressHUD.dismiss()
                }
                
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
                switch(response.result)
                {
                case .success:
                    if let responseData = response.data {
                        do {
                            if response.response?.statusCode == 200 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                                
                            }
                            else if response.response?.statusCode == 201 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                            else if response.response?.statusCode == 400 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            } else if response.response?.statusCode == 401 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["error"] as? String ?? "")
                                    
                                }
                            } else if response.response?.statusCode == 500 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                    
                                }
                            }
                        }
                    }
                    
                case .failure(let error):
                    print(error.localizedDescription)
                    if let dict = response.value as? [String:Any]{
                        AlertClass.startAlert(msg: error.localizedDescription as? String ?? "")
                    }
                }
            }
        }
        else
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
            }
            AlertClass.startAlert(msg: NOINTERNET)
            
        }
    }
    
    class  func postRequest(url:String,view:UIView,param:[String:Any],shouldAnimateHudd:Bool,refreshControl:UIRefreshControl? = nil, completionBlock: @escaping ( _ responseObject: Data) -> Void) {
        if (InternetReachability.sharedInstance.isInternetAvailable()) {
            if shouldAnimateHudd {
                LoaderClass.startLoader()
            }
            print("url is ====================== \(url)")
            print("param is ==================== \(param)")
            print("=============================")
            AF.request(url, method : .post, parameters : param, encoding : JSONEncoding.default).responseJSON { (response:DataResponse) in
                print("StatusCode is =============== \(response.response?.statusCode ?? 1100 )")
                print(response)
                if shouldAnimateHudd {
                    LoaderClass.stopLoader()
                    
                }
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
                switch(response.result)
                {
                case .success:
                    if let responseData = response.data {
                        do {
                            if response.response?.statusCode == 200 {
                                completionBlock(responseData)
                            }
                            else if response.response?.statusCode == 201 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                            else if response.response?.statusCode == 400 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            } else if response.response?.statusCode == 401 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                            else if response.response?.statusCode == 422 {
                                completionBlock(responseData)
                                AlertClass.startAlert(msg: "The email has already been taken.")
                            }else if response.response?.statusCode == 500 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }else if response.response?.statusCode == 550 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }

                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    AlertClass.startAlert(msg:error.localizedDescription )
                }
            }
        }
        else
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
            }
            AlertClass.startAlert(msg: NOINTERNET )
        }
    }
    
    class  func postRequestWithHeader(url:String,view:UIView,param:[String:Any],shouldAnimateHudd:Bool,refreshControl:UIRefreshControl? = nil, completionBlock: @escaping ( _ responseObject: Data) -> Void) {
        if (InternetReachability.sharedInstance.isInternetAvailable()) {
            if shouldAnimateHudd {
                LoaderClass.startLoader()
            }
            print("url is ====================== \(url)")
            print("param is ==================== \(param)")
            print("=============================")
            AF.request(url, method : .post, parameters : param, encoding : JSONEncoding.default, headers : Services1.headers2()).responseJSON { (response:DataResponse) in
                print("StatusCode is =============== \(response.response?.statusCode ?? 1100 )")
                print(response)
                if shouldAnimateHudd {
                    LoaderClass.stopLoader()
                    
                }
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
                switch(response.result)
                {
                case .success:
                    if let responseData = response.data {
                        do {
                            if response.response?.statusCode == 200 {
                                completionBlock(responseData)
                            }
                            else if response.response?.statusCode == 201 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                            else if response.response?.statusCode == 400 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            } else if response.response?.statusCode == 401 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                            else if response.response?.statusCode == 422 {
                                completionBlock(responseData)
                                AlertClass.startAlert(msg: "The email has already been taken.")
                            }else if response.response?.statusCode == 500 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                            else if response.response?.statusCode == 550 {
                                completionBlock(responseData)
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    AlertClass.startAlert(msg:error.localizedDescription )
                }
            }
        }
        else
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
            }
            AlertClass.startAlert(msg: NOINTERNET )
        }
    }
    
    class  func getRequest(url:String,view:UIView,shouldAnimateHudd:Bool,refreshControl:UIRefreshControl? = nil, completionBlock: @escaping ( _ responseObject: Data) -> Void) {
        if (InternetReachability.sharedInstance.isInternetAvailable()) {
            if shouldAnimateHudd {
                LoaderClass.startLoader()
            }
            print("url is ====================== \(url)")
            print("Header is =================== \(Services1.headers2())")
            print("=============================")
            AF.request(url, method : .get, encoding : JSONEncoding.default , headers : Services1.headers2()).responseJSON { (response:DataResponse) in
                print("StatusCode is =============== \(response.response?.statusCode ?? 1100 )")
                print(response)
                if shouldAnimateHudd {
                    LoaderClass.stopLoader()
                }
                
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
                
                
                switch(response.result)
                {
                case .success:
                    if let responseData = response.data {
                        do {
                            if response.response?.statusCode == 200 {
                                completionBlock(responseData)
                            }
                            else if response.response?.statusCode == 400 {
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }    else if response.response?.statusCode == 401 {
                                if let dict = response.value as? [String:Any]{
                                    AlertClass.startAlert(msg: dict["message"] as? String ?? "")
                                }
                            }
                            
                            else {
                                if let message = response.result as? [String : Any]
                                {
                                    if (message["message"] as? String) != nil
                                    {
                                        let alertController = UIAlertController(title: APPNAME, message:
                                                                                    (message["message"] as? String ?? ""), preferredStyle: .alert)
                                        alertController.view.tintColor = UIColor.black
                                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
                                        }))
                                        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
                                    }
                                    else
                                    {
                                        let alertController = UIAlertController(title: APPNAME, message:
                                                                                    "Server error!", preferredStyle: .alert)
                                        alertController.view.tintColor = UIColor.black
                                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
                                        }))
                                        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                    }
                    else {
                        AlertClass.startAlert(msg: response.error?.localizedDescription ?? "")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    AlertClass.startAlert(msg: error.localizedDescription)
                    
                }
            }
        }
        else
        {
            DispatchQueue.main.async {
                if refreshControl != nil {
                    refreshControl?.endRefreshing()
                }
            }
            AlertClass.startAlert(msg: NOINTERNET)
        }
    }
    

    
}
// MARK:- Loader Class

class LoaderClass {
    
    class func startLoader()
    {
        let activityData = ActivityData(size: nil, message: nil, messageFont: nil, type: NVActivityIndicatorType.orbit, color: .white, padding: 0, displayTimeThreshold: nil, minimumDisplayTime: nil, backgroundColor: NVActivityIndicatorView.DEFAULT_BLOCKER_BACKGROUND_COLOR, textColor: nil)
         NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData)
    }
    
    class func stopLoader()
    {
        NVActivityIndicatorPresenter.sharedInstance.stopAnimating()
    }
}


class Services1: NSObject
{
    class func headers2() -> HTTPHeaders
    {
        let token = "\(UserDefaults.standard.value(forKey: "token") ?? "")"
        let  headers2 : HTTPHeaders = ["Authorization": "Bearer \(token)"]
        return headers2
    }
}
