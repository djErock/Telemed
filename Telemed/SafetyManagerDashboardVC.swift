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
    
    var PatientNameArray = [String]()
    var DateAndTimeOfInjuryArray = [String]()
    var CompanyArray = [String]()
    var BranchArray = [String]()
    var StatusIndicatorArray = [Bool]()
    var ExamRoomsArray = [String]()
    var VisitIdArray = [String]()
    var BranchIdArray = [String]()
    
    var refreshVisits = UIRefreshControl()
    var isInitialVisitListSet = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register the table view cell class and its reuse id
        //self.visitsView.register(UITableViewCell.self, forCellReuseIdentifier: "Visit")
        
        // This view controller itself will provide the delegate methods and row data for the table view.
        visitsView.delegate = self
        visitsView.dataSource = self
        
        DataModel.sharedInstance.sessionInfo.VisitID = 0
        
        CreateNewVisit.title = "New " + "\u{2295}"
        CreateNewVisit.action = #selector(PrepareFaceSheet(sender:))
        
        LogOff.title = "Sign Out"
        LogOff.action = #selector(SafetyManagerDashboardVC.LogOutOfTheSystem(sender:))
        
        refreshVisitList()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        
        if #available(iOS 10.0, *) {
            visitsView.refreshControl = self.refreshVisits
        } else {
            print("not #available(iOS 10.0, *)")
            //visitsView.refreshControl
        }
        self.refreshVisits.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshVisits.addTarget(self, action: #selector(SafetyManagerDashboardVC.refreshVisitList), for: .valueChanged)
 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshVisitList() {
        DataModel.sharedInstance.accessNetworkData(
            vc: self,
            loadModal: false,
            params: [
                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey
            ],
            wsURLPath: "Util.asmx/returnActiveVisits",
            completion: {(visits: AnyObject) -> Void in
                if (DataModel.sharedInstance.testWSResponse(vc: self, visits)) {
                    let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                        super.viewDidLoad()
                        super.viewWillAppear(true)
                    })
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                self.PatientNameArray.removeAll()
                self.DateAndTimeOfInjuryArray.removeAll()
                self.CompanyArray.removeAll()
                self.BranchIdArray.removeAll()
                self.BranchArray.removeAll()
                self.StatusIndicatorArray.removeAll()
                self.ExamRoomsArray.removeAll()
                self.VisitIdArray.removeAll()
                
                
                for visit in visits as! NSArray {
                    if let visitDict = visit as? NSDictionary {
                        
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
                            let visitID = visitDict.value(forKey: "visit_id") as! String
                            //totalData = (jsonDict["totalfup"] as! NSString).doubleValue
                            self.VisitIdArray.append(visitID)
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
                        if visitDict.value(forKey: "is_occupied_prov") != nil {
                            let status = visitDict.value(forKey: "is_occupied_prov") as! Bool
                            self.StatusIndicatorArray.append(status)
                        }
                        
                        
                        // ExamRoomsArray
                        if (visitDict.value(forKey: "room_name") != nil) {
                            let room_name = visitDict.value(forKey: "room_name") as! String
                            self.ExamRoomsArray.append(room_name)
                        }
                        
                        // BranchIdArray
                        if (visitDict.value(forKey: "companybranch_id") != nil) {
                            let companyBranchName = visitDict.value(forKey: "companybranch_id") as! String
                            self.BranchIdArray.append(companyBranchName)
                        }
                        
                        
                        // CompanyArray
                        if (visitDict.value(forKey: "company_name") != nil) {
                            let companyName = visitDict.value(forKey: "company_name") as! String
                            self.CompanyArray.append(companyName)
                        }
                        
                        // BranchArray
                        if (visitDict.value(forKey: "branch_name") != nil) {
                            let sBranch = visitDict.value(forKey: "branch_name") as! String
                            if ( sBranch.isEmpty ) {
                                self.BranchArray.append("No Branch")
                            }else {
                                let companyBranchName = visitDict.value(forKey: "branch_name") as! String
                                self.BranchArray.append(companyBranchName)
                            }
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
    
    func tableView(_ visitsTableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let visitCell = visitsTableView.dequeueReusableCell(withIdentifier: "Visit") as! VisitsViewCell
        
        visitCell.PatientName.text = PatientNameArray[indexPath.row]
        visitCell.dateTimeOfInjury.text = DateAndTimeOfInjuryArray[indexPath.row]
        
        if StatusIndicatorArray[indexPath.row] {
            visitCell.PatientStatusIndicator.backgroundColor = UIColor.green
        }else {
            visitCell.PatientStatusIndicator.backgroundColor = UIColor.red
        }
        
        if ( BranchIdArray[indexPath.row] == "0" ) {
            visitCell.PatientCompany.text = CompanyArray[indexPath.row]
        }else {
            visitCell.PatientCompany.text = CompanyArray[indexPath.row] + " - " + BranchArray[indexPath.row]
        }
        
        return visitCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("<---------<<< HEY")
        if (self.VisitIdArray[indexPath.row] == "0") {
            
        }else {
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
                        DataModel.sharedInstance.accessNetworkData(
                            vc: self,
                            loadModal: false,
                            params: [
                                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                "sUpdateType": "edit",
                                "oQbUser": tmUser
                            ],
                            wsURLPath: "Telemed.asmx/updateQbUser",
                            completion: {(response: AnyObject) -> Void in
                                if (DataModel.sharedInstance.testWSResponse(vc: self, response)) {
                                    let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                                        self.viewDidLoad()
                                        self.viewWillAppear(true)
                                    })
                                    self.present(alertController, animated: true, completion: nil)
                                    return
                                }
                                DispatchQueue.main.async {
                                    self.performSegue(withIdentifier: "SendPatientToExamRoom", sender: Int(self.VisitIdArray[indexPath.row]) )
                                }
                            }
                        )
                    })
                }, errorBlock: {(_ response: QBResponse) -> Void in
                    print("<-----------------------------------<<< Handle 2nd QB Login error")
                }
            )
        }
    }
    
    
    func LogOutOfTheSystem(sender: UIBarButtonItem) {
        print("LogOutOfTheSystem")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination.isKind(of: PatientTelemedVC.self)) {
            let vc = segue.destination as! PatientTelemedVC
            vc.visitIdForSession = sender as! Int
        }else {
            //let vc = segue.destination as! PatientSortingRoomVC
        }
    }
    
}
