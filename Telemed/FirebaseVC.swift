//
//  FirebaseVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/24/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//
/*  
 If you are calling setAPNSToken, make sure that the value of type is correctly set:
 
 FIRInstanceIDAPNSTokenTypeSandbox for the sandbox environment, or
 FIRInstanceIDAPNSTokenTypeProd for the production environment. 
 
 If you don't set the correct type, messages will not be delivered to your app.
*/

import UIKit

class FirebaseVC: UIViewController {

    private var _sessionKey = String()
    
    var sessionKey : String {
        get { return _sessionKey }
        set { _sessionKey = newValue }
    }
    
    @IBOutlet weak var sessionKeyTestBox: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sessionKeyTestBox.text = _sessionKey
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
