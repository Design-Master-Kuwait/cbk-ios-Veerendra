//
//  ArticleTable.swift
//  DBData
//
//  Created by apple on 01/06/23.
//

import Foundation
import RealmSwift

class ArticleTable: Object {
    
    // Primary Key Declaration
    override static func primaryKey() -> String {
        return "id"
    }
    //
    
    @objc dynamic var id = ""
    @objc dynamic var status = ""
    @objc dynamic var totalResults = 0
    @objc dynamic var author = ""
    @objc dynamic var sourceId = ""
    @objc dynamic var sourceName = ""
    @objc dynamic var title = ""
    @objc dynamic var Description = ""
    @objc dynamic var url = ""
    @objc dynamic var urlToImage = ""
    @objc dynamic var publishedAt = ""
    @objc dynamic var content = ""
}
