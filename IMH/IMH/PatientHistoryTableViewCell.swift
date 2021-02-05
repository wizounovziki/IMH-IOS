//
//  PatientHistoryTableViewCell.swift
//  IMH
//
//  Created by admin user on 21/1/21.
//

import UIKit

class PatientHistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var outTimeDate: UILabel!
    @IBOutlet weak var outTimeClock: UILabel!
    @IBOutlet weak var outStatus: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
