//
//  SettingsController.swift
//  NewsApp
//
//  Created by Apple on 26/05/23.
//

import UIKit
import LocalAuthentication

class SettingsController: BaseViewController {
    
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var textField: UITextField!
    
    var arr = [String]()
    var arrUpdated = [String]()
    var arrArabic = [String]()
    var arrUpdatedArabic = [String]()
    var getEmail:String!
    var getPass:String!
    var isCredentialsTrue = false
    private let biometricIDAuth = BiometricIDAuth()
    private let pickerView = ToolbarPickerView()
    let languages = ["English", "Arabic"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    //MARK: - Update UI
    private func setupUI() {
        
        if LocalStore.shared.engTrueArabicFalse {
            arr = ["My Profile".localalizedString(str: "en"), "Change Language".localalizedString(str: "en"), "Switch to Dark Mode".localalizedString(str: "en"), "Enable Fingerprint".localalizedString(str: "en"), "Logout".localalizedString(str: "en")]
            arrUpdated = ["My Profile".localalizedString(str: "en"), "Change Language".localalizedString(str: "en"), "Switch to Dark Mode".localalizedString(str: "en"), "Logout".localalizedString(str: "en")]
            setupNavigationBar(title: "Settings".localalizedString(str: "en"), img: "back", imgRight: "", isBackButton: true, isRightButton: false, isBackButtonItem: false, isRightButton2: false, imgRight2: "",leftButton2: false, leftButton2Img: "", isCountrySelected: false)
        } else {
            
            arr = ["My Profile".localalizedString(str: "ar"), "Change Language".localalizedString(str: "ar"), "Switch to Dark Mode".localalizedString(str: "ar"), "Enable Fingerprint".localalizedString(str: "ar"), "Logout".localalizedString(str: "ar")]
            arrUpdated = ["My Profile".localalizedString(str: "ar"), "Change Language".localalizedString(str: "ar"), "Switch to Dark Mode".localalizedString(str: "ar"), "Logout".localalizedString(str: "ar")]
            setupNavigationBar(title: "Settings".localalizedString(str: "ar"), img: "back", imgRight: "", isBackButton: true, isRightButton: false, isBackButtonItem: false, isRightButton2: false, imgRight2: "",leftButton2: false, leftButton2Img: "", isCountrySelected: false)
        }
        
        
        if self.traitCollection.userInterfaceStyle == .dark {
            ChangeStayusBarColor()
            AppUserDefaults.set(true, forKey: "isDark")
        } else {
            ChangeStayusBarColorWhite()
            AppUserDefaults.set(false, forKey: "isDark")
        }
        self.getEmail = KeyChainWrapper.retriveValue(id: "email")
        self.getPass = KeyChainWrapper.retriveValue(id: "password")
        if self.getEmail != "" && self.getPass != "" {
            self.isCredentialsTrue = true
        }
        
        pickerView.delegate = self
        pickerView.dataSource = self
        textField.inputView = pickerView
        textField.isHidden = true
        textField.inputAccessoryView = pickerView.toolbar
        pickerView.toolbarDelegate = self
        
        
    }
    
    func logout() {
        
        let alert = UIAlertController(title: APPNAME, message: "Are you sure you want to logout.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Yes", style: .default, handler: {(action) -> Void in
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginController") as! LoginController
            self.navigationController?.pushViewController(vc, animated: true)
        })
        let cancelAction = UIAlertAction(title: "No", style: .default, handler: nil)
        alert.addAction(action)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func btnSwitchDark (_ sender: UISwitch) {
        if #available(iOS 13.0, *) {
             let appDelegate = UIApplication.shared.windows.first
                 if sender.isOn {
                     ChangeStayusBarColor()
                     AppUserDefaults.set(true, forKey: "isDark")
                    appDelegate?.overrideUserInterfaceStyle = .dark
                      return
                 }
            ChangeStayusBarColorWhite()
            AppUserDefaults.set(false, forKey: "isDark")
             appDelegate?.overrideUserInterfaceStyle = .light
             return
        }
    }
    
    
}
extension SettingsController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isCredentialsTrue{
            return arrUpdated.count
        } else {
            return arr.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellSettings") as! cellSettings? else {
            fatalError()
        }
        if isCredentialsTrue{
            cell.lblTitle.text = arrUpdated[indexPath.row]
            cell.imgTitle.image = UIImage(named: arrUpdated[indexPath.row].localalizedString(str: "en"))
        } else {
            cell.lblTitle.text = arr[indexPath.row]
            cell.imgTitle.image = UIImage(named: arr[indexPath.row].localalizedString(str: "en"))
        }
        
