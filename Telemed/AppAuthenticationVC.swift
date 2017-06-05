//
//  AppAuthenticationVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 6/2/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit

class AppAuthenticationVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        print(type(of: appVersion!))
        print(appVersion!)
        print(type(of: appBuild!))
        print(appBuild!)
        
        DataModel.sharedInstance.accessNetworkDataObject(
            params: [
                "sAppVersion": appVersion!,
                "sBuildVersion": appBuild!
            ],
            wsURLPath: "Telemed.asmx/isAppValid",
            completion: {(response: NSDictionary) -> Void in
                print("An update is required? - " + String(describing: response.value(forKey: "status") as! Bool))
                if (response.value(forKey: "status") as! Bool == false) {
                    self.performSegue(withIdentifier: "updateRequired", sender: AnyObject.self)
                }else {
                    self.performSegue(withIdentifier: "UserLogin", sender: AnyObject.self)
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
    
}
