//
//  ViewController.swift
//  notipush
//
//  Created by 三原一道 on 2022/05/16.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }



    @IBAction func notifyTouchDown(_ sender: Any) {
        let content: UNMutableNotificationContent = UNMutableNotificationContent()
        content.title = self.textField.text!
        content.sound = UNNotificationSound.default
        content.badge = 1
        if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
        }
        
        // MARK: 通知のリクエストを作成
        let request: UNNotificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        // MARK: 通知のリクエストを実際に登録する
        UNUserNotificationCenter.current().add(request) { (error: Error?) in
            // エラーが存在しているかをif文で確認している
            if error != nil {
                print(error)
            } else {
                // MARK: エラーがないので、うまく通知を追加できた
            }
        }
    }
}

