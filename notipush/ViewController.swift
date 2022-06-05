//
//  ViewController.swift
//  notipush
//
//  Created by 三原一道 on 2022/05/16.
//

import UIKit
import GoogleMobileAds
import StoreKit
class ViewController: UIViewController, UITextViewDelegate, GADFullScreenContentDelegate, ModalViewButtonDelegate{
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var editCountLable: UILabel!
    @IBOutlet weak var editCountDescriptionLabel: UILabel!
    @IBOutlet weak var editCountDescriptionLabel2: UILabel!
    @IBOutlet weak var switchDescriptionLabel: UILabel!
    @IBOutlet weak var cancelEditButton: UIButton!
    private var modalVC: ModalViewController?
    private var bannerView: GADBannerView?
    private var lastLoginDate: Date?
    private var interstitial: GADRewardedAd?
    private var lastTitle: String?
    private var lastText: String?
    
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
        titleField.layer.cornerRadius = 6;
        titleField.layer.borderColor = UIColor.quaternaryLabel.cgColor;
        titleField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        textView.layer.cornerRadius = 6;
        textView.layer.borderColor = UIColor.quaternaryLabel.cgColor;
        textView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        registerAppData()
        loadAppData()
        
        AppStoreClass.shared.reload()
        if(!AppStoreClass.shared.isUnlimit()){
            // 一般ユーザ
            chargeEditCountIfNewDay()
            NotificationCenter.default.addObserver(self, selector: #selector(dayChangeOccured), name: .dayChanged, object: nil)
            createInterAd()
        }
        else {
            // 無制限ユーザ
            editCountLable.text = "無制限"
            editCountDescriptionLabel.isHidden = true
            editCountDescriptionLabel2.isHidden = true
        }
        
        if(!AppStoreClass.shared.isBannerDisabled()){
            // バーナーあり
            bannerView = GADBannerView(adSize: GADAdSizeBanner)
            addBannerViewToView(bannerView!)
            
            // GADBannerViewのプロパティを設定
            bannerView!.adUnitID = "ca-app-pub-3689705642710450/8110182822"
            bannerView!.rootViewController = self
            
            // バナー広告読み込み
            bannerView!.load(GADRequest())
        }
    }
    
