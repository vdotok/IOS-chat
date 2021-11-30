//
//  TextView+Extensions.swift
//  Chat-Demo-IOS
//
//  Created by usama farooq on 06/06/2021.
//  Copyright © 2021 VDOTOK. All rights reserved.
//

import Foundation
import UIKit

extension UITextView{

    func setPlaceholder() {

        let placeholderLabel = UILabel()
        placeholderLabel.text = "Type your message"
        placeholderLabel.font = UIFont.init(name: "Manrope-Medium", size: 16)
        placeholderLabel.sizeToFit()
        placeholderLabel.tag = 222
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (self.font?.pointSize)! / 2)
        placeholderLabel.textColor = .placeHolder
        placeholderLabel.isHidden = !self.text.isEmpty

        self.addSubview(placeholderLabel)
    }

    func checkPlaceholder() {
        let placeholderLabel = self.viewWithTag(222) as! UILabel
        placeholderLabel.isHidden = !self.text.isEmpty
    }

}
