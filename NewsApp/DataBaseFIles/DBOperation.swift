//
//  DBOperation.swift
//  DBData
//
//  Created by apple on 01/06/23.
//

import Foundation
import RealmSwift

// -----------------Delete partner List Data ----------------

func deletePartnertableData() {
    var partnerData: Results<ArticleTable>!
    do {
        let realm = try Realm()
        partnerData = realm.objects(ArticleTable.self)
        if partnerData.count > 0 {
            try realm.write {
                realm.delete(partnerData)
            }
        }
    } catch { print("error is: \(error)")}
}

// -----------------Save partner List Data ----------------

func saveArticleData(id: String, sourceId: String, status: String, totalResults: Int, sourceName: String, author: String, title: String, Description: String, url: String, urlToImage: String, publishedAt: String, content: String ) {
    guard let realm = try? Realm() else { return }
    let partnerData = ArticleTable()
    partnerData.id = id
    partnerData.status = status
    partnerData.totalResults = totalResults
    partnerData.sourceId = sourceId
    partnerData.sourceName = sourceName
    partnerData.author = author
    partnerData.title = title
    partnerData.Description = Description
    partnerData.url = url
    partnerData.urlToImage = urlToImage
        partnerData.publishedAt = publishedAt
        partnerData.content = content
    do {   try realm.write {realm.add(partnerData, update: .all)}
    } catch {
        print("error is: \(error)")
        
    }
}

// -----------------Fetch Article List Data ----------------

func fetchArticleTableData() -> Results<ArticleTable>! {
    
    var dbfetchPartnerTableData: Results<ArticleTable>!
    do {
        let realm = try Realm()
            dbfetchPartnerTableData = realm.objects(ArticleTable.self)
    } catch { print("error is: \(error)") }
    return dbfetchPartnerTableData
}

func  getTrackingId(screenName: String) -> String {
    guard let version = Bundle.main.infoDictionary!["CFBundleVersion"]! as? String else { return ""}
    let currentDate = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMddyyyyhhmmss"
    let convertedDate: String = dateFormatter.string(from: currentDate)
    return "\(screenName)\(convertedDate)\("_")\(version)"
}