    func createInterAd(){
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID:"ca-app-pub-3689705642710450/9127202286",
                           request: request,
                           completionHandler: { [self] ad, error in
            if let error = error {
                print("Failed 失敗です　to load interstitial ad with error: \(error.localizedDescription)")
                return
            }
            interstitial = ad
            interstitial?.fullScreenContentDelegate = self
        }
        )
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: view.safeAreaLayoutGuide,
                                attribute: .bottom,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: bannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
    }
    
    
    func notificationRequest(reqGranted:@escaping ()->Void, reqRegected:@escaping ()->Void){
        let notificationCenter = UNUserNotificationCenter.current()
        // プッシュ通知の許可を依頼する際のコード
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            // [.alert, .badge, .sound]と指定されているので、「アラート、バッジ、サウンド」の3つに対しての許可をリクエストした
            if granted {
                // 「許可」が押された場合
                reqGranted()
            } else {
                reqRegected()
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
        saveAppData()
        updateView()
    }
    
    @IBAction func modalShowButtonTouchUp(_ sender: UIButton) {
        modalVC = self.storyboard?.instantiateViewController(withIdentifier: "modal") as? ModalViewController
        modalVC?.modalPresentationStyle = .formSheet
        modalVC?.delegate = self
        present(modalVC!, animated: true, completion: nil)
        modalVC?.updateView()
    }
    
    func AdButtonOnTouchUp() {
        if interstitial != nil {
            interstitial?.present(fromRootViewController: modalVC!, userDidEarnRewardHandler: {
                self.setEditCount(count: self.getEditCount() + 1)
                self.saveAppData()
                self.updateView()
            })
        } else {
            print("Ad wasn't ready")
        }
    }
    
    func unlimitButtonOnTouchUp() {
        AppStoreClass.shared.purchaseUnlimitFromAppStore{
            self.updateView()
            self.modalVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func ultimateButtonOnTouchUp() {
        if(AppStoreClass.shared.isUnlimitPurchased){
            AppStoreClass.shared.purchaseAdblockFromAppStore{
                self.updateView()
                self.modalVC?.dismiss(animated: true, completion: nil)
            }
        }
        else{
            AppStoreClass.shared.purchaseUltimateFromAppStore{
                self.updateView()
                self.modalVC?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func restoreButtonTouchUp() {
        AppStoreClass.shared.restore(restoreSuccess: {
            let alert = UIAlertController(title: nil, message: "購入情報の復元に成功しました。", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            self.modalVC!.present(alert, animated: true, completion: nil)
            self.updateView()
        }, restoreFailed: {
            let alert = UIAlertController(title: nil, message: "購入情報の復元に失敗しました。", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            self.modalVC!.present(alert, animated: true, completion: nil)
        })
    }
    
    func switchValueChange(isOn: Bool){
        if(isOn){
            if((titleField.text ?? "").isEmpty && textView.text.isEmpty){
                errorMessage.text = "メモ通知を作成してください。"
                switchView.setOn(false, animated: true)
                return
            }
            if(isEditing){
                editingComplete()
            }
            notificationRequest(reqGranted: {
                DispatchQueue.main.async {
                    self.errorMessage.text = nil
                    self.updateView()
                    self.removeCurrentNotifications()
                    self.notify()
                    self.notifyPersistent()
                }
            }, reqRegected: {
                DispatchQueue.main.async {
                    self.switchView.setOn(false, animated: true)
                    self.errorMessage.text = "通知を許可してください。"
                    self.updateView()
                }
            })
        }
        else{
            removeCurrentNotifications()
        }
    }
    
    func updateView(){
        if(switchView.isOn){
            switchDescriptionLabel.text = "設定からバナー通知をお切りいただけます。"
        }
        else{
            switchDescriptionLabel.text = "メモ通知は１時間ごとにサイレント通知され、ロック画面に常に表示されます。"
        }
        
        if(isEditing){
            titleField.isEnabled = true
            textView.isEditable = true
            titleField.placeholder = "タイトル"
            titleField.layer.borderWidth = 0.5
            textView.layer.borderWidth = 0.5
            editButton.setTitle("完了", for: .normal)
            editButton.isEnabled = true
            cancelEditButton.isHidden = false
        } else {
            titleField.isEnabled = false
            textView.isEditable = false
            titleField.placeholder = nil
            titleField.endEditing(true)
            textView.endEditing(true)
            titleField.layer.borderWidth = 0
            textView.layer.borderWidth = 0
            editButton.setTitle("編集", for: .normal)
            editButton.isEnabled = checkEditEnabled()
            cancelEditButton.isHidden = true
        }
        
        if(AppStoreClass.shared.isUnlimit()){
            editCountLable.text = "無制限"
            editCountDescriptionLabel.isHidden = true
            editCountDescriptionLabel2.isHidden = true
        }
        if(AppStoreClass.shared.isBannerDisabled()){
            bannerView?.isHidden = true
        }
    }
    
    func checkEditEnabled() -> Bool{
        return AppStoreClass.shared.isUnlimit() || getEditCount() > 0
    }
    
    @IBAction func editTouchUp(_ sender: Any) {
        if(isEditing){
            editingComplete()
        }else{
            if(AppStoreClass.shared.isUnlimit()){
                editingStart()
            }
            else{
                if(getEditCount() > 0){
                    editingStart()
                }else{
                }
            }
        }
        updateView()
    }
    
    @IBAction func cancelEditTouchUp(_ sender: Any) {
        editingCancel()
        updateView()
    }
    
    @IBAction func titleDidBeginEditing(_ sender: UITextView) {
    }
    @IBAction func titleEditingChanged(_ sender: UITextView) {
        errorMessage.text = nil
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
    }
    
    func textViewDidChange(_ textView: UITextView) {
        errorMessage.text = nil
    }
    
    func registerAppData(){
        UserDefaults.standard.register(defaults:  [
            AppConstants.BODY_TEXT_KEY:"",
            AppConstants.TITLE_TEXT_KEY:"",
            AppConstants.NOTIFY_FLAG_KEY:false,
            AppConstants.EDIT_COUNT_KEY:3,
            AppConstants.EDIT_FLAG_KEY:false,
            AppConstants.LAST_LOGIN_DATE_KEY:Date.now
        ])
    }
    
    func saveAppData(){
        UserDefaults.standard.set(textView.text, forKey: AppConstants.BODY_TEXT_KEY)
        UserDefaults.standard.set(titleField.text, forKey: AppConstants.TITLE_TEXT_KEY)
        UserDefaults.standard.set(switchView.isOn, forKey: AppConstants.NOTIFY_FLAG_KEY)
        UserDefaults.standard.set(getEditCount(), forKey: AppConstants.EDIT_COUNT_KEY)
        UserDefaults.standard.set(isEditing, forKey: AppConstants.EDIT_FLAG_KEY)
        UserDefaults.standard.set(lastLoginDate, forKey: AppConstants.LAST_LOGIN_DATE_KEY)
    }
    
    func loadAppData(){
        AppStoreClass.shared.reload()
        textView.text = UserDefaults.standard.string(forKey: AppConstants.BODY_TEXT_KEY)
        titleField.text = UserDefaults.standard.string(forKey: AppConstants.TITLE_TEXT_KEY)
        let notifyFlag: Bool = UserDefaults.standard.bool(forKey: AppConstants.NOTIFY_FLAG_KEY)
        switchView.setOn(notifyFlag, animated: false)
        
        if(AppStoreClass.shared.isUnlimit()){
            setEditCount(count: Int.max)
        }else{
            setEditCount(count: UserDefaults.standard.integer(forKey: AppConstants.EDIT_COUNT_KEY))
        }
        isEditing = UserDefaults.standard.bool(forKey: AppConstants.EDIT_FLAG_KEY)
        lastLoginDate = UserDefaults.standard.object(forKey: AppConstants.LAST_LOGIN_DATE_KEY) as? Date
        updateView()
    }
    
    func editingStart(){
        switchView.setOn(false, animated: true)
        switchValueChange(isOn: false)
        saveAppData()
        lastTitle = titleField.text
        lastText = textView.text
        isEditing = true
        errorMessage.text = nil
    }
    
    func editingComplete(){
        isEditing = false
        if(lastTitle != titleField.text || lastText != textView.text){
            setEditCount(count: getEditCount() - 1)
        }
        saveAppData()
    }
    
    func editingCancel(){
        isEditing = false
        titleField.text = lastTitle
        textView.text = lastText
    }
    
    func setEditCount(count: Int){
        if(count == 0){
            editButton.isEnabled = false
        }else{
            editButton.isEnabled = true
        }
        editCountLable.text = String(count)
    }
    
    func getEditCount()->Int{
        return Int(editCountLable.text ?? "0") ?? 0
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
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("広告表示の失敗　Ad did fail to present full screen content.")
    }
    
    /// Tells the delegate that the ad presented full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd){
        print("広告表示の成功　Ad did present full screen content.")
    }
    
    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("広告表示を消す　Ad did dismiss full screen content.")
        createInterAd()
        modalVC?.dismiss(animated: true)
    }
    @objc func dayChangeOccured() {
        chargeEditCountIfNewDay()
    }
    
    func getTimeFromServer(completionHandler:@escaping (_ getResDate: Date?) -> Void){
        let url = URL(string: "https://www.apple.com")
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            let httpResponse = response as? HTTPURLResponse
            if(httpResponse == nil){
                completionHandler(nil)
                return
            }
            if let contentType = httpResponse!.allHeaderFields["Date"] as? String {
                //print(httpResponse)
                let dFormatter = DateFormatter()
                dFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
                dFormatter.timeZone = TimeZone.current
                dFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
                let serverTime = dFormatter.date(from: contentType)
                completionHandler(serverTime)
            }
        }
        task.resume()
    }
    
    func chargeEditCountIfNewDay(){
        getTimeFromServer(completionHandler:{(serverDate) in
            if(serverDate == nil) {
                DispatchQueue.main.sync {
                let alert = UIAlertController(title: nil, message: "ネットワークアクセスが無いため、現在時刻を取得できませんでした。", preferredStyle: .alert)
                let ok = UIAlertAction(title: "OK", style: .default)
                alert.addAction(ok)
                    self.present(alert, animated: true, completion: nil)
                    
                }
                return
            }
            let calendar = Calendar.current
            let lastday = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: self.lastLoginDate!))!
            let today = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: serverDate!))!
            let diff = calendar.dateComponents([.day], from: lastday, to: today)
            if(diff.day! >= 1){
                DispatchQueue.main.sync {
                    self.lastLoginDate = serverDate
                    self.setEditCount(count: self.getEditCount() + 1)
                    self.saveAppData()
                    self.updateView()
                }
            }
        })
    }
}
