//
//  SettingsController.swift
//  NewsApp
//
//  Created by Apple on 26/05/23.
//

import UIKit

class SettingsController: BaseViewController {
    
    
    @IBOutlet weak var tableview: UITableView!
    var arr = ["My Profile", "Change Language", "Switch to Dark Mode", "Enable Fingerprint", "Logout"]
    var arrUpdated = ["My Profile", "Change Language", "Switch to Dark Mode", "Logout"]
    var getUser_Id:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    //MARK: - Update UI
    private func setupUI() {
        getUser_Id = KeyChainWrapper.retriveValue(id: "UserId")
        setupNavigationBar(title: "Settings", img: "back", imgRight: "", isBackButton: true, isRightButton: false, isBackButtonItem: false)
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
    
    
}
extension SettingsController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if getUser_Id == ""{
            return arr.count
        } else {
            return arrUpdated.count
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellSettings") as! cellSettings? else {
            fatalError()
        }
        if getUser_Id == "" {
            cell.lblTitle.text = arr[indexPath.row]
            cell.imgTitle.image = UIImage(named: arr[indexPath.row])
        } else {
            cell.lblTitle.text = arrUpdated[indexPath.row]
            cell.imgTitle.image = UIImage(named: arrUpdated[indexPath.row])
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
        if getUser_Id == "" {
            switch indexPath.row {
            case 0:
                print("First")
            case 1:
                print("second")
            case 2:
                print("third")
            case 3:
                let generateRandomNumber = randomString(length: 5)
                let id = KeyChainWrapper.stringToNSDATA(string: generateRandomNumber)
                let saveUserId = KeyChainWrapper.save(key: "UserId", data: id)
                authenticationWithTouchID()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
                    getUser_Id = KeyChainWrapper.retriveValue(id: "UserId")
                    tableview.reloadData()
                }
                
            default:
                logout()
            }
        } else {
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
