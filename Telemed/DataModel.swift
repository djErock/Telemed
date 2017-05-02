//
//  dataModel.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/26/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import Foundation

class DataModel {
    
    static let sharedInstance = DataModel()
    
    var sessionInfo = (
        SessionKey: String(),
        FirebaseAccessToken: String(),
        VisitID: Int(),
        UserLevelID: Int(),
        DefaultLocationID: Int(),
        Name: String(),
        Email: String(),
        Password: String()
    )
    var qbLoginParams = (
        login: String(),
        password: String(),
        email: String(),
        full_name: String(),
        external_user_id:  Int(),
        tag_list: String()
    )
    
    // Networking: communicating server
    func network() {
        // get everything
    }
    
    private init() { }
}
