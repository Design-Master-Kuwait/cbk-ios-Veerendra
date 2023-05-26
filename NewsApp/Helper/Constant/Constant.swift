


import UIKit


public let baseURL = ""


public struct API {
    
    
    
    // Mark : - Login & Register Api's -
    
//    public static let Login_Api               =  baseURL + "login"
    
}


/*********************************  Structures  ********************************/


public struct AppKey
{
    public static let notify_id = "notify_id"
    public static let device_id = "device_id"
}

let NOINTERNET = "No Internet Connection"
let APPNAME = "News App"

// Mark : -  LOGIN & SIGN UP

let EMAIL_EMPTY = "Email field can't be empty"
let EMAIL_NOT_VALID = "Please enter email address"
let PASSWORD_EMPTY = "Password field can't be empty"
let PASSWORD_LENGTH = "Password should be at least 5 characters long"
let CONFIRM_PASSWORD_EMPTY = "Confirm password field can't be empty"
let PASSWORD_NOT_MATCH = "Password and confirm password doesn't match"
let USER_NAME_EMPTY = "User name field can't be empty"
let NAME = "Name field can't be empty"
let phoneNoLegnth = "Please enter vaild phone number"

// CHANGE PASSWORD

let START_END_COMPARE_TIME  = "Please select end time grater than start time"
let OLD_PASSWORD_EMPTY = "Current password field can't be empty"
let NEW_PASSWORD_EMPTY = "New password field can't be empty"
let NEW_OLD_PASSWORD_NOt_MATCH = "New Password and Confirm password doesn't match"
let CONFORM_PASSWORD_EMPTY = "Confirm Password field can't be empty"


/************************************ Constant ***********************************/

let KAppDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
public let AppUserDefaults            =      UserDefaults.standard
public let AppNotificationCenter      =      NotificationCenter.default
public typealias KeyValue             =      [String : Any]
public let KPasswordMinLength         =       6
public let KDelayTime                 =       2.0
public let KTimeDuration              =       0.3
public let KOffline                   =       "Offline"
public let KPhoneMaxLength            =       12
public let KEmailMaxLength            =       100
public let KPasswordMaxLength         =       20
public let KTankMaxLimit              =       10
public let KAmountMaxLength           =       4
public let KFirstNameLength           =       20
public let KCommentLength             =       300
public var KLoading                   =        "Loading..."
public let KOk                        =        "Ok"


/*********************************************************************************/


// MARK :- Validate Messages

public let kOops  = "Oops..!!"
public let kEnterName  = "Please enter your name"
public let kEnterValidEmail  = "Please enter a valid email"
public let kEnterEmail  = "Please enter your email"
public let kEnterPassword  = "Pleasse enter your password"
public let kEnterConfirmPassword  = "Please confirm your password."
public let kEnterAddress  = "Enter address"
public let kEnterPhoneNumber  = "Please enter your phone number"
public let kEnterCurrentPassword  = "Pleasse enter your current password"
public let kEnterOldPassword  = "Enter old password"
public let kEnterNewPassword  = "Please enter new password"
public let kReEnterNewPassword  = "Re-Enter new password"
public let kOtp  = "Please enter your OTP"
public let khome  = "Please enter your home address"
public let kAppartment  = "Please enter your appartment address"
public let kLandmark  = "Please enter near landmark"
public let kPincode  = "Please enter your pincode"
public let kCity  = "Please enter your city"
public let kArea  = "Please enter your area"
public let kGovernate  = "Please enter your governate"
public let KselectOne  = "Please Select one option"
public let kDirection  = "Please confirm directions"
public let kEnterFirstName  = "Please enter your Firstname"
public let kEnterLastName  = "Please enter your Laststname"
// Mark :- Warning Messages

public let kPasswordDoesNotMatch  = "Password does not match"
public let kCheckYourMobileNumber =   "Please check your mobile number"
public let kCheckCountryCodeOrMobileNumber  =  "Please check your country code and mobile number"

// Mark :-Automatically set Up

public let kAvailablityErrorMessage = "Please change the availability to automatic from settings to perform this action. (Settings->Set Availability)"


// Mark :- Arabic Alert

public let kArbOops = "وجه الفتاة..!!"
public let kArbEnterEmail  = "رجاءا أدخل بريدك الإلكتروني"
public let kArbEnterValidEmail  = "يرجى إدخال البريد الإلكتروني الصحيح"
public let kArbEnterPassword  = "من فضلك أدخل رقمك السري"
public let kArbEnterName  = "يرجى إدخال اسمك"
public let kArbEnterPhoneNumber  = "يرجى إدخال رقم الهاتف الخاص بك"
public let kArbEnterConfirmPassword  = "يرجى التأكد من صحة كلمة المرور الخاصة بك"
public let kArbPasswordDoesNotMatch  = "كلمة السر غير متطابقة"
public let kArbOtp  = "الرجاء إدخال OTP الخاص بك"
public let kArbEnterNewPassword  = "الرجاء إدخال كلمة المرور الجديدة"



