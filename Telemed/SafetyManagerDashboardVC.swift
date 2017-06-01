//
//  SafetyManagerDashboardVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/27/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit

class SafetyManagerDashboardVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var visitsView: UITableView!
    @IBOutlet weak var LogOff: UIBarButtonItem!
    @IBOutlet weak var CreateNewVisit: UIBarButtonItem!
    
    //var CreateNewVisit: UIBarButtonItem!
    //var LogOff: UIBarButtonItem!
    
    var PatientNameArray = [String]()
    var DateAndTimeOfInjuryArray = [String]()
    var CompanyArray = [Int]()
    var BranchArray = [Int]()
    var StatusIndicatorArray = [String]()
    var ExamRoomsArray = [String]()
    var VisitIDArray = [Int]()
    var refreshVisits = UIRefreshControl()
    var isInitialVisitListSet = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visitsView.delegate = self
        visitsView.dataSource = self
        DataModel.sharedInstance.sessionInfo.VisitID = 0
        
        visitsView.refreshControl = self.refreshVisits
        self.refreshVisits.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshVisits.addTarget(self, action: #selector(SafetyManagerDashboardVC.refreshVisitList), for: .valueChanged)
        
        CreateNewVisit.title = "New " + "\u{2295}"
        CreateNewVisit.action = #selector(PrepareFaceSheet(sender:))
        
        LogOff.title = "Sign Out"
        LogOff.action = #selector(SafetyManagerDashboardVC.LogOutOfTheSystem(sender:))
        
        refreshVisitList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshVisitList() {
        DataModel.sharedInstance.accessNetworkDataArray(
            params: [
                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey
            ],
            wsURLPath: "Util.asmx/returnActiveVisits",
            completion: {(visits: NSArray) -> Void in
                self.testWSResponse(visits)
                self.PatientNameArray.removeAll()
                self.DateAndTimeOfInjuryArray.removeAll()
                self.CompanyArray.removeAll()
                self.BranchArray.removeAll()
                self.StatusIndicatorArray.removeAll()
                self.ExamRoomsArray.removeAll()
                self.VisitIDArray.removeAll()
                
                for visit in visits {
                    if let visitDict = visit as? NSDictionary {
                        print(visitDict)
                        // PatientNameArray
                        if visitDict.value(forKey: "first_name") != nil {
                            if visitDict.value(forKey: "last_name") != nil {
                                let firstName = visitDict.value(forKey: "first_name") as! String
                                let lastName = visitDict.value(forKey: "last_name") as! String
                                let fullName =  firstName + " " + lastName
                                self.PatientNameArray.append(fullName)
                            }
                        }
                        
                        // VisitIDArray
                        if visitDict.value(forKey: "visit_id") != nil {
                            let visitID = Int(visitDict.value(forKey: "visit_id") as! String)
                            self.VisitIDArray.append(visitID!)
                        }
                        
                        // ExamRoomsArray
                        if visitDict.value(forKey: "room_name") != nil {
                            let roomName = visitDict.value(forKey: "room_name") as! String
                            self.ExamRoomsArray.append(roomName)
                        }
                        
                        // DateAndTimeOfInjuryArray
                        if visitDict.value(forKey: "date_of_service") != nil {
                            if visitDict.value(forKey: "time_in") != nil {
                                let strDate = visitDict.value(forKey: "date_of_service") as! String
                                let strTime = visitDict.value(forKey: "time_in") as! String
                                let timeDate = strDate + " - " + strTime
                                self.DateAndTimeOfInjuryArray.append(timeDate)
                            }
                        }
                        
                        // StatusIndicatorArray
                        
                        // CompanyArray
                        if visitDict.value(forKey: "company_id") != nil {
                            let companyID = visitDict.value(forKey: "company_id") as! String
                            self.CompanyArray.append(Int(companyID)!)
                        }
                        
                        // BranchArray
                        if (visitDict.value(forKey: "companybranch_id") != nil) {
                            let branchID = visitDict.value(forKey: "companybranch_id") as! String
                            self.BranchArray.append(Int(branchID)!)
                        }
                    }
                }
                
                OperationQueue.main.addOperation({
                    self.visitsView.reloadData()
                    self.refreshVisits.endRefreshing()
                })
            }
        )
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PatientNameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let visitCell = tableView.dequeueReusableCell(withIdentifier: "Visit") as! VisitsViewCell
        visitCell.PatientName.text = PatientNameArray[indexPath.row]
        visitCell.dateTimeOfInjury.text = DateAndTimeOfInjuryArray[indexPath.row]
        DataModel.sharedInstance.accessNetworkDataObject(
            params: [
                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                "sType": "employer",
                "iObjectId": CompanyArray[indexPath.row]
            ],
            wsURLPath: "Util.asmx/returnObject",
            completion: {(company: NSDictionary) -> Void in
                let companyName = company.value(forKey: "CompanyName")
                if (self.BranchArray[indexPath.row] == 0) {
                    visitCell.PatientCompany.text = companyName as? String
                }else {
                    DataModel.sharedInstance.accessNetworkDataObject(
                        params: [
                            "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                            "sType": "employer",
                            "iObjectId": self.BranchArray[indexPath.row]
                        ],
                        wsURLPath: "Util.asmx/returnObject",
                        completion: {(branch: NSDictionary) -> Void in
                            let branchName = branch.value(forKey: "BranchName")
                            visitCell.PatientCompany.text = (companyName as? String)! + " - " + (branchName as? String)!
                        }
                    )
                }
            }
        )
        return visitCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let updateParameters = QBUpdateUserParameters()
        DataModel.sharedInstance.qbLoginParams.tags = [ExamRoomsArray[indexPath.row]]
        updateParameters.tags = [ExamRoomsArray[indexPath.row]]
        QBRequest.logIn(
            withUserLogin: DataModel.sharedInstance.qbLoginParams.login!,
            password: DataModel.sharedInstance.sessionInfo.QBPassword,
            successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                self.updateUser(params: updateParameters, completion: {(response: AnyObject) -> Void in
                    let qbUser = DataModel.sharedInstance.qbLoginParams
                    let tmUser: [String : Any] = [
                        "id" : qbUser.id,
                        "login" : qbUser.login ?? "",
                        "password" : qbUser.password ?? "",
                        "email" : qbUser.email ?? "",
                        "full_name" : qbUser.fullName ?? "",
                        "external_user_id" : qbUser.externalUserID,
                        "tag_list" : String(describing: qbUser.tags)
                    ]
                    DataModel.sharedInstance.accessNetworkDataObject(
                        params: [
                            "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                            "sUpdateType": "edit",
                            "oQbUser": tmUser
                        ],
                        wsURLPath: "Telemed.asmx/updateQbUser",
                        completion: {(response: NSDictionary) -> Void in
                            self.testWSResponse(response)
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "SendPatientToExamRoom", sender: self.VisitIDArray[indexPath.row])
                            }
                        }
                    )
                })
            }, errorBlock: {(_ response: QBResponse) -> Void in
                print("<-----------------------------------<<< Handle 2nd QB Login error")
            }
        )
    }
    
    
    func LogOutOfTheSystem(sender: UIBarButtonItem) {
        print("HEY")
        DataModel.sharedInstance.destroySession()
        if QBChat.instance().isConnected {
            QBChat.instance().disconnect(completionBlock: { (error) in
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                self.present(nextViewController, animated:true, completion:nil)
            })
        }else {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            self.present(nextViewController, animated:true, completion:nil)
        }
    }
    
    func PrepareFaceSheet(sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "CreateNewVisit", sender: sender)
    }
    
    func updateUser(params: QBUpdateUserParameters, completion: @escaping (_ response: AnyObject) -> ()) {
        QBRequest.updateCurrentUser(params, successBlock: { (response: QBResponse, user: QBUUser?) -> Void in
            print("<-----------------------------------<<< User Update succeeded")
            completion(response)
        }, errorBlock: { (response: QBResponse) -> Void in
            print("<-----------------------------------<<< Handle QB Update Current User error")
        })
    }
    
    func testWSResponse(_ response: AnyObject) {
        if response is NSArray {
            if (response.count == 0) {
                print("Got zero Array results")
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                self.present(nextViewController, animated:true, completion:nil)
                return
            }
        }else if response is NSDictionary {
            if (response.allValues.isEmpty) {
                print("Got zero Dictionary results")
                let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                self.present(nextViewController, animated:true, completion:nil)
                return
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination.isKind(of: PatientTelemedVC.self)) {
            let vc = segue.destination as! PatientTelemedVC
            vc.visitIdForSession = sender as! Int
        }else {
            //let vc = segue.destination as! PatientSortingRoomVC
        }
    }
    
}
