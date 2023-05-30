//
//  HomVM.swift
//  NewsApp
//
//  Created by Apple on 29/05/23.
//

import Foundation
import UIKit

class HomeVM {

        var HomeMdl : HomeBaseMDL?
    
         var window: UIWindow?
    
    func hitHomeMethod(request : Home.Request,viewCont : UIViewController,completion:@escaping() -> Void){
        
        
        let page = request.page ?? 1
        let category = request.category ?? ""
        let url = API.NewsHome_Api + "country=\("in")&apiKey=\("a9f7b40a4b1b47009caf85e25f6a998f")&page=\(page)&category=\(category)"
        
            Services.getRequest(url: url,view: viewCont.view, shouldAnimateHudd: true) { (responseData) in
                
                do {
                    self.HomeMdl = try JSONDecoder().decode(HomeBaseMDL.self, from: responseData)
                    if self.HomeMdl?.status == "ok" {
                        completion()
                    }
                }
                catch {
                 
                    
                }
            }
        }
  
    }