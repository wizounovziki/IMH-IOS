//
//  PatientListTableViewCell.swift
//  IMH
//
//  Created by admin user on 19/1/21.
//

import UIKit

class PatientListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var outWard: UILabel!
    @IBOutlet weak var outName: UILabel!
    @IBOutlet weak var outNRIC: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
