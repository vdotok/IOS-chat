//
//  YellowButton.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 21/05/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import UIKit

class YellowButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
       
    }
    
    func setupButton() {
        layer.cornerRadius = 8
        backgroundColor = .appYellowColor
        setTitleColor(.appDarkColor, for: .normal)
        titleLabel?.font = UIFont.init(name: "Manrope-Bold", size: 14)
        titleEdgeInsets = UIEdgeInsets(top: 2,left: 10,bottom:2,right: 10)
        titleLabel?.adjustsFontSizeToFitWidth = true
    }
}

