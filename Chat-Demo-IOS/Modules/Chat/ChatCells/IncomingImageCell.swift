//
//  IncomingImageCell.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 01/06/2021.
//

import UIKit

class IncomingImageCell: UITableViewCell {
    
    @IBOutlet weak var chatImage: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var userName: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        containerView.layer.cornerRadius = 8

    }

    
    func configure(with url: URL?) {
        if let url = url {
            if let data = try? Data(contentsOf: url)
            {
                let image: UIImage = UIImage(data: data)!
                chatImage.image = image
            }
        }
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
