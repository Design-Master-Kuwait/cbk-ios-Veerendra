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
        setupUI()
    }
    //MARK: - Update UI
    private func setupUI() {
        COUNTRIES_DATA()
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(pulledRefreshControl(sender:)), for: UIControl.Event.valueChanged)
        tableview.addSubview(pullControl)
        HomeNews_Api(page: Global.page, isRefresh: false, category: "", country: Global.country)
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
        HomeNews_Api(page: Global.page, isRefresh: true, category: Global.category, country: Global.country)
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
        return arrayNews.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellNewsHome") as! cellNewsHome? else {
            fatalError()
        }
        
        cell.imgNews.sd_setImage(with: URL(string: (arrayNews[indexPath.row].urlToImage) ?? ""), placeholderImage: UIImage(named: "news"))
        cell.lblTitle.text = arrayNews[indexPath.row].title
        if indexPath.row == (arrayNews.count) - 1{
            HomeNews_Api(page:Global.page, isRefresh: false, category: Global.category, country: Global.country)
        }
        
        return cell
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
            print((objHomeVM.HomeMdl?.articles!.count)!)
            for i in objHomeVM.HomeMdl!.articles!{
                self.arrayNews.append(i)
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
