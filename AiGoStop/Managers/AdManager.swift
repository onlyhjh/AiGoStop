//
//  Copyright 2022 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

// [START load_ad]
import GoogleMobileAds
import SwiftUI
import Combine
import AdSupport
import AppTrackingTransparency

class AdManager: NSObject, FullScreenContentDelegate, ObservableObject {
    
    static let shared = AdManager()
    
    @Published var interstitialAd: InterstitialAd? = nil
    var completion: (() -> Void)?
    
    override init() {
        super.init()
        
        MobileAds.shared.start { status in
            // 초기화 완료 후 처리할 작업이 있다면 이곳에 작성합니다.
            print("AdMob SDK 초기화 완료 상태: \(status.adapterStatusesByClassName)")
            Task {
                await self.loadAd()
                await PurchaseManager.shared.updatePurchasedProducts()
            }
        }
    }
    
    func showUUID() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                // 허용된 경우 IDFA 추출
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                print("Device advertisingIdentifier UUID (IDFA): \(idfa)")
            case .denied, .restricted, .notDetermined:
                print("Tracking permission not granted.")
            @unknown default:
                break
            }
        }
    }

    // [START load_ad]
    func loadAd() async {
        print("\(#function)")
//        #if DEBUG
//        let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // test Interstitial (전면광고)
//        #else
//        let interstitialAdUnitID = "ca-app-pub-9821824469972292/7914489898" // AiGoStop Interstitial (전면광고)
//        #endif
        
        let interstitialAdUnitID = "ca-app-pub-9821824469972292/7914489898" // AiGoStop Interstitial (전면광고)

        // let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // test Rewarded (리워드 광고)
        // RewardedAd.load(rewardedAdUnitID)
        
        do {
            interstitialAd = try await InterstitialAd.load(
                with: interstitialAdUnitID, request: Request())
            if let interstitialAd =  interstitialAd {
                interstitialAd.fullScreenContentDelegate = self
                print("load interstitial ad success: \(interstitialAd.description)")
                // showAd() 테스트
            }
            else {
                print("load interstitial ad empty!")
            }
        } catch {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
    }
    // [END load_ad]
    
    // [START show_ad]
    @MainActor
    func showAd(completion: (() -> Void)? = nil) {
        self.completion = completion
        
        print("\(#function) called - isAdRemoved: \(PurchaseManager.shared.isAdRemoved)")
        if PurchaseManager.shared.isAdRemoved {
            completion?()
            return
        }
        
        guard let interstitialAd = interstitialAd else {
            completion?()
            print("Ad wasn't ready.")
            return
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            completion?()
            return
        }
        
        interstitialAd.present(from: rootVC)
    }
    // [END show_ad]
    
    // MARK: - GADFullScreenContentDelegate methods
    
    // [START ad_events]
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("\(#function) called")
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
        // Clear the interstitial ad.
        interstitialAd = nil
        self.completion?()
        // 다음광고 로딩
        Task {
            await loadAd()
        }
    }
    // [END ad_events]
}
