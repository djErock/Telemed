//
//  CreditCardVC.swift
//  
//
//  Created by Erik Grosskurth on 5/18/17.
//
//

import UIKit

class CreditCardVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var delegate:ModalViewControllerDelegate?
    var ccFormOperationType = String()
    var submitAttempted = false
    var stateIdArray = [Int()]
    var stateNameArray = [String()]
    var ccIdArray = [Int()]
    var ccNameArray = [String()]
    var activeStateId = Int()
    var activeCCTypeId = Int()
    
    let errorColor : UIColor = UIColor.red
    let validColor : UIColor = UIColor.lightGray
    
    
    @IBOutlet weak var FirstNameField: UITextField!
    @IBOutlet weak var LastNameField: UITextField!
    @IBOutlet weak var Address: UITextField!
    @IBOutlet weak var Address2Field: UITextField!
    @IBOutlet weak var StatePicker: UIPickerView!
    @IBOutlet weak var ZipCodeField: UITextField!
    @IBOutlet weak var CCNumberField: UITextField!
    @IBOutlet weak var CCTypePicker: UIPickerView!
    @IBOutlet weak var CCExpMonthField: UITextField!
    @IBOutlet weak var CCExpYearField: UITextField!
    @IBOutlet weak var CCCSVField: UITextField!
    @IBOutlet weak var SubmitCCButton: UIButton!
    @IBOutlet weak var CancelCCButton: UIButton!
    
    @IBAction func CancelCCButton(_ sender: Any) {
        let refreshAlert = UIAlertController(title: "Are you sure?", message: "You will lose any unsaved information if you cancel now.", preferredStyle: UIAlertControllerStyle.alert)
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            self.delegate?.dismissed()
        }))
        refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            return
        }))
    }
    @IBAction func SubmitCCForm(_ sender: Any) {
        submitAttempted = true
        if (!validateCCForm(t: ccFormOperationType)) {
            return
        }
        let refreshAlert = UIAlertController(title: "Submit CC Form", message: ccFormOperationType + " this credit card information?", preferredStyle: UIAlertControllerStyle.alert)
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            print("Handle Ok logic here")
            DataModel.sharedInstance.accessNetworkDataObject(
                params: [
                    "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                    "sType": "credit_card",
                    "iObjectId": 0
                ],
                wsURLPath: "Util.asmx/returnObject",
                completion: {(creditCardData: NSDictionary) -> Void in
                    self.testWSResponse(creditCardData)
                    creditCardData.setValue(DataModel.sharedInstance.sessionInfo.CompanyID, forKey: "company_id")
                    creditCardData.setValue(self.activeCCTypeId, forKey: "cardtype_id")
                    creditCardData.setValue(self.activeStateId, forKey: "state_id")
                    creditCardData.setValue(self.FirstNameField.text!, forKey: "first_name")
                    creditCardData.setValue(self.LastNameField.text!, forKey: "last_name")
                    creditCardData.setValue(self.Address.text!, forKey: "address")
                    creditCardData.setValue(self.Address2Field.text!, forKey: "address2")
                    creditCardData.setValue(self.ZipCodeField.text!, forKey: "zip")
                    creditCardData.setValue(self.CCExpMonthField.text!, forKey: "exp_month")
                    creditCardData.setValue(self.CCExpYearField.text!, forKey: "exp_year")
                    creditCardData.setValue(self.CCNumberField.text!, forKey: "card_number")
                    creditCardData.setValue(self.CCCSVField.text!, forKey: "security_code")
                    DataModel.sharedInstance.accessNetworkDataObject(
                        params: [
                            "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                            "sUpdateType": self.ccFormOperationType,
                            "oCreditCard": creditCardData
                        ],
                        wsURLPath: "Telemed.asmx/updateCreditCard",
                        completion: {(response: AnyObject) -> Void in
                            self.testWSResponse(response)
                            self.delegate?.dismissed()
                        }
                    )
                }
            )
        }))
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Handle Cancel Logic here")
        }))
        present(refreshAlert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set up page styles
        
        SubmitCCButton.setTitle(ccFormOperationType + " this Credit Card", for: .normal)
        Address2Field.layer.borderWidth = 0.25
        Address2Field.layer.borderColor = validColor.cgColor
        
        // LOAD THE textview Delegate hook ups
        
        FirstNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        LastNameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        Address.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        Address2Field.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        ZipCodeField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        CCNumberField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        CCExpMonthField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        CCExpYearField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        CCCSVField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // LOAD THE PICKERS
        
        StatePicker.delegate = self
        StatePicker.dataSource = self
        
        CCTypePicker.delegate = self
        CCTypePicker.dataSource = self
        
        DataModel.sharedInstance.accessNetworkDataArray(
            params: [
                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                "sTableName": "tblStates"
            ],
            wsURLPath: "Util.asmx/populateDDL",
            completion: {(states: NSArray) -> Void in
                self.testWSResponse(states)
                for state in states {
                    if let stateDict = state as? NSDictionary {
                        if stateDict.value(forKey: "id") != nil {
                            if stateDict.value(forKey: "name") != nil {
                                self.stateIdArray.append(stateDict.value(forKey: "id") as! Int)
                                self.stateNameArray.append(stateDict.value(forKey: "name") as! String)
                            }
                        }
                    }
                }
                self.StatePicker.reloadAllComponents()
            }
        )
        DataModel.sharedInstance.accessNetworkDataArray(
            params: [
                "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                "sTableName": "tblCreditCardTypes"
            ],
            wsURLPath: "Util.asmx/populateDDL",
            completion: {(ccTypes: NSArray) -> Void in
                self.testWSResponse(ccTypes)
                for cc in ccTypes {
                    if let ccDict = cc as? NSDictionary {
                        if ccDict.value(forKey: "id") != nil {
                            if ccDict.value(forKey: "name") != nil {
                                self.ccIdArray.append(ccDict.value(forKey: "id") as! Int)
                                self.ccNameArray.append(ccDict.value(forKey: "name") as! String)
                            }
                        }
                    }
                }
                self.CCTypePicker.reloadAllComponents()
            }
        )
        
        if (ccFormOperationType == "Edit") {
            DataModel.sharedInstance.accessNetworkDataObject(
                params: [
                    "sKey": DataModel.sharedInstance.sessionInfo.SessionKey,
                    "sType": "credit_card",
                    "iObjectId": DataModel.sharedInstance.sessionInfo.ActiveCCID
                ],
                wsURLPath: "Util.asmx/returnObject",
                completion: {(creditCardData: NSDictionary) -> Void in
                    self.testWSResponse(creditCardData)
                    self.FirstNameField.text = creditCardData.value(forKey: "first_name") as? String
                    self.LastNameField.text = creditCardData.value(forKey: "last_name") as? String
                    self.Address.text = creditCardData.value(forKey: "address") as? String
                    self.Address2Field.text = creditCardData.value(forKey: "address2") as? String
                    self.ZipCodeField.text = creditCardData.value(forKey: "zip") as? String
                    self.CCNumberField.text = creditCardData.value(forKey: "card_number") as? String
                    self.CCExpMonthField.text = creditCardData.value(forKey: "exp_month") as? String
                    self.CCExpYearField.text = creditCardData.value(forKey: "exp_year") as? String
                    self.CCCSVField.text = creditCardData.value(forKey: "security_code") as? String
                    
                    self.activeCCTypeId = creditCardData.value(forKey: "cardtype_id") as! Int
                    self.activeStateId = creditCardData.value(forKey: "state_id") as! Int
                    
                }
            )
        }else {
            DataModel.sharedInstance.sessionInfo.ActiveCCID = 0
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var retCount = Int()
        if pickerView == StatePicker {
            retCount = stateIdArray.count
        } else if pickerView == CCTypePicker {
            retCount = ccIdArray.count
        }
        return retCount
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var retRow = String()
        if pickerView == StatePicker {
            retRow = stateNameArray[row]
        } else if pickerView == CCTypePicker {
            retRow = ccNameArray[row]
        }
        return retRow
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == StatePicker {
            print(stateIdArray[row])
            activeStateId = stateIdArray[row]
            if (submitAttempted) {
                let result = validateCCForm(t: ccFormOperationType)
                print( "validation proved to be " + String(describing:result) )
            }
        } else if pickerView == CCTypePicker {
            print(ccIdArray[row])
            activeCCTypeId = ccIdArray[row]
            if (submitAttempted) {
                let result = validateCCForm(t: ccFormOperationType)
                print( "validation proved to be " + String(describing:result) )
            }
        }
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if (submitAttempted) {
            let result = validateCCForm(t: ccFormOperationType)
            print( "validation proved to be " + String(describing:result) )
        }
    }
    
    func validateCCForm(t: String) -> Bool {
        print("lets Validate")
        var valid = false
        var falseCount = 0
        let fName = FirstNameField.text
        let lName = LastNameField.text
        let addy = Address.text
        let zip = ZipCodeField.text
        let cc = CCNumberField.text
        let expM = CCExpMonthField.text
        let expY = CCExpYearField.text
        let csv = CCCSVField.text
        
        if ( self.activeStateId == 0 ) {
            print("invalid state id")
            StatePicker.layer.borderWidth = 1.0
            StatePicker.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            StatePicker.layer.borderWidth = 0.25
            StatePicker.layer.borderColor = validColor.cgColor
        }
        
        if ( self.activeCCTypeId == 0 ) {
            print("invalid CC id")
            CCTypePicker.layer.borderWidth = 1.0
            CCTypePicker.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            CCTypePicker.layer.borderWidth = 0.25
            CCTypePicker.layer.borderColor = validColor.cgColor
        }
        
        if ( (fName?.characters.count)! <= 1 ) {
            print("invalid first name")
            FirstNameField.layer.borderWidth = 1.0
            FirstNameField.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            FirstNameField.layer.borderWidth = 0.25
            FirstNameField.layer.borderColor = validColor.cgColor
        }
        
        if ( (lName?.characters.count)! <= 1 ) {
            print("invalid last name")
            LastNameField.layer.borderWidth = 1.0
            LastNameField.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            LastNameField.layer.borderWidth = 0.25
            LastNameField.layer.borderColor = validColor.cgColor
        }
            
        if (addy?.isEmpty)! {
            print("empty address")
            Address.layer.borderWidth = 1.0
            Address.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }else {
            Address.layer.borderWidth = 0.25
            Address.layer.borderColor = validColor.cgColor
        }
            
        if ( (zip?.characters.count)! == 5 && chkStrForNums(string: zip!) ) {
            ZipCodeField.layer.borderWidth = 0.25
            ZipCodeField.layer.borderColor = validColor.cgColor
        }else {
            print("invalid zip code")
            ZipCodeField.layer.borderWidth = 1.0
            ZipCodeField.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }
            
        if ( (cc?.characters.count)! > 0 && chkStrForNums(string: cc!) ) {
            CCNumberField.layer.borderWidth = 0.25
            CCNumberField.layer.borderColor = validColor.cgColor
        }else {
            print("invalid credit card number")
            CCNumberField.layer.borderWidth = 1.0
            CCNumberField.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }
            
        if ( (expM?.characters.count)! == 2 && chkStrForNums(string: expM!) ) {
            CCExpMonthField.layer.borderWidth = 0.25
            CCExpMonthField.layer.borderColor = validColor.cgColor
        }else {
            print("invalid credit card exp month")
            CCExpMonthField.layer.borderWidth = 1.0
            CCExpMonthField.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }
        
        if ( (expY?.characters.count)! == 4 && chkStrForNums(string: expY!) ) {
            CCExpYearField.layer.borderWidth = 0.25
            CCExpYearField.layer.borderColor = validColor.cgColor
        }else {
            print("invalid credit card exp year")
            CCExpYearField.layer.borderWidth = 1.0
            CCExpYearField.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }
            
        if ( (csv?.characters.count)! == 3 && chkStrForNums(string: csv!) ) {
            CCCSVField.layer.borderWidth = 0.25
            CCCSVField.layer.borderColor = validColor.cgColor
        }else {
            print("invalid credit card csv")
            CCCSVField.layer.borderWidth = 1.0
            CCCSVField.layer.borderColor = errorColor.cgColor
            falseCount += 1
        }
        
        
        if (falseCount == 0) {
            valid = true
        }else {
            valid = false
        }
        
        return valid
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func chkStrForNums(string: String) -> Bool {
        return string.rangeOfCharacter(from: NSCharacterSet.decimalDigits.inverted) == nil
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
    
}

protocol ModalViewControllerDelegate:class {
    func dismissed()
}
