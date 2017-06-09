//
//  AppAuthenticationVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 6/2/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit

class AppAuthenticationVC: UIViewController, UIAlertViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        DataModel.sharedInstance.accessNetworkDataObject(
            params: [
                "sAppVersion": appVersion!,
                "sBuildVersion": appBuild!
            ],
            wsURLPath: "Telemed.asmx/isAppValid",
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
                print("An update is required? - " + String(describing: response.value(forKey: "status") as! Bool))
                if ( response.value(forKey: "status") as! Bool ) {
                    self.performSegue(withIdentifier: "UserLogin", sender: AnyObject.self)
                }else {
                    self.performSegue(withIdentifier: "updateRequired", sender: AnyObject.self)
                }
            }
        )
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: (Any)?) {
        if (segue.destination.isKind(of: LoginVC.self)) {
            //let vc = segue.destination as! ProviderDashboardVC
        }else if (segue.destination.isKind(of: updateRequiredVC.self)) {
            //let vc = segue.destination as! SafetyManagerDashboardVC
        }else {
            //let vc = segue.destination as! PatientSortingRoomVC
        }
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
