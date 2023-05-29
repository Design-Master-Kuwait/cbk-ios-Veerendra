//
//  NavigationBarNew.swift
//  NewsApp
//
//  Created by Apple on 26/05/23.
//

import UIKit
import LocalAuthentication


class BaseViewController: UIViewController {

  
    
    
    // --------------------------------------------------------
    // MARK: - Navigation Bar Setup
    // --------------------------------------------------------
    public func setupNavigationBar(title:String, img:String, imgRight:String, isBackButton:Bool, isRightButton:Bool, isBackButtonItem:Bool) {
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.backgroundColor = UIColor.setColor(lightColor: UIColor.white, darkColor: .black)
        self.view.backgroundColor = .white
        let separator = UILabel(frame: CGRect(x: 0, y: (navigationController?.navigationBar.frame.size.height)!, width: (navigationController?.navigationBar.frame.size.width)!, height: 0.5))
        separator.backgroundColor =  #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        navigationController?.navigationBar.addSubview(separator)
        
        
        if isBackButtonItem{
            self.navigationItem.setHidesBackButton(true, animated: true)
        } else {
            self.navigationItem.setHidesBackButton(false, animated: true)
        }
        setupNavigationBarItems(title: title, img: img, isBackButton: isBackButton, isRight: isRightButton, imgRight: imgRight)
    }
    
    public func setupNavigationBarItems(title:String, img:String, isBackButton:Bool, isRight:Bool, imgRight:String) {
        navigationItem.title = title
        
        if isBackButton{
            setupLeftNavigationBar(img: img)
        } else
        
        if isRight{
            setupRightNavigationBar(img: imgRight)
        }
    }
    
    public func setupLeftNavigationBar(img:String) {
        let btnBack = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        btnBack.setImage(UIImage(named: img), for: .normal)
        btnBack.addTarget(self, action: #selector(_handleftnBackTapped), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btnBack)
    }
    
    public func setupRightNavigationBar(img:String) {
        let btnSettings = UIButton(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
        btnSettings.setImage(UIImage(named: img), for: .normal)
        btnSettings.addTarget(self, action: #selector(_handrightBackTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btnSettings)
    }
    

    // --------------------------------------------------------
    // MARK: - Button Action
    // --------------------------------------------------------

    @objc fileprivate func _handleftnBackTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func _handrightBackTapped() {
        pushToViewController(sb_Id: "SettingsController")
    }
    
    
    
    
    
    // --------------------------------------------------------
    // MARK: - Touch unlock
    // --------------------------------------------------------
    func authenticationWithTouchID() {
            let localAuthenticationContext = LAContext()
            localAuthenticationContext.localizedFallbackTitle = "Username"

            var authError: NSError?
            let reasonString = "To access the secure data"

            if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                
                localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { success, evaluateError in
                    
                    if success {
                        
                        let userId = KeyChainWrapper.retriveValue(id: "UserId")
                        if userId == "" {
                            print("Not available")
                        } else {
                            let vc = self.storyboard?.instantiateViewController(withIdentifier: "HomeVC")
                            self.navigationController?.pushViewController(vc!, animated: true)
                        }
                        
                        //TODO: User authenticated successfully, take appropriate action
                        
                    } else {
                        //TODO: User did not authenticate successfully, look at error and take appropriate action
                        guard let error = evaluateError else {
                            return
                        }
                        
                        print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                        
                        //TODO: If you have choosen the 'Fallback authentication mechanism selected' (LAError.userFallback). Handle gracefully
                        
                    }
                }
            } else {
                
                guard let error = authError else {
                    return
                }
                //TODO: Show appropriate alert if biometry/TouchID/FaceID is lockout or not enrolled
                print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code))
            }
        }
        
