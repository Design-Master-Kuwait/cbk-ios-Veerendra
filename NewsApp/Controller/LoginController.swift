//
//  LoginController.swift
//  NewsApp
//
//  Created by Apple on 25/05/23.
//

import UIKit

class LoginController: BaseViewController {
    
    @IBOutlet weak var viewEmail: UIView!
    @IBOutlet weak var viewPassword: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var txtFldEmail: UITextField!
    @IBOutlet weak var txtFldPassword: UITextField!
    @IBOutlet weak var btnFingerprint: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Update UI
    private func setupUI()
    {
        
        setupNavigationBar(title: "Login", img: "back", imgRight: "", isBackButton: false, isRightButton: false, isBackButtonItem: true)
        viewEmail.addShadowToView()
        viewPassword.addShadowToView()
        btnLogin.addShadowToButton()
        UserDefaults.standard.set(true, forKey: "engTrueArabicFalse")
        let userId = KeyChainWrapper.retriveValue(id: "UserId")
        if userId == ""{
            btnFingerprint.isHidden = true
        } else {
            btnFingerprint.isHidden = false
        }
    }
    // MARK: - Button's Action
    @IBAction func btnLogin (_ sender:UIButton) {
        loginValidation()
    }
    @IBAction func btnFingerprint (_ sender:UIButton) {
        authenticationWithTouchID()
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            let userId = KeyChainWrapper.retriveValue(id: "UserId")
            if userId == "" {
                print("Not available")
            } else {
                let vc = storyboard?.instantiateViewController(withIdentifier: "HomeVC")
                navigationController?.pushViewController(vc!, animated: true)
            }
        }
    }
    
    
}
extension LoginController {
    
    // MARK : - LOGIN VALIDATIONS
    
    func loginValidation()
    {
        if LocalStore.shared.engTrueArabicFalse {
            let emailText = txtFldEmail.text ?? ""
            let passWordText = txtFldPassword.text ?? ""
            if emailText.isEmpty
            {
                presentAlert(withTitle: kOops, message: kEnterEmail)
                return
            }
            if passWordText.isEmpty {
                presentAlert(withTitle: kOops, message: kEnterPassword)
                return
            }
            if emailText.isEmail() {
                print("Okay Email go ahead")
            }else{
                presentAlert(withTitle: kOops, message: kEnterValidEmail)
            }
            if (txtFldEmail.text != nil) && (txtFldPassword.text != nil)
            {
                let vc = storyboard?.instantiateViewController(withIdentifier: "HomeVC")
                navigationController?.pushViewController(vc!, animated: true)
            }
        } else {
            let emailText = txtFldEmail.text ?? ""
            let passWordText = txtFldPassword.text ?? ""
            if emailText.isEmpty
            {
                presentAlert(withTitle: kArbOops, message: kArbEnterEmail)
                return
            }
            if passWordText.isEmpty {
                presentAlert(withTitle: kArbOops, message: kArbEnterPassword)
                return
            }
            if emailText.isEmail()
            {
                print("Okay Email go ahead")
            } else {
                presentAlert(withTitle: kArbOops, message: kArbEnterValidEmail)
            }
            if (txtFldEmail.text != nil) && (txtFldPassword.text != nil)
            {
                let vc = storyboard?.instantiateViewController(withIdentifier: "HomeVC")
                navigationController?.pushViewController(vc!, animated: true)
            }
        }
        
    }
    
}
