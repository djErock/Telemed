//
//  PatientTelemedVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 5/1/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit
import SystemConfiguration
import MobileCoreServices
import Quickblox
import QuickbloxWebRTC
import Fabric
import Crashlytics

let kQBApplicationID:UInt = 51908
let kQBAuthKey = "uQ-SG4-ntaw3zOx"
let kQBAuthSecret = "ry6qwgF6fs7AyyJ"
let kQBAccountKey = "7yvNe17TnjNUqDoPwfqp"


class PatientTelemedVC: UIViewController {
    
    @IBOutlet weak var TemporaryVisitIDLabel: UILabel!
    var visitIdForSession = Int()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        QBRTCClient.initializeRTC()
        DataModel.sharedInstance.sessionInfo.VisitID = visitIdForSession
        
        QBRTCClient.instance().add(self as! QBRTCClientDelegate) // self class must conform to QBRTCClientDelegate protocol
        
        // 2123, 2123, 3122 - opponent's
        let opponentsIDs = [3245, 2123, 3122]
        let newSession = QBRTCClient.instance().createNewSession(withOpponents: opponentsIDs as [NSNumber], with: QBRTCConferenceType.video)
        // userInfo - the custom user information dictionary for the call. May be nil.
        let userInfo :[String:String] = ["key":"value"]
        newSession.startCall(userInfo)
        
        
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    



}
