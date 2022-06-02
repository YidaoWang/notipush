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
    private var modalVC: ModalViewController?
    private var bannerView: GADBannerView!
    private var editFlag: Bool = false
    private var lastLoginDate: Date?
    private var interstitial: GADInterstitialAd?
    @IBOutlet weak var editCountDescriptionLabel: UILabel!
    
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
        notificationRequest()
        
        AppStoreClass.shared.reload()
        if(!AppStoreClass.shared.isUnlimit()){
            // 一般ユーザ
            let f = DateFormatter()
            f.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMd", options: 0, locale: Locale(identifier: "ja_JP"))
            if(f.string(from: lastLoginDate!) != f.string(from: Date.now)){
                lastLoginDate = Date.now
                setEditCount(count: 3)
                saveAppData()
            }
            createInterAd()
        }
        else {
            // 無制限ユーザ
            editCountLable.text = "無制限"
            editCountDescriptionLabel.isHidden = true
        }
        
        if(!AppStoreClass.shared.isBannerDisabled()){
            // バーナーあり
            bannerView = GADBannerView(adSize: GADAdSizeBanner)
            addBannerViewToView(bannerView)
            
            // GADBannerViewのプロパティを設定
            bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
            bannerView.rootViewController = self
            
            // バナー広告読み込み
            bannerView.load(GADRequest())
        }
    }
    
    func createInterAd(){
            let request = GADRequest()
            GADInterstitialAd.load(withAdUnitID:"ca-app-pub-3940256099942544/4411468910",
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
        if(switchView.isOn){
            switchEditMode(isOn: false)
        }
        self.view.endEditing(true)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        switchValueChange(isOn: sender.isOn)
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
            interstitial?.present(fromRootViewController: modalVC!)
        } else {
            print("Ad wasn't ready")
        }
    }
    
    func unlimitButtonOnTouchUp() {
        AppStoreClass.shared.purchaseUnlimitFromAppStore{
            self.editCountLable.text = "無制限"
            self.editCountDescriptionLabel.isHidden = true
            self.editButton.isEnabled = true
            self.modalVC?.dismiss(animated: true, completion: nil)
        }
    }
    
    func ultimateButtonOnTouchUp() {
        AppStoreClass.shared.purchaseUltimateFromAppStore{
            self.editCountLable.text = "無制限"
            self.editCountDescriptionLabel.isHidden = true
            self.bannerView.isHidden = true
            self.editButton.isEnabled = true
            self.modalVC?.dismiss(animated: true, completion: nil)
        }
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
            switchEditMode(isOn: false)
        }
        else{
            removeCurrentNotifications()
        }
        saveAppData()
    }
    
    @IBAction func editTouchUp(_ sender: Any) {
        if(AppStoreClass.shared.isUnlimit()){
            errorMessage.text = nil
            switchView.setOn(false, animated: true)
            switchEditMode(isOn: true)
            saveAppData()
        }
        else{
            let count = getEditCount()
            if(count > 0){
                setEditCount(count: count-1)
                errorMessage.text = nil
                switchView.setOn(false, animated: true)
                switchEditMode(isOn: true)
                saveAppData()
            }else{
                
            }
        }
    }
    
    @IBAction func titleDidBeginEditing(_ sender: UITextView) {
    }
    @IBAction func titleEditingChanged(_ sender: UITextView) {
        saveAppData()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
    }
    
    func textViewDidChange(_ textView: UITextView) {
        saveAppData()
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
        UserDefaults.standard.set(editFlag, forKey: AppConstants.EDIT_FLAG_KEY)
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
        editFlag = UserDefaults.standard.bool(forKey: AppConstants.EDIT_FLAG_KEY)
        switchEditMode(isOn: editFlag)
        lastLoginDate = UserDefaults.standard.object(forKey: AppConstants.LAST_LOGIN_DATE_KEY) as? Date
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
    
    func switchEditMode(isOn: Bool){
        editFlag = isOn
        if(isOn){
            titleField.isEnabled = true
            textView.isEditable = true
            titleField.layer.borderWidth = 0.5
            textView.layer.borderWidth = 0.5
            editButton.isHidden = true
        }
        else{
            titleField.isEnabled = false
            textView.isEditable = false
            titleField.endEditing(true)
            textView.endEditing(true)
            titleField.layer.borderWidth = 0
            textView.layer.borderWidth = 0
            editButton.isHidden = false
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
    
    func adDidRecordImpression(_ ad: GADFullScreenPresentingAd)
    {
        setEditCount(count: getEditCount() + 1)
        saveAppData()
    }
}
