//
//  SelectLangController.swift
//  NewsApp
//
//  Created by Apple on 29/05/23.
//

import UIKit

class SelectLangController: BaseViewController {
    
    
    @IBOutlet weak var lblChoose: UILabel!
    @IBOutlet weak var viewEnglish: UIView!
    @IBOutlet weak var viewArabic: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        // Do any additional setup after loading the view.
    }
    //MARK: - SETUP UI
    func setupUI() {
        if LocalStore.shared.engTrueArabicFalse {
            lblChoose.text = "Choose Language".localalizedString(str: "en")
            setupNavigationBar(title: "Language".localalizedString(str: "en"), img: "", imgRight: "", isBackButton: false, isRightButton: false, isBackButtonItem: false)
        } else {
            lblChoose.text = "Choose Language".localalizedString(str: "ar")
            setupNavigationBar(title: "Language".localalizedString(str: "ar"), img: "", imgRight: "", isBackButton: false, isRightButton: false, isBackButtonItem: false)
        }
        
        lblChoose.textColor = UIColor.setColor(lightColor: .black, darkColor: .black)
        viewArabic.layer.cornerRadius = 7
        viewEnglish.layer.cornerRadius = 7
        if self.traitCollection.userInterfaceStyle == .dark {
            ChangeStayusBarColor()
        } else {
            ChangeStayusBarColorWhite()
        }
        
    }
    //MARK: - Button's Action
    @IBAction func btnEnglish (_ sender: UIButton) {
        LocalStore.shared.engTrueArabicFalse = true
        UIView.appearance().semanticContentAttribute = .forceLeftToRight
        pushToViewController(sb_Id: "LoginController")
    }
    @IBAction func btnArabic (_ sender: UIButton) {
        LocalStore.shared.engTrueArabicFalse = false
        UIView.appearance().semanticContentAttribute = .forceRightToLeft
        pushToViewController(sb_Id: "LoginController")
    }
    
    
    
    
}
