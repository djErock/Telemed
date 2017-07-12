//
//  ViewController.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/24/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit
import Firebase
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
    @IBAction func unwindToMe(segue: UIStoryboardSegue){}
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var validationBox: UILabel!
    @IBOutlet weak var logInButton: UIButton!
    @IBAction func logInAction(_ sender: UIButton) {
        guard let user = username.text, !user.isEmpty else {
            validationBox.text = "Please enter valid credentials"
            return
        }
        guard let pass = password.text, !pass.isEmpty else {
            validationBox.text = "Please enter valid credentials"
            return
        }
    
        DataModel.sharedInstance.accessNetworkData(
            vc: self,
            loadModal: true,
            params: [
                "sUser": username.text!,
                "sPass": password.text!
            ],
            wsURLPath: "telemed.asmx/telemedLogin",
            completion: {(response: AnyObject) -> Void in
                if (DataModel.sharedInstance.testWSResponse(vc: self, response)) {
                    let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                        self.viewDidLoad()
                        self.viewWillAppear(true)
                    })
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                let sessionKey = response.value(forKey: "key") as! String
                if (sessionKey.characters.count != 50) {
                    self.validationBox.text = response.value(forKey: "message") as? String
                    return
                }
                DataModel.sharedInstance.sessionInfo.SessionKey = sessionKey
                DataModel.sharedInstance.accessNetworkData(
                    vc: self,
                    loadModal: false,
                    params: [
                        "sKey": DataModel.sharedInstance.sessionInfo.SessionKey
                    ],
                    wsURLPath: "telemed.asmx/getUser",
                    completion: {(oUser: AnyObject) -> Void in
                        if (DataModel.sharedInstance.testWSResponse(vc: self, oUser)) {
                            let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                                self.viewDidLoad()
                                self.viewWillAppear(true)
                            })
                            self.present(alertController, animated: true, completion: nil)
                            return
                        }
                        DataModel.sharedInstance.accessNetworkData(
                            vc: self,
                            loadModal: false,
                            params: [
                                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                "sType": "contact",
                                "iObjectId": 0
                            ],
                            wsURLPath: "Util.asmx/returnObject",
                            completion: {(contactData: AnyObject) -> Void in
                                if ( DataModel.sharedInstance.testWSResponse(vc: self, contactData) ) {
                                    let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                                        self.viewDidLoad()
                                        self.viewWillAppear(true)
                                    })
                                    self.present(alertController, animated: true, completion: nil)
                                    return
                                }
                                // Create sessionInfomal
                                
                                DataModel.sharedInstance.sessionInfo.CompanyID = Int(contactData["CompanyId"] as! String)!
                                DataModel.sharedInstance.sessionInfo.Name = (oUser["first_name"] as! String) + " " + (oUser["last_name"] as! String)
                                DataModel.sharedInstance.sessionInfo.Email = oUser["email_address"] as! String
                                DataModel.sharedInstance.sessionInfo.Password = oUser["password"] as! String
                                DataModel.sharedInstance.sessionInfo.UserLevelID = oUser["userlevel_id"] as! Int
                                DataModel.sharedInstance.sessionInfo.DefaultLocationID = oUser["defaultlocation_id"] as! Int
                                DataModel.sharedInstance.sessionInfo.QBPassword = "=TelemedUser#" + String(oUser["user_id"] as! Int) + "!"
                                
                                // create qbUserParams
                                
                                DataModel.sharedInstance.qbLoginParams.login = (oUser["first_name"] as! String) + "_" + (oUser["last_name"] as! String) + "_" + String(oUser["user_id"] as! Int)
                                DataModel.sharedInstance.qbLoginParams.password = "=TelemedUser#" + String(oUser["user_id"] as! Int) + "!"
                                DataModel.sharedInstance.qbLoginParams.email = oUser["email_address"] as? String
                                DataModel.sharedInstance.qbLoginParams.fullName = (oUser["first_name"] as! String) + " " + (oUser["last_name"] as! String)
                                DataModel.sharedInstance.qbLoginParams.externalUserID = UInt(oUser["user_id"] as! Int)
                                
                                print(String(describing: DataModel.sharedInstance.qbLoginParams))
                                
                                self.correlateUsers(completion: {(qbUser: AnyObject) -> Void in
                                    QBRequest.logOut(successBlock: { (QBResponse) in
                                        if (DataModel.sharedInstance.sessionInfo.UserLevelID == 11) {
                                            DataModel.sharedInstance.accessNetworkData(
                                                vc: self,
                                                loadModal: false,
                                                params: [
                                                    "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                                    "iVisitId": 0,
                                                    "iUserId": qbUser.value(forKey: "user_id")!,
                                                    "sRegToken": DataModel.sharedInstance.sessionInfo.FirebaseAccessToken
                                                ],
                                                wsURLPath: "Telemed.asmx/updateDocCreds",
                                                completion: {(result: AnyObject) -> Void in
                                                    print("subscribe")
                                                    Messaging.messaging().subscribe(toTopic: "providers")
                                                    // SEGUE to ProviderDashboardVC
                                                    self.performSegue(withIdentifier: "ProviderDashboardVC", sender: sender)
                                                }
                                            )
                                        }else if (DataModel.sharedInstance.sessionInfo.UserLevelID == 3) {
                                            DataModel.sharedInstance.accessNetworkData(
                                                vc: self,
                                                loadModal: false,
                                                params: [
                                                    "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                                    "iVisitId": 0,
                                                    "iUserId": DataModel.sharedInstance.qbLoginParams.externalUserID,
                                                    "sRegToken": DataModel.sharedInstance.sessionInfo.FirebaseAccessToken
                                                ],
                                                wsURLPath: "Telemed.asmx/updateSmCreds",
                                                completion: {(result: AnyObject) -> Void in
                                                    print("subscribe")
                                                    Messaging.messaging().subscribe(toTopic: "safetyManagers")
                                                    // SEGUE to SafetyManagerDashboardVC
                                                    self.performSegue(withIdentifier: "SafetyManagerDashboardVC", sender: sender)
                                                }
                                            )
                                        }else {
                                            // SEGUE to PatientSortingRoomVC
                                            self.performSegue(withIdentifier: "PatientSortingRoomVC", sender: sender)
                                        }
                                    }, errorBlock: { (QBResponse) in
                                        print("error logging out of QB")
                                        print(QBResponse)
                                    })
                                    
                                })
                            }
                        )
                    }
                )
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DataModel.sharedInstance.destroySessionSaveLogin()
        if DataModel.sharedInstance.sessionInfo.Email.isEmpty {
            username.text = "eg@marta.com"
            password.text = "teamwork1"
        }else {
            username.text = DataModel.sharedInstance.sessionInfo.Email
            password.text = DataModel.sharedInstance.sessionInfo.Password
        }
        
        validationBox.textAlignment = .center
        validationBox.text = ""
        username.becomeFirstResponder()
        logInButton.layer.cornerRadius = 10
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func correlateUsers(completion: @escaping (_ response: AnyObject) -> ()) {
        QBRequest.logIn(
            withUserLogin: DataModel.sharedInstance.qbLoginParams.login!,
            password: DataModel.sharedInstance.qbLoginParams.password!,
            successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                print("<-----------------------------------<<< Login succeeded")
                DataModel.sharedInstance.qbLoginParams = user!
                completion(response)
            }, errorBlock: {(_ response: QBResponse) -> Void in
                print("<-----------------------------------<<< Handle QB Login error")
                QBRequest.signUp(
                    DataModel.sharedInstance.qbLoginParams,
                    successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                        print("<-----------------------------------<<< Sign up was successful")
                        print(String(describing: DataModel.sharedInstance.qbLoginParams))
                        QBRequest.logIn(
                            withUserLogin: DataModel.sharedInstance.qbLoginParams.login!,
                            password: DataModel.sharedInstance.qbLoginParams.password!,
                            successBlock: {(_ logInResponse: QBResponse, _ loggedInUser: QBUUser?) -> Void in
                                DataModel.sharedInstance.qbLoginParams = loggedInUser!
                                print("<-----------------------------------<<< Login succeeded")
                                completion(logInResponse)
                        }, errorBlock: {(_ response: QBResponse) -> Void in
                            print("Signed up but <-----------------------------------<<< Handle QB Login error")
                        })
                    }, errorBlock: {(_ response: QBResponse) -> Void in
                        print("<-----------------------------------<<< Handle QB Sign Up error")
                    }
                )
            }
        )
    }
    
    

}

