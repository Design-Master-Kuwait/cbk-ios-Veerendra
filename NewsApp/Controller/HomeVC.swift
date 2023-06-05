//
//  HomeVC.swift
//  NewsApp
//
//  Created by Apple on 26/05/23.
//

import UIKit
import SDWebImage
import CoreData
import SwiftyJSON


class HomeVC: BaseViewController {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var txtFld: UITextField!
    private var objHomeVM = HomeVM()
    private var arrayNews = [HomeBaseMDL.HomeData]()
    private var pullControl = UIRefreshControl()
    private let pickerView = ToolbarPickerView()
    private let articles = ["All", "Business", "Entertainment", "General", "Health" ,"Science" ,"Sports", "Technology"]
    private var arrCountries = [countryNames]()
    private var isCountrySelected = false
    private var status = ""
    private var totalResults = 0
    var isLoaded = false
    var selected: String {
        return AppUserDefaults.string(forKey: "selectedNews") ?? ""
    }
    var selectedCountry: String {
        return AppUserDefaults.string(forKey: "country") ?? ""
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        self.isLoaded = false
        setupUI()
    }
    //MARK: - Update UI
    private func setupUI() {
        COUNTRIES_DATA()
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(pulledRefreshControl(sender:)), for: UIControl.Event.valueChanged)
        tableview.addSubview(pullControl)
        
        if self.traitCollection.userInterfaceStyle == .dark {
            ChangeStayusBarColor()
        } else {
            ChangeStayusBarColorWhite()
        }
        view.backgroundColor = UIColor.setColor(lightColor: .white, darkColor: .black)
        let isFilterApplied = AppUserDefaults.bool(forKey: "isFilterApplied")
        if isFilterApplied{
            setupNavigationBar(title: "Home", img: "", imgRight: "settings", isBackButton: false, isRightButton: true, isBackButtonItem: true, isRightButton2: true, imgRight2: "filterSelected",leftButton2: true, leftButton2Img: "countrySelected", isCountrySelected: true)
        } else {
            setupNavigationBar(title: "Home", img: "", imgRight: "settings", isBackButton: false, isRightButton: true, isBackButtonItem: true, isRightButton2: true, imgRight2: "filter",leftButton2: true, leftButton2Img: "country", isCountrySelected: true)
        }
        
        if (InternetReachability.sharedInstance.isInternetAvailable()) {
            HomeNews_Api(page: Global.page, isRefresh: false, category: "", country: Global.country)
        } else {
            for i in fetchArticleTableData(){
                let src: HomeBaseMDL.HomeData.Source = HomeBaseMDL.HomeData.Source(id: i.sourceId, name: i.sourceName)
                let arr = HomeBaseMDL.HomeData(source: src, author: i.author, title: i.title, description: i.description, url: i.url, urlToImage: i.urlToImage, publishedAt: i.publishedAt, content: i.content)
                arrayNews.append(arr)
            }
            self.isLoaded = true
            tableview.reloadData()
        }
        
        
        
