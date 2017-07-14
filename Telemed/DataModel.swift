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
//import Rainbow

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
            FirebaseAccessToken: DataModel.sharedInstance.sessionInfo.FirebaseAccessToken,
            APNSAccessToken: DataModel.sharedInstance.sessionInfo.APNSAccessToken,
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
    
    
    
    func accessNetworkData(vc: UIViewController, loadModal: Bool, params: [String:Any], wsURLPath: String, completion: @escaping (_ response: AnyObject) -> ()) {
        if loadModal {
            //DataModel.sharedInstance.toggleModalProgess(show: true)
        }
        // Present on vc.
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
                if loadModal {
                    //DataModel.sharedInstance.toggleModalProgess(show: false)
                }
                print(error!)
                let resp: [String: String] = [ "conn": "failed" ]
                DispatchQueue.main.async { completion(resp as NSDictionary) }
                return
            }
            guard let data = data else {
                print("WEB SERVICE ERROR <----------------------------<<<<<< " + wsURLPath)
                if loadModal {
                    //DataModel.sharedInstance.toggleModalProgess(show: false)
                }
                return
            }
            let status = (response as! HTTPURLResponse).statusCode
            if status == 500 {
                if loadModal {
                    //DataModel.sharedInstance.toggleModalProgess(show: false)
                }
                do {
                    if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        print( String(describing:parsedJSON) )
                    }else {
                        print("JSONSerialization Error")
                    }
                } catch let error {
                    print("Error with the error message JSON Serialization")
                    print(error.localizedDescription)
                }
                print(error ?? "No Error Found where there should be")
                print("accessNetworkDataObject: response status: \(status) - " + wsURLPath)
                // Access the storyboard and fetch an instance of the view controller
                let window = UIApplication.shared.keyWindow;
                var currentViewController = window?.rootViewController;
                while (currentViewController?.presentedViewController != nil) {
                    currentViewController = currentViewController?.presentedViewController;
                    let loginViewController = currentViewController?.storyboard?.instantiateViewController(withIdentifier: "LoginVC")
                    DispatchQueue.main.async { UIApplication.shared.keyWindow?.rootViewController = loginViewController }
                    return
                }
            }
            
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print("WEB SERVICE SUCCESS <----------------------------<<<<<< "+wsURLPath+" "+String(describing:params))
                    if loadModal {
                        //DataModel.sharedInstance.toggleModalProgess(show: false)
                    }
                    if let parsedResponseDict = parsedJSON["d"] as? NSDictionary {
                        DispatchQueue.main.async {
                            completion(parsedResponseDict)
                        }
                    }else if let parsedResponseArr = parsedJSON["d"] as? NSArray {
                        DispatchQueue.main.async {
                            completion(parsedResponseArr)
                        }
                    }else {
                        print("INVALID KEY <----------------------------<<<<<< " + wsURLPath)
                        DispatchQueue.main.async {
                            completion(parsedJSON as AnyObject)
                        }
                    }
                }
            } catch let error {
                print("Error with JSON Serialization")
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    func testWSResponse(vc: UIViewController, _ response: AnyObject) -> Bool {
        var returnResponse = Bool()
        if response is NSArray {
            print(String(describing: response))
            if (response.count == nil) {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AppAuthenticate") as! AppAuthenticationVC
                vc.present(nextViewController, animated:true, completion:nil)
                print("Got zero Array results")
                returnResponse = true
            }else {
                returnResponse = false
            }
        }else if response is NSDictionary {
            guard response["conn"] != nil else {
                print("CONN == nil <----------------------------<<<<<< ")
                return true
            }
            if (response.allValues.isEmpty) {
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "AppAuthenticate") as! AppAuthenticationVC
                vc.present(nextViewController, animated:true, completion:nil)
                print("Got zero Dictionary results")
                returnResponse = true
            }else {
                returnResponse = false
            }
        }
        return returnResponse
    }
    
    let modalAlert = UIAlertController(title: "Please Wait...", message: "Loading Data...", preferredStyle: UIAlertControllerStyle.alert)
    
    func toggleModalProgess(show: Bool) -> Void {
        if (show == true) {
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            loadingIndicator.startAnimating()
            DataModel.sharedInstance.modalAlert.view.addSubview(loadingIndicator)
            DataModel.sharedInstance.modalAlert.show()
        }else if (show == false) {
            DataModel.sharedInstance.modalAlert.hide()
        }
    }
    
    private init() { }
}

public extension UIAlertController {
    func show() {
        print("show alertcontroller")
        let win = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        win.rootViewController = vc
        win.windowLevel = UIWindowLevelAlert + 1
        win.makeKeyAndVisible()
        vc.present(self, animated: true, completion: nil)
        print("we showed it")
    }
    func hide() {
        print("hide alertcontroller")
        dismiss(animated: true, completion: nil)
    }
}
