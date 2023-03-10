//
//  outgoingImageCell.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 01/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import UIKit
import SDWebImage

class outgoingImageCell: UITableViewCell {
    
    @IBOutlet weak var chatImage: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var messageStatus: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configure(with url: URL?) {
        chatImage.sd_setImage(with:url, placeholderImage: UIImage(named: "loading"))
    }
    
    func configure(seen status: String ) {
        messageStatus.text = status
    }
    
}
