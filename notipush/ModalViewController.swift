//
//  ModalViewController.swift
//  notipush
//
//  Created by 三原一道 on 2022/06/02.
//

import Foundation
import UIKit

class ModalViewController: UIViewController{
    
    var delegate: ModalViewButtonDelegate?
    
    @IBAction func adButtonTpuchUp(_ sender: UIButton) {
        delegate?.AdButtonOnTouchUp()
    }
    @IBAction func unlimitButtonTouchUp(_ sender: UIButton) {
        delegate?.unlimitButtonOnTouchUp()
    }
    @IBAction func ultimateButtonTouchUp(_ sender: UIButton) {
        delegate?.ultimateButtonOnTouchUp()
    }
}

