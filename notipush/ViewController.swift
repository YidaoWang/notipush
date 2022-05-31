//
//  ViewController.swift
//  notipush
//
//  Created by 三原一道 on 2022/05/16.
//

import UIKit

class ViewController: UIViewController, UITextViewDelegate{
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var errorMessage: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.myViewController = self
        textView.delegate = self
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
                tapGR.cancelsTouchesInView = false
                self.view.addGestureRecognizer(tapGR)
        titleField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        titleField.leftViewMode = UITextField.ViewMode.always
        titleField.layer.borderWidth = 0.5;
        titleField.layer.cornerRadius = 6;
        titleField.layer.borderColor = UIColor.quaternaryLabel.cgColor;
        titleField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        textView.layer.borderWidth = 0.5;
        textView.layer.cornerRadius = 6;
        textView.layer.borderColor = UIColor.quaternaryLabel.cgColor;
        textView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        loadAppData()
        notificationRequest()
    }
    
    func notificationRequest(){
        let notificationCenter = UNUserNotificationCenter.current()
        // プッシュ通知の許可を依頼する際のコード
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            // [.alert, .badge, .sound]と指定されているので、「アラート、バッジ、サウンド」の3つに対しての許可をリクエストした
            if granted {
                // 「許可」が押された場合
            } else {
                let alert = UIAlertController(title: nil, message: "アプリで通知を受け取るために、設定で通知を許可してください。", preferredStyle: .alert)
                let yes = UIAlertAction(title: "設定を開く", style: .default, handler: { (action) -> Void in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)})
                let no = UIAlertAction(title: "許可しない", style: .cancel, handler: { (action) -> Void in
                    })
                alert.addAction(yes)
                alert.addAction(no)
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

    @IBAction func switchValueChanged(_ sender: UISwitch) {
        switchValueChange(isOn: sender.isOn)
    }
    
    func switchValueChange(isOn: Bool){
        if(isOn){
            if((titleField.text ?? "").isEmpty && textView.text.isEmpty){
                errorMessage.text = "メモ通知を作成してください。"
                switchView.setOn(false, animated: true)
                return
            }
            removeCurrentNotifications()
            notify()
            notifyPersistent()
        }
        else{
            removeCurrentNotifications()
        }
        switchNotifyViewChange(isOn: isOn)
        saveAppData()
    }

    
    @IBAction func titleDidBeginEditing(_ sender: Any) {
        errorMessage.text = nil
        switchView.setOn(false, animated: true)
        switchValueChange(isOn: false)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        errorMessage.text = nil
        switchView.setOn(false, animated: true)
        switchValueChange(isOn: false)
    }
    
    func saveAppData(){
        UserDefaults.standard.set(textView.text, forKey: AppConstants.BODY_TEXT_KEY)
        UserDefaults.standard.set(titleField.text, forKey: AppConstants.TITLE_TEXT_KEY)
        UserDefaults.standard.set(switchView.isOn, forKey: AppConstants.NOTIFY_FLAG_KEY)
    }
    
    func loadAppData(){
        textView.text = UserDefaults.standard.string(forKey: AppConstants.BODY_TEXT_KEY)
        titleField.text = UserDefaults.standard.string(forKey: AppConstants.TITLE_TEXT_KEY)
        let notifyFlag: Bool = UserDefaults.standard.bool(forKey: AppConstants.NOTIFY_FLAG_KEY)
        switchView.setOn(notifyFlag, animated: false)
        switchNotifyViewChange(isOn: notifyFlag)
    }
    
    func switchNotifyViewChange(isOn: Bool){
        if(isOn){
            titleField.endEditing(true)
            textView.endEditing(true)
            titleField.layer.borderWidth = 0
            textView.layer.borderWidth = 0
        }
        else{
            titleField.layer.borderWidth = 0.5
            textView.layer.borderWidth = 0.5
        }
    }
    
    func removeCurrentNotifications(){
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func notify(_ sound: UNNotificationSound! = UNNotificationSound.default){
        let content: UNMutableNotificationContent = UNMutableNotificationContent()
        
        if((titleField.text ?? "").isEmpty){
            content.title = AppConstants.TITLE_DEFAULT_VALUE
        }
        else{
            content.title = titleField.text!
        }
        content.body = textView.text
        content.sound = sound
        content.badge = 1
        if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
        }
        requestNotification(content: content, trigger: nil)
    }

    func notifyPersistent(){
        let content: UNMutableNotificationContent = UNMutableNotificationContent()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(60*60), repeats: true)
        if((titleField.text ?? "").isEmpty){
            content.title = AppConstants.TITLE_DEFAULT_VALUE
        }
        else{
            content.title = titleField.text!
        }
        content.body = textView.text
        content.sound = nil
        content.badge = 1
        if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
        }
        requestNotification(content: content, trigger: trigger)
    }
    
    func requestNotification(content: UNMutableNotificationContent, trigger: UNNotificationTrigger!){
        // MARK: 通知のリクエストを作成
        let request: UNNotificationRequest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // MARK: 通知のリクエストを実際に登録する
        UNUserNotificationCenter.current().add(request) { (error: Error?) in
            // エラーが存在しているかをif文で確認している
            if error != nil {
                print(error!)
            } else {
                // MARK: エラーがないので、うまく通知を追加できた
            }
        }
    }
}
