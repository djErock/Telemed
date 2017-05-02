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
    
    func logInToCaduceus(u: String, p: String, completion: @escaping (_ sKey: String) -> ()) {
        let params = ["sUser": u, "sPass": p]
        let url = URL(string: "https://telemed.caduceususa.com/ws/telemed.asmx/telemedLogin")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { return }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    let parsedData = parsedJSON["d"] as! [String:Any]
                    let key = parsedData["key"] as! String
                    DispatchQueue.main.async { completion(key) }
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
            guard error == nil else { return }
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
    
    func getActiveVisits(k: String, completion: @escaping (_ oVisits: AnyObject) -> ()) {
        let params = ["sKey": k]
        let url = URL(string: "https://telemed.caduceususa.com/ws/Util.asmx/returnActiveVisits")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { return }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    //let visits = parsedJSON["d"] as! [NSArray]
                    DispatchQueue.main.async { completion(parsedJSON as NSDictionary) }
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
    
    func returnObject(k: String, t: String, i: Int, completion: @escaping (_ oVisits: AnyObject) -> ()) {
        let params: [String: Any] = ["sKey": k, "sType": t, "iObjectId": i]
        let url = URL(string: "https://telemed.caduceususa.com/ws/Util.asmx/returnObject")!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do { request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) } catch let error { print(error.localizedDescription) }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            guard error == nil else { return }
            guard let data = data else { return }
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    //let visits = parsedJSON["d"] as! [NSArray]
                    DispatchQueue.main.async { completion(parsedJSON as NSDictionary) }
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
    
}
