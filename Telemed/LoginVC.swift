//
//  ViewController.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/24/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit
import SystemConfiguration
import MobileCoreServices
import Quickblox
import QuickbloxWebRTC

class LoginVC: UIViewController {
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        if (segue.destination.isKind(of: ProviderDashboardVC.self)) {
            //let vc = segue.destination as! ProviderDashboardVC
        }else if (segue.destination.isKind(of: SafetyManagerDashboardVC.self)) {
            //let vc = segue.destination as! SafetyManagerDashboardVC
        }else {
            //let vc = segue.destination as! PatientSortingRoomVC
        }
    }
    
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var validationBox: UITextView!
    @IBAction func logInAction(_ sender: UIButton) {
        guard let user = username.text, !user.isEmpty else {
            validationBox.text = "Please enter valid credentials"
            return
        }
        guard let pass = password.text, !pass.isEmpty else {
            validationBox.text = "Please enter valid credentials"
            return
        }
        
        CallWebService.sharedInstance.logInToCaduceus(u: username.text!, p: password.text!, completion: {(sessionKey: String) -> Void in
            DataModel.sharedInstance.sessionInfo.SessionKey = sessionKey
            CallWebService.sharedInstance.getUser(
                k: sessionKey,
                completion: {(oUser: AnyObject) -> Void in
                    
                    // Create sessionInfo
                    
                    DataModel.sharedInstance.sessionInfo.Name = (oUser["first_name"] as! String) + " " + (oUser["last_name"] as! String)
                    DataModel.sharedInstance.sessionInfo.Email = oUser["email_address"] as! String
                    DataModel.sharedInstance.sessionInfo.Password = oUser["password"] as! String
                    DataModel.sharedInstance.sessionInfo.UserLevelID = oUser["userlevel_id"] as! Int
                    DataModel.sharedInstance.sessionInfo.DefaultLocationID = oUser["defaultlocation_id"] as! Int
                    
                    // create qbUserParams
                    
                    DataModel.sharedInstance.qbLoginParams.login = (oUser["first_name"] as! String) + " " + (oUser["last_name"] as! String) + " " + String(oUser["user_id"] as! Int)
                    DataModel.sharedInstance.qbLoginParams.password = oUser["password"] as! String
                    DataModel.sharedInstance.qbLoginParams.email = oUser["email_address"] as! String
                    DataModel.sharedInstance.qbLoginParams.full_name = (oUser["first_name"] as! String) + " " + (oUser["last_name"] as! String)
                    DataModel.sharedInstance.qbLoginParams.external_user_id = oUser["user_id"] as! Int
                    
                    self.correlateUsers(k: sessionKey,i: oUser["user_id"] as! Int, completion: {(oUser: AnyObject) -> Void in
                        if (DataModel.sharedInstance.sessionInfo.UserLevelID == 11) {
                            // SEGUE to ProviderDashboardVC
                            self.performSegue(withIdentifier: "ProviderDashboardVC", sender: sender)
                        }else if (DataModel.sharedInstance.sessionInfo.UserLevelID == 3) {
                            // SEGUE to SafetyManagerDashboardVC
                            self.performSegue(withIdentifier: "SafetyManagerDashboardVC", sender: sender)
                        }else {
                            // SEGUE to PatientSortingRoomVC
                            self.performSegue(withIdentifier: "PatientSortingRoomVC", sender: sender)
                        }
                    })
                    
                    
                }
            )
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validationBox.textAlignment = .center
        validationBox.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func correlateUsers(k: String, i: Int, completion: @escaping (_ response: AnyObject) -> ()) {
        
        QBRequest.logIn(
            withUserLogin: DataModel.sharedInstance.qbLoginParams.login,
            password: DataModel.sharedInstance.qbLoginParams.password,
            successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                print("Login succeeded")
                print(response)
                print(String(describing: user))
            }, errorBlock: {(_ response: QBResponse) -> Void in
                print("Handle QB Login error")
                /* Since No User, then sign them up
                let user = QBUUser()
                user.login = DataModel.sharedInstance.qbLoginParams.login
                user.password = DataModel.sharedInstance.qbLoginParams.password
                QBRequest.signUp(user, successBlock: {
                    (_ response: QBResponse, _ user: QBUUser) -> Void in
                        print("Sign up was successful")
                    } as? (QBResponse, QBUUser?) -> Void, errorBlock: {(_ response: QBResponse) -> Void in
                        print("Handle error here")
                        print(response)
                    }
                )
                */
            }
        )
        
        
        /*
        CallWebService.sharedInstance.returnObject(
            k: k,
            t: "qbuser",
            i: i,
            completion: {(oUser: AnyObject) -> Void in
                
            }
        )
        
        
        
        func login() {
            // Authenticate user
            QBRequest.logIn(withUserLogin: QBUser, password: QBPass, successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                // Login succeeded
            }, errorBlock: {(_ response: QBResponse) -> Void in
                // Handle error
            })
        }
        
        // Registration/sign up of User
         
         let user = QBUUser()
         
        user.login = "login"
        user.password = "password"
        QBRequest.signUp(user, successBlock: {(_ response: QBResponse, _ user: QBUUser) -> Void in
            print("Sign up was successful")
            } as? (QBResponse, QBUUser?) -> Void, errorBlock: {(_ response: QBResponse) -> Void in
                print("Handle error here")
                print(response)
        })
        */
    }

}

