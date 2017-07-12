//
//  FaceSheetVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 5/16/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit

class FaceSheetVC: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    // First Name Elements
    @IBOutlet weak var fNameLabel: UILabel!
    @IBOutlet weak var fNameText: UITextField!
    // Last Name Elements
    @IBOutlet weak var lNameLabel: UILabel!
    @IBOutlet weak var lNameText: UITextField!
    // SSN Elements
    @IBOutlet weak var ssnLabel: UILabel!
    @IBOutlet weak var ssnText: UITextField!
    // DOB Elements
    @IBOutlet weak var dobLabel: UILabel!
    @IBOutlet weak var DOBPicker: UIDatePicker!
    // MODAL ELEMENTS
    @IBOutlet weak var modalShade: UIView!
    @IBOutlet weak var modalSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var ccLabel: UILabel!
    @IBOutlet weak var ccTableView: UITableView!
    // Page Buttons
    @IBOutlet weak var submitNewVisit: UIButton!
    @IBOutlet weak var CancelNewVisit: UIBarButtonItem!
    
    @IBAction func SubmitFaceSheetForm(_ sender: Any) {
        submitAttempted = true
        if (!validateFSForm()) { return }
        self.showModal()
        DataModel.sharedInstance.accessNetworkData(
            vc: self,
            loadModal: false,
            params: [
                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                "sType": "form_facesheet",
                "iObjectId": 0
            ],
            wsURLPath: "Util.asmx/returnObject",
            completion: {(FaceSheetForm: AnyObject) -> Void in
                if (DataModel.sharedInstance.testWSResponse(vc: self, FaceSheetForm)) {
                    let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                        super.viewDidLoad()
                        super.viewWillAppear(true)
                    })
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                FaceSheetForm.setValue(DataModel.sharedInstance.sessionInfo.CompanyID, forKey: "company_id")
                FaceSheetForm.setValue(self.fNameText.text, forKey: "first_name")
                FaceSheetForm.setValue(self.lNameText.text, forKey: "last_name")
                var ssn = String(describing: self.ssnText.text!)
                ssn.insert("-", at: ssn.index(ssn.startIndex, offsetBy: 5))
                ssn.insert("-", at: ssn.index(ssn.startIndex, offsetBy: 3))
                FaceSheetForm.setValue(ssn, forKey: "ssn")
                FaceSheetForm.setValue(String(describing:self.DOBPicker.date), forKey: "date_of_birth")
                FaceSheetForm.setValue(DataModel.sharedInstance.sessionInfo.ActiveCCID, forKey: "creditcard_id")
                
                DataModel.sharedInstance.accessNetworkData(
                    vc: self,
                    loadModal: true,
                    params: [
                        "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                        "oFormFS": FaceSheetForm
                    ],
                    wsURLPath: "Telemed.asmx/submitPatient",
                    completion: {(results: AnyObject) -> Void in
                        
                        if (DataModel.sharedInstance.testWSResponse(vc: self, results)) {
                            let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                                super.viewDidLoad()
                                super.viewWillAppear(true)
                            })
                            self.present(alertController, animated: true, completion: nil)
                            return
                        }
                        let updateParameters = QBUpdateUserParameters()
                        DataModel.sharedInstance.qbLoginParams.tags = [results.value(forKey: "room_name")!]
                        updateParameters.tags = [results.value(forKey: "room_name")!]
                        QBRequest.logIn(
                            withUserLogin: DataModel.sharedInstance.qbLoginParams.login!,
                            password: DataModel.sharedInstance.sessionInfo.QBPassword,
                            successBlock: {(_ response: QBResponse, _ user: QBUUser?) -> Void in
                                print("<-----------------------------------<<< 2nd Login succeeded")
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
                                                let vidStr = String(describing: results.value(forKey: "key")!)
                                                self.hideModal()
                                                self.performSegue(withIdentifier: "SendNewPatientToExamRoom", sender: Int(vidStr))
                                            }
                                        }
                                    )
                                })
                        }, errorBlock: {(_ response: QBResponse) -> Void in
                            print("<-----------------------------------<<< Handle 2nd QB Login error")
                        })
                    }
                )
            }
        )
    }
    // CC Elements
    @IBAction func addNewCC(_ sender: UIButton) {
        print("Add CC")
    }
    @IBAction func editSelectedCC(_ sender: UIButton) {
        print("Edit CC")
    }
    @IBAction func deleteSelectedCC(_ sender: UIButton) {
        if (DataModel.sharedInstance.sessionInfo.ActiveCCID != 0) {
            let deleteAlert = UIAlertController(title: "Delete credit card...", message: "Are you sure you want to delete this card from the system?", preferredStyle: UIAlertControllerStyle.alert)
            deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                DataModel.sharedInstance.accessNetworkData(
                    vc: self,
                    loadModal: false,
                    params: [
                        "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                        "sType": "credit_card",
                        "iObjectId": DataModel.sharedInstance.sessionInfo.ActiveCCID
                    ],
                    wsURLPath: "Util.asmx/returnObject",
                    completion: {(creditCardData: AnyObject) -> Void in
                        if (DataModel.sharedInstance.testWSResponse(vc: self, creditCardData)) {
                            let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                                self.viewDidLoad()
                                self.viewWillAppear(true)
                            })
                            self.present(alertController, animated: true, completion: nil)
                            return
                        }
                        creditCardData.setValue(DataModel.sharedInstance.sessionInfo.ActiveCCID, forKey: "creditcard_id")
                        DataModel.sharedInstance.accessNetworkData(
                            vc: self,
                            loadModal: false,
                            params: [
                                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                                "sUpdateType": "Delete",
                                "oCreditCard": creditCardData
                            ],
                            wsURLPath: "Telemed.asmx/updateCreditCard",
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
                                self.updateCreditCardList()
                            }
                        )
                    }
                )
            }))
            deleteAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                return
            }))
            self.present(deleteAlert, animated: true, completion: nil)
        }else {
            let alert = UIAlertController(title: "Wait...", message: "Please select a card to delete, thank you.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
 
    @IBAction func DOBPickerChangeEvent(_ sender: Any) {
        self.view.endEditing(true)
        if (submitAttempted) {
            let date = Date()
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: date)
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY"
            let birthYear = formatter.string(from: DOBPicker.date)
            if (Int(birthYear)! > (Int(currentYear) - 13)) {
                DOBPicker.layer.borderWidth = 1.0
                DOBPicker.layer.borderColor = errorColor.cgColor
            }else {
                DOBPicker.layer.borderWidth = 0.25
                DOBPicker.layer.borderColor = validColor.cgColor
            }
        }
    }
    
    
    // Arrays for UITableView
    var CardNameArray = [String]()
    var CardIDArray = [Int]()
    
    // Globals
    var selectedCCId = Int()
    let errorColor : UIColor = UIColor.red
    let validColor : UIColor = UIColor.lightGray
    var submitAttempted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fNameText.becomeFirstResponder()
        
        fNameText.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lNameText.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        ssnText.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        self.fNameText.delegate = self;
        self.lNameText.delegate = self;
        self.ssnText.delegate = self;
        
        ccTableView.delegate = self
        ccTableView.dataSource = self
        ccTableView.layer.borderWidth = 1.0
        ccTableView.layer.borderColor = UIColor.gray.cgColor
        self.updateCreditCardList()
        
        CancelNewVisit.title = "Cancel"
        CancelNewVisit.action = #selector(self.DestroyFaceSheet(sender: ))
        
    }
    
    func DestroyFaceSheet(sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "CancelNewVisitBackToDashBoard", sender: sender)
    }
    
    func updateCreditCardList() {
        CardNameArray = [String]()
        CardIDArray = [Int]()
        DataModel.sharedInstance.accessNetworkData(
            vc: self,
            loadModal: false,
            params: [
                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                "sTableName": "none"
            ],
            wsURLPath: "Util.asmx/populateDDLCreditCards",
            completion: {(creditCards: AnyObject) -> Void in
                if (DataModel.sharedInstance.testWSResponse(vc: self, creditCards)) {
                    let alertController = UIAlertController(title: "Title", message: "This app is experiencing connectivity issues. Please check your internet connection. If the problem persists, please contact a Caduceus IT professional to help sort out the problems, Thanks.", preferredStyle: UIAlertControllerStyle.alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { UIAlertAction in
                        self.viewDidLoad()
                        self.viewWillAppear(true)
                    })
                    self.present(alertController, animated: true, completion: nil)
                    return
                }
                for card in creditCards as! NSArray {
                    if let cardDict = card as? NSDictionary {
                        if cardDict.value(forKey: "id") != nil && cardDict.value(forKey: "name") != nil {
                            self.CardNameArray.append(cardDict.value(forKey: "name") as! String)
                            self.CardIDArray.append(cardDict.value(forKey: "id") as! Int)
                        }
                    }
                }
                OperationQueue.main.addOperation({
                    self.ccTableView.reloadData()
                })
            }
        )
    }
    
    func updateUser(params: QBUpdateUserParameters, completion: @escaping (_ response: AnyObject) -> ()) {
        QBRequest.updateCurrentUser(params, successBlock: { (response: QBResponse, user: QBUUser?) -> Void in
            print("<-----------------------------------<<< User Update succeeded")
            completion(response)
        }, errorBlock: { (response: QBResponse) -> Void in
            print("<-----------------------------------<<< Handle QB Update Current User error")
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("There are " + String(CardNameArray.count) + " cards on file")
        return CardNameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CreditCardCell = tableView.dequeueReusableCell(withIdentifier: "CreditCard", for: indexPath) as! CreditCardsViewCell
        if (!CardNameArray.isEmpty) {
            CreditCardCell.CreditCardName.text = CardNameArray[indexPath.row]
            CreditCardCell.cardId = CardIDArray[indexPath.row]
        }else {
            CreditCardCell.CreditCardName.text = "Please add a credit card " + "\u{2295}"
            CreditCardCell.cardId = 0
        }
        return CreditCardCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DataModel.sharedInstance.sessionInfo.ActiveCCID = CardIDArray[indexPath.row]
        print("selected a row")
        print(indexPath)
    }
    
    func validateFSForm() -> Bool {
        print("lets Validate")
        var valid = false
        var falseCount = 0
        let fName = fNameText.text
        let lName = lNameText.text
        let ssn = ssnText.text
        
        if ( (fName?.characters.count)! <= 1 ) {
            print("invalid first name")
            fNameText.layer.borderWidth = 1.0
            fNameText.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            fNameText.layer.borderWidth = 0.25
            fNameText.layer.borderColor = validColor.cgColor
        }
        
        if ( (lName?.characters.count)! <= 1 ) {
            print("invalid first name")
            lNameText.layer.borderWidth = 1.0
            lNameText.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            lNameText.layer.borderWidth = 0.25
            lNameText.layer.borderColor = validColor.cgColor
        }
        
        if ( (ssn?.characters.count)! == 9 && chkStrForNums(string: ssn!) ) {
            ssnText.layer.borderWidth = 0.25
            ssnText.layer.borderColor = validColor.cgColor
        }else {
            print("invalid social security number")
            ssnText.layer.borderWidth = 1.0
            ssnText.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }
        
        let date = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY"
        let birthYear = formatter.string(from: DOBPicker.date)
        if (Int(birthYear)! > (Int(currentYear) - 13)) {
            print("Not old enough")
            DOBPicker.layer.borderWidth = 1.0
            DOBPicker.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            DOBPicker.layer.borderWidth = 0.25
            DOBPicker.layer.borderColor = validColor.cgColor
        }
        
        if (DataModel.sharedInstance.sessionInfo.ActiveCCID == 0) {
            print("No card chosen")
            ccTableView.layer.borderWidth = 1.0
            ccTableView.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            ccTableView.layer.borderWidth = 0.25
            ccTableView.layer.borderColor = validColor.cgColor
        }
        
        
        if (falseCount == 0) {
            valid = true
        }else {
            valid = false
        }
        
        return valid
        
    }
    
    func showModal() {
        UIView.animate(
            withDuration: 0.35,
            animations: {
                //self.modalShade.alpha = 0.9
            }
        )
        UIView.animate(
            withDuration: 0.35,
            animations: {
                //self.modalSpinner.alpha = 1
            }
        )
    }
    
    func hideModal() {
        UIView.animate(
            withDuration: 0.35,
            animations: {
                //self.modalShade.alpha = 0
        }
        )
        UIView.animate(
            withDuration: 0.35,
            animations: {
                //self.modalSpinner.alpha = 0
            }
        ) 
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    func textFieldDidChange(_ textField: UITextField) {
        if (submitAttempted) {
            let result = validateFSForm()
            print( "validation proved to be " + String(describing:result) )
        }
    }
    
    func chkStrForNums(string: String) -> Bool {
        return string.rangeOfCharacter(from: NSCharacterSet.decimalDigits.inverted) == nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewCC" {
            if let modalVC1 = segue.destination as? CreditCardVC {
                modalVC1.delegate = self
                modalVC1.ccFormOperationType = "Add"
            }
        }else if segue.identifier == "EditCC" {
            if (DataModel.sharedInstance.sessionInfo.ActiveCCID != 0) {
                if let modalVC1 = segue.destination as? CreditCardVC {
                    modalVC1.delegate = self
                    modalVC1.ccFormOperationType = "Edit"
                }
            }else {
                let alert = UIAlertController(title: "Wait...", message: "Please select a card to edit, thank you.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
        }else if (segue.destination.isKind(of: PatientTelemedVC.self)) {
            let vc = segue.destination as! PatientTelemedVC
            vc.visitIdForSession = sender as! Int
        }else {
            
        }
    }

}

extension FaceSheetVC: ModalViewControllerDelegate {
    func dismissed() {
        dismiss(animated: true, completion: nil)//dismiss the presented view controller
        self.updateCreditCardList()
    }
}