        let isDark = AppUserDefaults.bool(forKey: "isDark")
        if isDark{
            cell.switchButton.isOn = isDark
        }else {
            cell.switchButton.isOn = isDark
        }
        
        let engTrueArabicFalse = AppUserDefaults.bool(forKey: "engTrueArabicFalse")
        if engTrueArabicFalse{
            cell.lblLangaugeChange.text = "English"
            if isCredentialsTrue{
                cell.lblTitle.text = arrUpdated[indexPath.row]
                cell.imgTitle.image = UIImage(named: arrUpdated[indexPath.row].localalizedString(str: "ar"))
            } else {
                cell.lblTitle.text = arr[indexPath.row]
                cell.imgTitle.image = UIImage(named: arr[indexPath.row].localalizedString(str: "ar"))
            }
        }
        else
        {
            cell.lblLangaugeChange.text = "عربي"
            if isCredentialsTrue{
                cell.lblTitle.text = arrUpdated[indexPath.row]
                cell.imgTitle.image = UIImage(named: arrUpdated[indexPath.row])
            } else {
                cell.lblTitle.text = arr[indexPath.row]
                cell.imgTitle.image = UIImage(named: arr[indexPath.row])
            }
        }
        if indexPath.row == 1{
            cell.stackview.isHidden = false
            cell.switchButton.isHidden = true
            cell.lblLangaugeChange.isHidden = false
        } else if indexPath.row == 2{
            cell.stackview.isHidden = false
            cell.switchButton.isHidden = false
            cell.lblLangaugeChange.isHidden = true
        } else {
            cell.stackview.isHidden = true
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isCredentialsTrue{
            switch indexPath.row {
            case 0:
                print("First")
            case 1:
                print("second")
            case 2:
                print("third")
            default:
                logout()
            }
        } else {
            switch indexPath.row {
            case 0:
                print("First")
            case 1:
                print("second")
                textField.becomeFirstResponder()
            case 2:
                print("third")
            case 3:
                let email = KeyChainWrapper.stringToNSDATA(string: Global.email)
                let password = KeyChainWrapper.stringToNSDATA(string: Global.password)
                _ = KeyChainWrapper.save(key: "email", data: email)
                _ = KeyChainWrapper.save(key: "password", data: password)
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
                        
                        AlertClass.alert(title: "Success",
                                         message: "You Are Successfully LoggedIn",
                                         okActionTitle: "OK")
                        
                        
                        
                        self.getEmail = KeyChainWrapper.retriveValue(id: "email")
                        self.getPass = KeyChainWrapper.retriveValue(id: "password")
                        if self.getEmail != "" && self.getPass != "" {
                            self.isCredentialsTrue = true
                        }
                        self.tableview.reloadData()
                    }
                }
                
                
                
            default:
                logout()
            }
        }
    }
}
class cellSettings: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgTitle: UIImageView!
    @IBOutlet weak var stackview: UIStackView!
    @IBOutlet weak var lblLangaugeChange: UILabel!
    @IBOutlet weak var switchButton: UISwitch!
}
extension SettingsController: UIPickerViewDataSource, UIPickerViewDelegate {

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.languages.count
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.languages[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if self.languages[row] == "English" {
            AppUserDefaults.set(true, forKey: "engTrueArabicFalse")
        }
        else
        {
            AppUserDefaults.set(false, forKey: "engTrueArabicFalse")
        }
        tableview.reloadData()
    }
}

extension SettingsController: ToolbarPickerViewDelegate {

    func didTapDone() {
        let row = self.pickerView.selectedRow(inComponent: 0)
        self.pickerView.selectRow(row, inComponent: 0, animated: false)
        let lang = self.languages[row]
        if lang == "English" {
            AppUserDefaults.set(true, forKey: "engTrueArabicFalse")
        }
        else
        {
            AppUserDefaults.set(false, forKey: "engTrueArabicFalse")
        }
        tableview.reloadData()
        self.textField.resignFirstResponder()
        pushToViewController(sb_Id: "LoginController")
    }

    func didTapCancel() {
        self.textField.text = nil
        self.textField.resignFirstResponder()
    }
}
