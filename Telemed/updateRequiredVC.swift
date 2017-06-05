//
//  updateRequiredVC.swift
//  Telemed
//
//  Created by Erik Grosskurth on 6/2/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit

class updateRequiredVC: UIViewController {

    @IBAction func updateApp(_ sender: Any) {
        let url = URL(string: "https://itunes.apple.com/us/app/caduceus-telemed/id1234687786?ls=1&mt=8")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