        func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
            var message = ""
            if #available(iOS 11.0, macOS 10.13, *) {
                switch errorCode {
                    case LAError.biometryNotAvailable.rawValue:
                        message = "Authentication could not start because the device does not support biometric authentication."
                    
                    case LAError.biometryLockout.rawValue:
                        message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
                    
                    case LAError.biometryNotEnrolled.rawValue:
                        message = "Authentication could not start because the user has not enrolled in biometric authentication."
                    
                    default:
                        message = "Did not find error code on LAError object"
                }
            } else {
                switch errorCode {
                    case LAError.touchIDLockout.rawValue:
                        message = "Too many failed attempts."
                    
                    case LAError.touchIDNotAvailable.rawValue:
                        message = "TouchID is not available on the device"
                    
                    case LAError.touchIDNotEnrolled.rawValue:
                        message = "TouchID is not enrolled on the device"
                    
                    default:
                        message = "Did not find error code on LAError object"
                }
            }
            
            return message;
        }
        
        func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
            
            var message = ""
            
            switch errorCode {
                
            case LAError.authenticationFailed.rawValue:
                message = "The user failed to provide valid credentials"
                
            case LAError.appCancel.rawValue:
                message = "Authentication was cancelled by application"
                
            case LAError.invalidContext.rawValue:
                message = "The context is invalid"
                
            case LAError.notInteractive.rawValue:
                message = "Not interactive"
                
            case LAError.passcodeNotSet.rawValue:
                message = "Passcode is not set on the device"
                
            case LAError.systemCancel.rawValue:
                message = "Authentication was cancelled by the system"
                
            case LAError.userCancel.rawValue:
                message = "The user did cancel"
                
            case LAError.userFallback.rawValue:
                message = "The user chose to use the fallback"

            default:
                message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
            }
            
            return message
        }

    
    
    // --------------------------------------------------------
    // MARK: - Push To ViewController
    // --------------------------------------------------------
  
    func pushToViewController(sb_Id:String) {
        let vc = storyboard?.instantiateViewController(withIdentifier: sb_Id)
        navigationController?.pushViewController(vc!, animated: true)
        
    }
    
    
    
    func ChangeStayusBarColor(){
           if #available(iOS 13.0, *) {
                   let app = UIApplication.shared
                   let statusBarHeight: CGFloat = app.statusBarFrame.size.height
                   
                   let statusbarView = UIView()
                   statusbarView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                   view.addSubview(statusbarView)
                 
                   statusbarView.translatesAutoresizingMaskIntoConstraints = false
                   statusbarView.heightAnchor
                       .constraint(equalToConstant: statusBarHeight).isActive = true
                   statusbarView.widthAnchor
                       .constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
                   statusbarView.topAnchor
                       .constraint(equalTo: view.topAnchor).isActive = true
                   statusbarView.centerXAnchor
                       .constraint(equalTo: view.centerXAnchor).isActive = true
                 
               } else {
                   let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
                   statusBar?.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
               }
           }
    
    func ChangeStayusBarColorWhite(){
           if #available(iOS 13.0, *) {
                   let app = UIApplication.shared
                   let statusBarHeight: CGFloat = app.statusBarFrame.size.height
                   
                   let statusbarView = UIView()
                   statusbarView.backgroundColor = #colorLiteral(red: 1, green: 0.9999999404, blue: 0.9999999404, alpha: 1)
                   view.addSubview(statusbarView)
                 
                   statusbarView.translatesAutoresizingMaskIntoConstraints = false
                   statusbarView.heightAnchor
                       .constraint(equalToConstant: statusBarHeight).isActive = true
                   statusbarView.widthAnchor
                       .constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
                   statusbarView.topAnchor
                       .constraint(equalTo: view.topAnchor).isActive = true
                   statusbarView.centerXAnchor
                       .constraint(equalTo: view.centerXAnchor).isActive = true
                 
               } else {
                   let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
                   statusBar?.backgroundColor = #colorLiteral(red: 1, green: 0.9999999404, blue: 0.9999999404, alpha: 1)
               }
           }
    
  
    
}
class DarkModeAwareNavigationController: UINavigationController {

  override init(rootViewController: UIViewController) {
       super.init(rootViewController: rootViewController)
       self.updateBarTintColor()
  }

  required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
       self.updateBarTintColor()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
       super.traitCollectionDidChange(previousTraitCollection)
       self.updateBarTintColor()
  }

  private func updateBarTintColor() {
       if #available(iOS 13.0, *) {
            self.navigationBar.barTintColor = UITraitCollection.current.userInterfaceStyle == .dark ? .black : .white
  }
  }
}
