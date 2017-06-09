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
        
        DataModel.sharedInstance.accessNetworkDataObject(
            params: [
                "sUser": username.text!,
                "sPass": password.text!
            ],
            wsURLPath: "telemed.asmx/telemedLogin",
            completion: {(response: NSDictionary) -> Void in
                if (!self.testWSResponse(response)) {
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
                DataModel.sharedInstance.accessNetworkDataObject(
                    params: [
                        "sKey": DataModel.sharedInstance.sessionInfo.SessionKey
                    ],
                    wsURLPath: "telemed.asmx/getUser",
                    completion: {(oUser: NSDictionary) -> Void in
                        if (!self.testWSResponse(oUser)) {
                            let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                                self.viewDidLoad()
                                self.viewWillAppear(true)
                            })
                            self.present(alertController, animated: true, completion: nil)
                            return
                        }
                        DataModel.sharedInstance.accessNetworkDataObject(
                            params: [
                                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                "sType": "contact",
                                "iObjectId": 0
                            ],
                            wsURLPath: "Util.asmx/returnObject",
                            completion: {(contactData: NSDictionary) -> Void in
                                if (!self.testWSResponse(contactData)) {
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
                                
                                self.correlateUsers(k: DataModel.sharedInstance.sessionInfo.SessionKey, i: oUser["user_id"] as! Int, completion: {(oUser: AnyObject) -> Void in
                                    if (DataModel.sharedInstance.sessionInfo.UserLevelID == 11) {
                                        DataModel.sharedInstance.accessNetworkDataObject(
                                            params: [
                                                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                                "iVisitId": 0,
                                                "iUserId": oUser.value(forKey: "user_id")!,
                                                "sRegToken": DataModel.sharedInstance.sessionInfo.FirebaseAccessToken
                                            ],
                                            wsURLPath: "Telemed.asmx/updateDocCreds",
                                            completion: {(result: NSDictionary) -> Void in
                                                print("subscribe")
                                                Messaging.messaging().subscribe(toTopic: "providers")
                                                // SEGUE to ProviderDashboardVC
                                                self.performSegue(withIdentifier: "ProviderDashboardVC", sender: sender)
                                            }
                                        )
                                    }else if (DataModel.sharedInstance.sessionInfo.UserLevelID == 3) {
                                        print("hey <-----------------------------<<<")
                                        print(oUser)
                                        DataModel.sharedInstance.accessNetworkDataObject(
                                            params: [
                                                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                                "iVisitId": 0,
                                                "iUserId": DataModel.sharedInstance.qbLoginParams.externalUserID,
                                                "sRegToken": DataModel.sharedInstance.sessionInfo.FirebaseAccessToken
                                            ],
                                            wsURLPath: "Telemed.asmx/updateSmCreds",
                                            completion: {(result: NSDictionary) -> Void in
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
                                })
                            }
                        )
                    }
                )
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DataModel.sharedInstance.destroySessionSaveLogin()
        username.text = DataModel.sharedInstance.sessionInfo.Email
        password.text = DataModel.sharedInstance.sessionInfo.Password
        validationBox.textAlignment = .center
        validationBox.text = ""
        username.becomeFirstResponder()
        logInButton.layer.cornerRadius = 10
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func correlateUsers(k: String, i: Int, completion: @escaping (_ response: AnyObject) -> ()) {
        QBRequest.logIn(
            withUserLogin: DataModel.sharedInstance.qbLoginParams.login!,
            password: DataModel.sharedInstance.qbLoginParams.password!,
            successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                print("<-----------------------------------<<< Login succeeded")
                DataModel.sharedInstance.qbLoginParams = user!
                DispatchQueue.main.async { completion(response) }
            }, errorBlock: {(_ response: QBResponse) -> Void in
                print("<-----------------------------------<<< Handle QB Login error")
                QBRequest.signUp(
                    DataModel.sharedInstance.qbLoginParams,
                    successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                        print("<-----------------------------------<<< Sign up was successful")
                        DataModel.sharedInstance.qbLoginParams = user!
                        DispatchQueue.main.async { completion(response) }
                    }, errorBlock: {(_ response: QBResponse) -> Void in
                        print("<-----------------------------------<<< Handle QB Sign Up error")
                    }
                )
            }
        )
    }
    
    func testWSResponse(_ response: AnyObject) -> Bool {
        var returnResponse = Bool()
        guard response["conn"] != nil else {
            print("CONN == nil <----------------------------<<<<<< ")
            return false
        }
        if response is NSArray {
            if (response.count == 0) {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AppAuthenticate") as! AppAuthenticationVC
                self.present(nextViewController, animated:true, completion:nil)
                print("Got zero Array results")
                returnResponse = false
            }else {
                returnResponse = true
            }
        }else if response is NSDictionary {
            if (response.allValues.isEmpty) {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AppAuthenticate") as! AppAuthenticationVC
                self.present(nextViewController, animated:true, completion:nil)
                print("Got zero Dictionary results")
                returnResponse = false
            }else {
                returnResponse = true
            }
        }
        return returnResponse
    }

}

