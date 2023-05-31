//
//  HomeBaseMDL.swift
//  NewsApp
//
//  Created by Apple on 29/05/23.
//

import Foundation

struct HomeBaseMDL : Codable {
    
    var status : String?
    var totalResults : Int?
    var articles : [HomeData]?
    
    struct HomeData : Codable {
        
        var source : Source?
        var author : String?
        var title : String?
        var description : String?
        var url : String?
        var urlToImage : String?
        var publishedAt : String?
        var content : String?
        
        
        struct Source : Codable {
            var id : String?
            var name : String?
        }
    }
    
}


