//
//  dataModel.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/26/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import Foundation
import Quickblox
import QuickbloxWebRTC

class DataModel {
    
    static let sharedInstance = DataModel()
    
    var sessionInfo = (
        SessionKey: String(),
        FirebaseAccessToken: String(),
        APNSAccessToken: String(),
        VisitID: Int(),
        UserLevelID: Int(),
        DefaultLocationID: Int(),
        Name: String(),
        Email: String(),
        Password: String(),
        CompanyID: Int(),
        ActiveCCID: Int(),
        QBPassword: String(),
        Peers: [NSNumber]()
    )
    
    var qbLoginParams = QBUUser()
    
    func destroySession() {
        sessionInfo = (
            SessionKey: String(),
            FirebaseAccessToken: String(),
            APNSAccessToken: String(),
            VisitID: Int(),
            UserLevelID: Int(),
            DefaultLocationID: Int(),
            Name: String(),
            Email: String(),
            Password: String(),
            CompanyID: Int(),
            ActiveCCID: Int(),
            QBPassword: String(),
            Peers: [NSNumber]()
        )
        qbLoginParams = QBUUser()
        print("Destroyed Session")
    }
    
    func destroySessionSaveLogin() {
        sessionInfo = (
            SessionKey: String(),
            FirebaseAccessToken: String(),
            APNSAccessToken: String(),
            VisitID: Int(),
            UserLevelID: Int(),
            DefaultLocationID: Int(),
            Name: String(),
            Email: DataModel.sharedInstance.sessionInfo.Email,
            Password: DataModel.sharedInstance.sessionInfo.Password,
            CompanyID: Int(),
            ActiveCCID: Int(),
            QBPassword: String(),
            Peers: [NSNumber]()
        )
        print("Destroyed Session but Saved Login")
    }
    
    func accessNetworkDataObject(params: [String:Any], wsURLPath: String, completion: @escaping (_ response: NSDictionary) -> ()) {
        let url = URL(string: "https://telemed.caduceususa.com/ws/" + wsURLPath)!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< " + wsURLPath)
                print(error!)
                return
            }
            guard let data = data else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< " + wsURLPath)
                return
            }
            
            let status = (response as! HTTPURLResponse).statusCode
            if status == 500 {
                print(type(of: data))
                print(String(describing:data))
                print(response ?? "No Response")
                print(error ?? "No Error")
                print("accessNetworkDataObject: response status: \(status) - " + wsURLPath)
                // NEED TO CREATE AN ALERT FOR THIS
                return
            }
            
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print("WEB SERVICE SUCCESS <----------------------------<<<<<< "+wsURLPath+" "+String(describing:params))
                    var response = NSDictionary()
                    if (parsedJSON["d"] as? NSDictionary != nil) {
                        response = parsedJSON["d"] as! NSDictionary
                    }else {
                        print("INVALID KEY <----------------------------<<<<<< " + wsURLPath)
                        print(parsedJSON)
                    }
                    DispatchQueue.main.async { completion(response) }
                }
            } catch let error {
                print("Error with JSON Serialization")
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func accessNetworkDataArray(params: [String:Any], wsURLPath: String, completion: @escaping (_ response: NSArray) -> ()) {
        let url = URL(string: "https://telemed.caduceususa.com/ws/" + wsURLPath)!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< " + wsURLPath)
                print(error!)
                return
            }
            guard let data = data else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< " + wsURLPath)
                return
            }
            
            let status = (response as! HTTPURLResponse).statusCode
            if status == 500 {
                print(type(of: data))
                print(String(describing:data))
                print(response ?? "No Response")
                print("accessNetworkDataArray: response status: \(status) - " + wsURLPath)
                // NEED TO CREATE AN ALERT FOR THIS
                return
            }
            
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print("WEB SERVICE SUCCESS <----------------------------<<<<<< " + wsURLPath)
                    var response = NSArray()
                    if (parsedJSON["d"] as? NSArray != nil) {
                        response = parsedJSON["d"] as! NSArray
                    }else {
                        print("INVALID KEY <----------------------------<<<<<< " + wsURLPath)
                        print(parsedJSON)
                    }
                    DispatchQueue.main.async { completion(response) }
                }
            } catch let error {
                print("Error with JSON Serialization")
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    private init() { }
}
