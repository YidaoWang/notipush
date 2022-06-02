//
//  AppStoreClass.swift
//  notipush
//
//  Created by 三原一道 on 2022/06/02.
//

import Foundation
import StoreKit
import SwiftyStoreKit
final class AppStoreClass {
    private init() {}
    static let shared = AppStoreClass()
    
    // 購入済みかどうか確認する
    var isUnlimitPurchased = false
    var isUltimatePurchased = false
    
    func isUnlimit() -> Bool
    {
        return isUltimatePurchased || isUnlimitPurchased
    }
    
    func isBannerDisabled() -> Bool
    {
        return isUltimatePurchased
    }
    
    // アプリ起動時にネットに繋いでAppStoreで購入済みか確認する（1件のみ有料アイテムを登録）
    func isPurchasedWhenAppStart() {
        restore()
    }
    
    // 購入
    func purchaseUnlimitFromAppStore(onSuccess: @escaping () -> Void) {
        SwiftyStoreKit.purchaseProduct("unlimit", quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                AppStoreClass.shared.isUnlimitPurchased = true
                UserDefaults.standard.set(true, forKey: AppConstants.UNLIMIT_PURCHASE_FLAG_KEY)
                onSuccess()
            case .error(let error):
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                @unknown default: break
                }
            }
        }
    }
    
    func purchaseUltimateFromAppStore(onSuccess: @escaping () -> Void) {
        SwiftyStoreKit.purchaseProduct("ultimate", quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
                AppStoreClass.shared.isUltimatePurchased = true
                UserDefaults.standard.set(true, forKey: AppConstants.ULTIMATE_PURCHASE_FLAG_KEY)
                onSuccess()
            case .error(let error):
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                @unknown default: break
                }
            }
        }
    }
    
    // リストア
    func restore() {
        SwiftyStoreKit.restorePurchases(atomically: true) { result in
            for product in result.restoredPurchases {
                if product.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
                
                if product.productId == "unlimit" {
                    // プロダクトID1のリストア後の処理を記述する
                    self.isUnlimitPurchased = true
                    UserDefaults.standard.set(true, forKey:AppConstants.UNLIMIT_PURCHASE_FLAG_KEY)
                    return
                }
                else if product.productId == "ultimate" {
                    // プロダクトID1のリストア後の処理を記述する
                    self.isUltimatePurchased = true
                    UserDefaults.standard.set(true, forKey:AppConstants.ULTIMATE_PURCHASE_FLAG_KEY)
                    return
                }
            }
            self.isUnlimitPurchased = false
            self.isUltimatePurchased = false
        }
    }
    
    func reload(){
        self.isUnlimitPurchased = UserDefaults.standard.bool(forKey: AppConstants.UNLIMIT_PURCHASE_FLAG_KEY)
        self.isUltimatePurchased = UserDefaults.standard.bool(forKey: AppConstants.ULTIMATE_PURCHASE_FLAG_KEY)
    }
}
