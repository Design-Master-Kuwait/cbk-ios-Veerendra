//
//  SelectLangController.swift
//  NewsApp
//
//  Created by Apple on 29/05/23.
//

import UIKit
import SkeletonView

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
        DispatchQueue.main.async {
            self.lblChoose.showGradientSkeleton()
            self.viewEnglish.showGradientSkeleton()
            self.viewArabic.showGradientSkeleton()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.lblChoose.hideSkeleton()
            self.viewEnglish.hideSkeleton()
            self.viewArabic.hideSkeleton()
        }
        
        if LocalStore.shared.engTrueArabicFalse {
            lblChoose.text = "Choose Language".localalizedString(str: "en")
            setupNavigationBar(title: "Language".localalizedString(str: "en"), img: "", imgRight: "", isBackButton: false, isRightButton: false, isBackButtonItem: false, isRightButton2: false, imgRight2: "",leftButton2: false, leftButton2Img: "", isCountrySelected: false)
        } else {
            lblChoose.text = "Choose Language".localalizedString(str: "ar")
            setupNavigationBar(title: "Language".localalizedString(str: "ar"), img: "", imgRight: "", isBackButton: false, isRightButton: false, isBackButtonItem: false, isRightButton2: false, imgRight2: "",leftButton2: false, leftButton2Img: "", isCountrySelected: false)
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
    //    override var preferredStatusBarStyle: UIStatusBarStyle {
    //        switch traitCollection.userInterfaceStyle {
    //        case .light:
    //            return .darkContent
    //        case .dark:
    //            return .lightContent
    //        case .unspecified:
    //            return .default
    //        @unknown default:
    //            return.default
    //        }
    //    }
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
