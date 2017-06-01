//
//  CreditCardsViewCell.swift
//  Telemed
//
//  Created by Erik Grosskurth on 5/17/17.
//  Copyright © 2017 Caduceus USA. All rights reserved.
//

import UIKit

class CreditCardsViewCell: UITableViewCell {

    @IBOutlet weak var CreditCardName: UILabel!
    @IBAction func EditCard(_ sender: Any) {
        print("Need to edit this card")
        print(sender)
    }
    @IBAction func DeleteCard(_ sender: Any) {
        print("Need to delete this card")
        print(sender)
    }
    
    var cardId = Int()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
