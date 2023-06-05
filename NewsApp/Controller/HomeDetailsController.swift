//
//  HomeDetailsController.swift
//  NewsApp
//
//  Created by Apple on 05/06/23.
//

import UIKit
import SDWebImage

protocol ObjectSavable {
    func setObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable
    func getObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable
}

class HomeDetailsController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    var arrayDetails = [NewsStruct]()
    private var pullControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(pulledRefreshControl(sender:)), for: UIControl.Event.valueChanged)
        tableview.addSubview(pullControl)
        
        do {
            let news = try AppUserDefaults.getObject(forKey: "NewsObject", castTo: NewsStruct.self)
            print(news)
            arrayDetails.append(news)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    // MARK: - Pull to refresh
    @objc func pulledRefreshControl(sender:AnyObject) {
        arrayDetails.removeAll()
        do {
            let news = try AppUserDefaults.getObject(forKey: "NewsObject", castTo: NewsStruct.self)
            print(news)
            arrayDetails.append(news)
        } catch {
            print(error.localizedDescription)
        }
        self.pullControl.endRefreshing()
    }
   
}
extension HomeDetailsController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellDetails") as! cellDetails? else {
            fatalError()
        }
        print(arrayDetails[indexPath.row].img)
        cell.imgShow.sd_setImage(with: URL(string: arrayDetails[indexPath.row].img), placeholderImage: UIImage(named: "news"))
        cell.lblTitle.text = arrayDetails[indexPath.row].title
        cell.lblDesc.text = arrayDetails[indexPath.row].desc
        
        return cell
    }
    
    
}
extension UserDefaults: ObjectSavable {
    func setObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            set(data, forKey: forKey)
        } catch {
            throw ObjectSavableError.unableToEncode
        }
    }
    
    func getObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable {
        guard let data = data(forKey: forKey) else { throw ObjectSavableError.noValue }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            throw ObjectSavableError.unableToDecode
        }
    }
}

enum ObjectSavableError: String, LocalizedError {
    case unableToEncode = "Unable to encode object into data"
    case noValue = "No data object found for the given key"
    case unableToDecode = "Unable to decode object into given type"
    
    var errorDescription: String? {
        rawValue
    }
}
struct NewsStruct: Codable {
    var title: String
    var desc: String
    var img: String
}
class cellDetails: UITableViewCell {
    @IBOutlet weak var imgShow: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var viewBottomShadow: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let clear = UIColor.clear
        let grayColor = UIColor.black
        let colours:[CGColor] = [grayColor.cgColor, clear.cgColor]
        viewBottomShadow.layer.sublayers?.removeAll()
        viewBottomShadow.applyGradient(colors: colours, locations: [0.0, 1.0], direction: .bottomToTop)
        viewBottomShadow.clipsToBounds = true
    }
}
