//
//  HomeVC.swift
//  NewsApp
//
//  Created by Apple on 26/05/23.
//

import UIKit

class HomeVC: BaseViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    //MARK: - Update UI
    private func setupUI() {
        if self.traitCollection.userInterfaceStyle == .dark {
            ChangeStayusBarColor()
        } else {
            ChangeStayusBarColorWhite()
        }
        view.backgroundColor = UIColor.setColor(lightColor: .white, darkColor: .black)
        setupNavigationBar(title: "Home", img: "", imgRight: "settings", isBackButton: false, isRightButton: true, isBackButtonItem: true)
    }
    
    
    
    
    
 

}
