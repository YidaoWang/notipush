//
//  ModalViewController.swift
//  notipush
//
//  Created by 三原一道 on 2022/06/02.
//

import Foundation
import UIKit

class ModalViewController: UIViewController{
    
    @IBOutlet weak var adView: UIView!
    @IBOutlet weak var adButton: UIButton!
    @IBOutlet weak var unlimitButton: UIButton!
    @IBOutlet weak var ultimateButton: UIButton!
    @IBOutlet weak var adButtonWidth100: NSLayoutConstraint!
    @IBOutlet weak var ultimateLabel: UILabel!
    @IBOutlet weak var ultimateHeight: NSLayoutConstraint!
    var delegate: ModalViewButtonDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
    }
    
    func updateView(){
        if(AppStoreClass.shared.isUnlimit()){
            adButton.setAttributedTitle(NSAttributedString(string: "無制限",
                                                           attributes: [NSAttributedString.Key.foregroundColor : UIColor.systemGray]), for: .normal)
            adButton.frame = CGRect(x:adButton.frame.minX+20, y:adButton.frame.minY, width:80, height:28)
            adButtonWidth100.constant = 80
            adButton.isEnabled = false
            unlimitButton.setAttributedTitle(NSAttributedString(string: "購入済み",
                                                                attributes: [NSAttributedString.Key.foregroundColor : UIColor.systemGray]), for: .normal)
            if(!AppStoreClass.shared.isBannerDisabled())
            {
                ultimateLabel.text = "バナー広告削除"
                ultimateHeight.constant = 120
                ultimateButton.setAttributedTitle(NSAttributedString(string: "¥120",
                                                                     attributes: [NSAttributedString.Key.foregroundColor : UIColor.systemBlue]), for:.normal)
                unlimitButton.isEnabled = false
            }
            else{
                ultimateButton.setAttributedTitle(NSAttributedString(string: "購入済み",
                                                                     attributes: [NSAttributedString.Key.foregroundColor : UIColor.systemGray]), for:.normal)
                ultimateButton.isEnabled = false
            }
        }
    }
    
    @IBAction func adButtonTpuchUp(_ sender: UIButton) {
        delegate?.AdButtonOnTouchUp()
    }
    @IBAction func unlimitButtonTouchUp(_ sender: UIButton) {
        delegate?.unlimitButtonOnTouchUp()
    }
    @IBAction func ultimateButtonTouchUp(_ sender: UIButton) {
        delegate?.ultimateButtonOnTouchUp()
    }
    
    @IBAction func restoreButtonTouchUp(_ sender: UIButton) {
        delegate?.restoreButtonTouchUp()
    }
    
    @IBAction func termsButtonTouchUp(_ sender: Any) {
        guard let url = URL(string: "https://yidaowang.github.io/notipush.github.io/terms") else { return }
        UIApplication.shared.open(url)
    }
    
}

