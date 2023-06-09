//
//  LoginController.swift
//  NewsApp
//
//  Created by Apple on 25/05/23.
//

import UIKit
import LocalAuthentication

class LoginController: BaseViewController {
    
    @IBOutlet weak var viewEmail: UIView!
    @IBOutlet weak var viewPassword: UIView!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var txtFldEmail: UITextField!
    @IBOutlet weak var txtFldPassword: UITextField!
    private let biometricIDAuth = BiometricIDAuth()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Update UI
    private func setupUI()
    {
        
        DispatchQueue.main.async {
            self.txtFldEmail.showGradientSkeleton()
            self.txtFldPassword.showGradientSkeleton()
            self.btnLogin.showGradientSkeleton()
            self.viewEmail.showGradientSkeleton()
            self.viewPassword.showGradientSkeleton()
            self.txtFldEmail.isUserInteractionDisabledWhenSkeletonIsActive = true
            self.txtFldPassword.isUserInteractionDisabledWhenSkeletonIsActive = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.txtFldEmail.hideSkeleton()
            self.txtFldPassword.hideSkeleton()
            self.btnLogin.hideSkeleton()
            self.viewEmail.hideSkeleton()
            self.viewPassword.hideSkeleton()
        }
        
        if LocalStore.shared.engTrueArabicFalse {
            txtFldEmail.placeholder = "Email".localalizedString(str: "en")
            txtFldPassword.placeholder = "Password".localalizedString(str: "en")
            btnLogin.setTitle("Login".localalizedString(str: "en"), for: .normal)
            txtFldEmail.textAlignment = .left
            txtFldPassword.textAlignment = .left
            setupNavigationBar(title: "Login".localalizedString(str: "en"), img: "back", imgRight: "", isBackButton: false, isRightButton: false, isBackButtonItem: true, isRightButton2: false, imgRight2: "",leftButton2: false, leftButton2Img: "", isCountrySelected: false)
        } else {
            
            txtFldEmail.placeholder = "Email".localalizedString(str: "ar")
            txtFldPassword.placeholder = "Password".localalizedString(str: "ar")
            btnLogin.setTitle("Login".localalizedString(str: "ar"), for: .normal)
            txtFldEmail.textAlignment = .right
            txtFldPassword.textAlignment = .right
            setupNavigationBar(title: "Login".localalizedString(str: "ar"), img: "back", imgRight: "", isBackButton: false, isRightButton: false, isBackButtonItem: true, isRightButton2: false, imgRight2: "",leftButton2: false, leftButton2Img: "", isCountrySelected: false)
        }
        txtFldEmail.placeholderColor(color: UIColor.setColor(lightColor: #colorLiteral(red: 170/255, green: 170/255, blue: 170/255, alpha: 1), darkColor: #colorLiteral(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)))
        txtFldPassword.placeholderColor(color: UIColor.setColor(lightColor: #colorLiteral(red: 170/255, green: 170/255, blue: 170/255, alpha: 1), darkColor: #colorLiteral(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)))
        
        if self.traitCollection.userInterfaceStyle == .dark {
            ChangeStayusBarColor()
            txtFldEmail.textColor = .black
            txtFldPassword.textColor = .black
        } else {
            txtFldEmail.textColor = .black
            txtFldPassword.textColor = .black
            ChangeStayusBarColorWhite()
        }
        viewEmail.addShadowToView()
        viewPassword.addShadowToView()
        btnLogin.addShadowToButton()
        setNeedsStatusBarAppearanceUpdate()
        let email = KeyChainWrapper.retriveValue(id: "email")
        let password = KeyChainWrapper.retriveValue(id: "password")
        if email != "" && password != ""{
            biometric()
        }
    }
    
    func biometric() {
        biometricIDAuth.canEvaluate { (canEvaluate, _, canEvaluateError) in
            guard canEvaluate else {
                AlertClass.alert(title: "Error",
                                 message: canEvaluateError?.localizedDescription ?? "Face ID/Touch ID may not be configured",
                                 okActionTitle: "OK")
                return
            }
            
            biometricIDAuth.evaluate { (success, error) in
                guard success else {
                    AlertClass.alert(title: "Error",
                                     message: error?.localizedDescription ?? "Face ID/Touch ID may not be configured",
                                     okActionTitle: "OK")
                    return
                }
                self.pushToViewController(sb_Id: "HomeVC")
                
            }
        }
    }
    // MARK: - Button's Action
    @IBAction func btnLogin (_ sender:UIButton) {
        loginValidation()
    }
    @IBAction func btnFingerprint (_ sender:UIButton) {
        
    }
    
    
}
extension LoginController {
    
    // MARK : - LOGIN VALIDATIONS
    
    func loginValidation()
    {
        Global.email = txtFldEmail.text ?? ""
        Global.password = txtFldPassword.text ?? ""
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
