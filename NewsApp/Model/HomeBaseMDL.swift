//
//  HomeBaseMDL.swift
//  NewsApp
//
//  Created by Apple on 29/05/23.
//

import Foundation

struct HomeBaseMDL : Codable {
    
    let status : String?
    let totalResults : Int?
    let articles : [HomeData]?
    
    struct HomeData : Codable {
        
        let source : Source?
        let author : String?
        let title : String?
        let description : String?
        let url : String?
        let urlToImage : String?
        let publishedAt : String?
        let content : String?
        
        
        struct Source : Codable {
            let id : String?
            let name : String?
        }
    }
    
}


