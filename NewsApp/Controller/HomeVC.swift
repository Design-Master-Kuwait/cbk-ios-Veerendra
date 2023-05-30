//
//  HomeVC.swift
//  NewsApp
//
//  Created by Apple on 26/05/23.
//

import UIKit
import SDWebImage

class HomeVC: BaseViewController {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var txtFld: UITextField!
    private var objHomeVM = HomeVM()
    private var arrayNews = [HomeBaseMDL.HomeData]()
    private var pullControl = UIRefreshControl()
    private let pickerView = ToolbarPickerView()
    private let articles = ["All", "Business", "Entertainment", "General", "Health" ,"Science" ,"Sports", "Technology"]
    private var page = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        setupUI()
    }
    //MARK: - Update UI
    private func setupUI() {
        pullControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        pullControl.addTarget(self, action: #selector(pulledRefreshControl(sender:)), for: UIControl.Event.valueChanged)
        tableview.addSubview(pullControl)
        HomeNews_Api(page: page, isRefresh: false, category: "")
        if self.traitCollection.userInterfaceStyle == .dark {
            ChangeStayusBarColor()
        } else {
            ChangeStayusBarColorWhite()
        }
        view.backgroundColor = UIColor.setColor(lightColor: .white, darkColor: .black)
        setupNavigationBar(title: "Home", img: "", imgRight: "settings", isBackButton: false, isRightButton: true, isBackButtonItem: true, isRightButton2: true, imgRight2: "filter")
        pickerView.delegate = self
        pickerView.dataSource = self
        txtFld.inputView = pickerView
        txtFld.isHidden = true
        txtFld.inputAccessoryView = pickerView.toolbar
        pickerView.toolbarDelegate = self
    }
    
    // MARK: - Pull to refresh
    @objc func pulledRefreshControl(sender:AnyObject) {
        HomeNews_Api(page: page, isRefresh: true, category: "")
        self.pullControl.endRefreshing()
    }

    override func _handrightBackTapped2() {
        txtFld.becomeFirstResponder()
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
            HomeNews_Api(page:page, isRefresh: false, category: "")
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
class cellNewsHome: UITableViewCell {
    @IBOutlet weak var imgNews: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var viewMain: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgNews.clipsToBounds = true
        imgNews.layer.cornerRadius = 7
        imgNews.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        viewMain.addShadowToView()
        
    }
}

//MARK: - Api Integration
extension HomeVC {
    func HomeNews_Api(page:Int, isRefresh:Bool, category:String)
    {
        
        let Req = Home.Request(page: page, category: category)
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
                let totalResult = objHomeVM.HomeMdl?.totalResults!
                self.page += 1
            }
            tableview.reloadData()
        }
    }
}
extension HomeVC: UIPickerViewDataSource, UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.articles.count
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let selectedNews = AppUserDefaults.integer(forKey: "selectedNews")
        return self.articles[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        AppUserDefaults.set(row, forKey: "selectedNews")
    }
}

extension HomeVC: ToolbarPickerViewDelegate {

    func didTapDone() {
        let row = self.pickerView.selectedRow(inComponent: 0)
        self.pickerView.selectRow(row, inComponent: 0, animated: false)
        let category = self.articles[row]
        HomeNews_Api(page: 1, isRefresh: false, category: category)
        tableview.reloadData()
        self.txtFld.resignFirstResponder()
//        pushToViewController(sb_Id: "LoginController")
    }

    func didTapCancel() {
        self.txtFld.text = nil
        self.txtFld.resignFirstResponder()
    }
}
