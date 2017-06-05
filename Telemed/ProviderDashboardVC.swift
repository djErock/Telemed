//
//  ProviderDashboardVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/27/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//
/*
 If you are calling setAPNSToken, make sure that the value of type is correctly set:
 
 FIRInstanceIDAPNSTokenTypeSandbox for the sandbox environment, or
 FIRInstanceIDAPNSTokenTypeProd for the production environment.
 
 If you don't set the correct type, messages will not be delivered to your app.
 */

import UIKit
import Foundation

class ProviderDashboardVC: UIViewController {
    
    @IBOutlet weak var ProviderMessage: UITextView!
    @IBAction func BackToHome(_ sender: UIButton) {
        
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ProviderMessage.text = "We are sorry but the Provider Interface isn't available yet... Please go to Google Chrome on a desktop computer or Android Device to work telemed Visits. Thank you..."
        print(DataModel.sharedInstance.sessionInfo)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
