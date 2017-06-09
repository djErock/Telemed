//
//  Service.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/25/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import Foundation

class CallWebService {
    
    static let sharedInstance = CallWebService()
    
    func logInToCaduceus(u: String, p: String, completion: @escaping (_ login: [String:Any]) -> ()) {
        let params = ["sUser": u, "sPass": p]
        let url = URL(string: "https://telemed.caduceususa.com/ws/telemed.asmx/telemedLogin")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< logInToCaduceus")
                print(error!)
                return
            }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    let parsedData = parsedJSON["d"] as! [String:Any]
                    DataModel.sharedInstance.sessionInfo.SessionKey = parsedData["key"] as! String
                    DispatchQueue.main.async { completion(parsedData) }
                }
            } catch let error {
                print("logInToCaduceus - probably a 500 error")
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func getUser(k: String, completion: @escaping (_ oUser: AnyObject) -> ()) {
        let params = ["sKey": k]
        let url = URL(string: "https://telemed.caduceususa.com/ws/telemed.asmx/getUser")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< getUser")
                print(error!)
                return
            }
            guard let data = data else { return }
            do {
                print(data)
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    let user = parsedJSON["d"] as! [String:Any]
                    DispatchQueue.main.async { completion(user as AnyObject) }
                }
            } catch let error {
                print("getUser - probably a 500 error")
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func getActiveVisits(k: String, completion: @escaping (_ visits: NSArray) -> ()) {
        let params = ["sKey": k]
        let url = URL(string: "https://telemed.caduceususa.com/ws/Util.asmx/returnActiveVisits")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< getActiveVisits")
                print(error!)
                return
            }
            guard let data = data else {
                print("No Data")
                return
            }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    var visits = NSArray()
                    
                    if parsedJSON["d"] as? NSArray != nil {
                        visits = parsedJSON["d"] as! NSArray
                    } else {
                        
                    }
                    
                    DispatchQueue.main.async { completion(visits) }
                }
            } catch let error {
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse)
                }else {
                    print("nada")
                }
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func populateDDL(k: String, tbl: String, ddl: String, completion: @escaping (_ response: NSArray) -> ()) {
        var params: [String: Any]
        if (tbl != "none") {
            params = ["sKey": k, "sTableName": tbl]
        }else {
            params = ["sKey": k]
        }
        let url = URL(string: "https://telemed.caduceususa.com/ws/Util.asmx/" + ddl)!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< populateDDL " + tbl)
                print(error!)
                return
            }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    let parseOutTheD = parsedJSON["d"] as! [NSArray]
                    DispatchQueue.main.async { completion(parseOutTheD as NSArray) }
                }
            } catch let error {
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse)
                }else {
                    print("nada")
                }
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func returnObject(k: String, t: String, i: Int, completion: @escaping (_ response: NSDictionary) -> ()) {
        let params: [String: Any] = ["sKey": k, "sType": t, "iObjectId": i]
        let url = URL(string: "https://telemed.caduceususa.com/ws/Util.asmx/returnObject")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< returnObject " + t)
                print(error!)
                return
            }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    let returnData = parsedJSON["d"] as! NSDictionary
                    print(returnData)
                    DispatchQueue.main.async { completion(returnData) }
                }
            } catch let error {
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse)
                }else {
                    print("nada")
                }
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func updateQbUser(k: String, t: String, oUser: QBUUser, completion: @escaping (_ oVisits: AnyObject) -> ()) {
        let tmUser: [String : Any] = [
            "id" : oUser.id,
            "login" : oUser.login ?? "",
            "password" : oUser.password ?? "",
            "email" : oUser.email ?? "",
            "full_name" : oUser.fullName ?? "",
            "external_user_id" : oUser.externalUserID,
            "tag_list" : String(describing: oUser.tags)
        ]
        let params: [String: Any] = ["sKey": k, "sUpdateType": t, "oQbUser": tmUser as AnyObject]
        let url = URL(string: "https://telemed.caduceususa.com/ws/Telemed.asmx/updateQbUser")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< updateQbUser")
                print(error!)
                return
            }
            guard data != nil else { return }
            DispatchQueue.main.async { completion(response!) }
        })
        task.resume()
    }
    
    func creditCard(k: String, t: String, data: NSDictionary, completion: @escaping (_ response: AnyObject) -> ()) {
        
        let params: [String: Any] = ["sKey": k, "sUpdateType": t, "oCreditCard": data]
        let url = URL(string: "https://telemed.caduceususa.com/ws/Telemed.asmx/updateCreditCard")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< creditCard")
                print(error!)
                
                return
            }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    //let visits = parsedJSON["d"] as! [NSArray]
                    DispatchQueue.main.async { completion(parsedJSON as AnyObject) }
                }
            } catch let error {
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse)
                }else {
                    print("nada")
                }
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func submitPatient(k: String, data: NSDictionary, completion: @escaping (_ response: NSDictionary) -> ()) {
        
        let params: [String: Any] = ["sKey": k, "oFormFS": data]
        let url = URL(string: "https://telemed.caduceususa.com/ws/Telemed.asmx/submitPatient")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< submitPatient")
                print(error!)
                return
            }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    let result = parsedJSON["d"] as! NSDictionary
                    DispatchQueue.main.async { completion(result) }
                }
            } catch let error {
                if let httpResponse = response as? HTTPURLResponse {
                    print(httpResponse)
                }else {
                    print("nada")
                }
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    private init() { }
}
