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
    
    var isUnlimitPurchased = false
    var isUltimatePurchased = false
    var isAdblockPurchased = false
    
    func isUnlimit() -> Bool
    {
        return isUltimatePurchased || isUnlimitPurchased
    }
    
    func isBannerDisabled() -> Bool
    {
        return isUltimatePurchased || isAdblockPurchased
    }
    
    // 購入
    func purchaseUnlimitFromAppStore(onSuccess: @escaping () -> Void) {
        purchaseFromAppStore(product: "unlimit", onSuccess: {
            AppStoreClass.shared.isUnlimitPurchased = true
            UserDefaults.standard.set(true, forKey: AppConstants.UNLIMIT_PURCHASE_FLAG_KEY)
            onSuccess()
        })
    }
    
    func purchaseUltimateFromAppStore(onSuccess: @escaping () -> Void) {
        purchaseFromAppStore(product: "ultimate", onSuccess: {
            AppStoreClass.shared.isUltimatePurchased = true
            UserDefaults.standard.set(true, forKey: AppConstants.ULTIMATE_PURCHASE_FLAG_KEY)
            onSuccess()
        })
    }
    
    func purchaseAdblockFromAppStore(onSuccess: @escaping () -> Void) {
        purchaseFromAppStore(product: "adblock", onSuccess: {
            AppStoreClass.shared.isAdblockPurchased = true
            UserDefaults.standard.set(true, forKey: AppConstants.ADBLOCK_PURCHASE_FLAG_KEY)
            onSuccess()
        })
    }
    
    func purchaseFromAppStore(product: String, onSuccess: @escaping () -> Void){
        SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
            switch result {
            case .success(let purchase):
                print("Purchase Success: \(purchase.productId)")
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
    func restore(restoreSuccess:@escaping ()->Void, restoreFailed:@escaping ()->Void) {
        SwiftyStoreKit.restorePurchases(atomically: true) { result in
            var isUnlimitPurchased = false
            var isUltimatePurchased = false
            var isAdblockPurchased = false
            for product in result.restoredPurchases {
                if product.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
                if product.productId == "unlimit" {
                    isUnlimitPurchased = true
                }
                else if product.productId == "ultimate" {
                    isUltimatePurchased = true
                }
                else if product.productId == "adblock" {
                    isAdblockPurchased = true
                }
            }
            if(isUnlimitPurchased || isUltimatePurchased || isAdblockPurchased){
                self.isUnlimitPurchased = isUnlimitPurchased
                self.isUltimatePurchased = isUltimatePurchased
                self.isAdblockPurchased = isAdblockPurchased
                self.save()
                restoreSuccess()
            }
            else{
                restoreFailed()
            }
        }
    }
    
    func save(){
        UserDefaults.standard.set(isUnlimitPurchased, forKey: AppConstants.UNLIMIT_PURCHASE_FLAG_KEY)
        UserDefaults.standard.set(isUltimatePurchased, forKey: AppConstants.ULTIMATE_PURCHASE_FLAG_KEY)
        UserDefaults.standard.set(isAdblockPurchased, forKey: AppConstants.ADBLOCK_PURCHASE_FLAG_KEY)
    }
    
    func reload(){
        self.isUnlimitPurchased = UserDefaults.standard.bool(forKey: AppConstants.UNLIMIT_PURCHASE_FLAG_KEY)
        self.isUltimatePurchased = UserDefaults.standard.bool(forKey: AppConstants.ULTIMATE_PURCHASE_FLAG_KEY)
        self.isAdblockPurchased = UserDefaults.standard.bool(forKey: AppConstants.ADBLOCK_PURCHASE_FLAG_KEY)
    }
}