        pickerView.delegate = self
        pickerView.dataSource = self
        txtFld.inputView = pickerView
        txtFld.isHidden = true
        txtFld.inputAccessoryView = pickerView.toolbar
        pickerView.toolbarDelegate = self
        if isCountrySelected {
            pickerView.selectRow(Global.selectCount, inComponent: 0, animated: true)
            pickerView.reloadAllComponents()
        }else {
            if let row = articles.firstIndex(of: selected) {
                pickerView.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }
    
    // MARK: - Pull to refresh
    @objc func pulledRefreshControl(sender:AnyObject) {
        
        if InternetReachability.sharedInstance.isInternetAvailable(){
            HomeNews_Api(page: Global.page, isRefresh: true, category: Global.category, country: Global.country)
            
        }else {
            for i in fetchArticleTableData(){
                let src: HomeBaseMDL.HomeData.Source = HomeBaseMDL.HomeData.Source(id: i.sourceId, name: i.sourceName)
                let arr = HomeBaseMDL.HomeData(source: src, author: i.author, title: i.title, description: i.description, url: i.url, urlToImage: i.urlToImage, publishedAt: i.publishedAt, content: i.content)
                arrayNews.append(arr)
            }
            tableview.reloadData()
        }
        self.pullControl.endRefreshing()
    }
    
    // MARK: - Button's Action
    override func _handrightBackTapped2() {
        if let row = articles.firstIndex(of: selected) {
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
        isCountrySelected = false
        txtFld.becomeFirstResponder()
        pickerView.reloadAllComponents()
    }
    override func _handleftnBackTapped2() {
        pickerView.selectRow(Global.selectCount, inComponent: 0, animated: true)
        pickerView.reloadAllComponents()
        isCountrySelected = true
        txtFld.becomeFirstResponder()
        pickerView.reloadAllComponents()
    }
    
    
}
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = 0
        if self.isLoaded{
            count = arrayNews.count
        }else{
            count = 10
        }
        return count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellNewsHome") as! cellNewsHome? else {
            fatalError()
        }
        if self.isLoaded{
            cell.hideSkeleton()
            cell.imgNews.sd_setImage(with: URL(string: (arrayNews[indexPath.row].urlToImage) ?? ""), placeholderImage: UIImage(named: "news"))
            cell.lblTitle.text = arrayNews[indexPath.row].title
            if InternetReachability.sharedInstance.isInternetAvailable(){
                if indexPath.row == (arrayNews.count) - 1{
                    HomeNews_Api(page:Global.page, isRefresh: false, category: Global.category, country: Global.country)
                }
            }else {
                
            }
            
        } else {
            cell.showAniamtion()
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let news = NewsStruct(title: arrayNews[indexPath.row].title ?? "", desc: arrayNews[indexPath.row].description ?? "", img: arrayNews[indexPath.row].urlToImage ?? "")
        do {
            try AppUserDefaults.setObject(news, forKey: "NewsObject")
            pushToViewController(sb_Id: "HomeDetailsController")
        } catch {
            print(error.localizedDescription)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
}
class cellNewsHome: UITableViewCell {
    @IBOutlet weak var imgNews: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewMain: UIView!
    @IBOutlet weak var viewBottomShadow: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgNews.sd_imageIndicator = SDWebImageActivityIndicator.white
        imgNews.sd_imageIndicator?.startAnimatingIndicator()
        imgNews.clipsToBounds = true
        imgNews.layer.cornerRadius = 12
        viewBottomShadow.clipsToBounds = true
        viewBottomShadow.layer.cornerRadius = 12
        viewBottomShadow.layer.maskedCorners = [ .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        viewMain.addShadowToView()
        let clear = UIColor.clear
        let grayColor = UIColor.black
        let colours:[CGColor] = [grayColor.cgColor, clear.cgColor]
        viewBottomShadow.layer.sublayers?.removeAll()
        viewBottomShadow.applyGradient(colors: colours, locations: [0.0, 1.0], direction: .bottomToTop)
        viewBottomShadow.clipsToBounds = true
        
    }
    
    func showAniamtion() {
        imgNews.showAnimatedSkeleton()
        lblTitle.showGradientSkeleton()
        viewMain.showAnimatedSkeleton()
        viewBottomShadow.showAnimatedSkeleton()
    }
    
    func hideAnimation() {
        imgNews.hideSkeleton()
        lblTitle.hideSkeleton()
        viewMain.hideSkeleton()
        lblTitle.hideSkeleton()
    }
}

//MARK: - Api Integration
extension HomeVC {
    func HomeNews_Api(page:Int, isRefresh:Bool, category:String, country:String)
    {
        
        let Req = Home.Request(page: page, category: category, country: country)
        objHomeVM.hitHomeMethod(request: Req, viewCont: self){ [self] in
            print("All Ok Data")
            if isRefresh{
                arrayNews.removeAll()
            }
            if objHomeVM.HomeMdl?.status == "ok" {
                if let list = objHomeVM.HomeMdl?.articles {
                    self.status = objHomeVM.HomeMdl?.status ?? ""
                    self.totalResults = objHomeVM.HomeMdl?.totalResults ?? 0
                    
                    for i in objHomeVM.HomeMdl!.articles!{
                        self.arrayNews.append(i)
                    }
                    self.isLoaded = true
                    // Save ArticleDetails in DB
                    self.saveArticleTableData(arr: arrayNews)
                }
            } else {
                print("Error", objHomeVM)
            }
            if isRefresh == false{
                Global.page += 1
            }
            
            
            tableview.reloadData()
        }
    }
    
    func COUNTRIES_DATA() {
        if let url = Bundle.main.url(forResource: "countries", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode([countryNames].self, from: data)
                print(jsonData)
                self.arrCountries = jsonData
                self.pickerView.reloadAllComponents()
            } catch {
                print("error:\(error)")
            }
        }
    }
}
extension HomeVC: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if isCountrySelected{
            return arrCountries.count
        } else {
            return self.articles.count
        }
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if isCountrySelected{
            return self.arrCountries[row].name
        } else {
            let selectedNews = AppUserDefaults.integer(forKey: "selectedNews")
            return self.articles[row]
        }
        
    }
}

