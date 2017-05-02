//
//  VisitsViewCell.swift
//  Telemed
//
//  Created by Erik Grosskurth on 4/28/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit

class VisitsViewCell: UITableViewCell {

    @IBOutlet weak var PatientStatusIndicator: UIView!
    @IBOutlet weak var PatientName: UILabel!
    @IBOutlet weak var PatientCompany: UILabel!
    @IBOutlet weak var dateTimeOfInjury: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
