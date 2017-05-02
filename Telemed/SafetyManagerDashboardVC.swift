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
    
    var PatientNameArray = [String]()
    var DateAndTimeOfInjuryArray = [String]()
    var CompanyBranchArray = [String]()
    var StatusIndicatorArray = [String]()
    var VisitIDArray = [Int]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visitsView.delegate = self
        visitsView.dataSource = self
        DataModel.sharedInstance.sessionInfo.VisitID = 0
        let sessionKey = DataModel.sharedInstance.sessionInfo.SessionKey
        CallWebService.sharedInstance.getActiveVisits(
            k: sessionKey,
            completion: {(oVisits: AnyObject) -> Void in
                print(oVisits)
                if let visitArray = oVisits["d"] as? NSArray {
                    for visit in visitArray {
                        if let visitDict = visit as? NSDictionary {
                            
                            // Name
                            
                            if visitDict.value(forKey: "first_name") != nil {
                                if visitDict.value(forKey: "last_name") != nil {
                                    let firstName = visitDict.value(forKey: "first_name") as! String
                                    let lastName = visitDict.value(forKey: "last_name") as! String
                                    let fullName =  firstName + " " + lastName
                                    self.PatientNameArray.append(fullName)
                                }
                            }
                            
                            // Visit ID
                            
                            if visitDict.value(forKey: "visit_id") != nil {
                                
                                let visitID = Int(visitDict.value(forKey: "visit_id") as! String)
                                self.VisitIDArray.append(visitID!)
                            }
                            
                            
 
                            OperationQueue.main.addOperation({
                                self.visitsView.reloadData()
                            })
                        }
                    }
                }
            }
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PatientNameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let visitCell = tableView.dequeueReusableCell(withIdentifier: "Visit") as! VisitsViewCell
        visitCell.PatientName.text = PatientNameArray[indexPath.row]
        //visitCell.VisitID.text = PatientNameArray[indexPath.row]
        return visitCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "SendPatientToExamRoom", sender: VisitIDArray[indexPath.row])
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