extension HomeVC: ToolbarPickerViewDelegate {
    
    func didTapDone() {
        if isCountrySelected{
            let row = self.pickerView.selectedRow(inComponent: 0)
            self.pickerView.selectRow(row, inComponent: 0, animated: false)
            let country = self.arrCountries[row].code
            Global.country = country
            Global.selectCount = row
            arrayNews.removeAll()
            AppUserDefaults.set(country, forKey: "countrySelected")
            HomeNews_Api(page: 1, isRefresh: false, category: "", country: Global.country)
            tableview.reloadData()
            self.txtFld.resignFirstResponder()
            //            AppUserDefaults.set(true, forKey: "isFilterApplied")
            setupNavigationBar(title: "Home", img: "", imgRight: "settings", isBackButton: false, isRightButton: true, isBackButtonItem: true, isRightButton2: true, imgRight2: "filterSelected", leftButton2: true, leftButton2Img: "countrySelected", isCountrySelected: true)
        }
        else
        {
            let row = self.pickerView.selectedRow(inComponent: 0)
            self.pickerView.selectRow(row, inComponent: 0, animated: false)
            let category = self.articles[row]
            arrayNews.removeAll()
            if category == "All"{
                HomeNews_Api(page: 1, isRefresh: false, category: "", country: Global.country)
            }else {
                HomeNews_Api(page: 1, isRefresh: false, category: category, country: Global.country)
            }
            AppUserDefaults.set(category, forKey: "selectedNews")
            Global.category = category
            tableview.reloadData()
            self.txtFld.resignFirstResponder()
            AppUserDefaults.set(true, forKey: "isFilterApplied")
            setupNavigationBar(title: "Home", img: "", imgRight: "settings", isBackButton: false, isRightButton: true, isBackButtonItem: true, isRightButton2: true, imgRight2: "filterSelected", leftButton2: true, leftButton2Img: "countrySelected", isCountrySelected: true)
        }
    }
    
    func didTapCancel() {
        self.txtFld.text = nil
        self.txtFld.resignFirstResponder()
    }
}
extension HomeVC {
    // Save Partner List Into Local DB
    func saveArticleTableData(arr: [HomeBaseMDL.HomeData]) {
//        deletePartnertableData()
        
        var pIncr: Int  = 0
        
        let articleDataList = arr
        if articleDataList.count > 0 {
            for articleDetails in articleDataList {
                pIncr += 1
                saveArticleData(id:  getTrackingId(screenName: "\(pIncr)"), sourceId: articleDetails.source?.id ?? "", status: self.status, totalResults: self.totalResults ,sourceName: articleDetails.source?.name ?? "", author: articleDetails.author ?? "", title: articleDetails.title ?? "", Description: articleDetails.description ?? "", url: articleDetails.url ?? "", urlToImage: articleDetails.urlToImage ?? "", publishedAt: articleDetails.publishedAt ?? "", content: articleDetails.content ?? "")
            }
        }
    }
}
