//
//  AiGoStopApp.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 5/20/26.
//

import SwiftUI
import SwiftData
import GoogleMobileAds
import AppTrackingTransparency

@main
struct AiGoStopApp: App {

    init() {
        MobileAds.shared.start()
        _ = AdManager.shared   // 여기서 초기 생성 및 광고 로딩 시작
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
          ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    ATTrackingManager.requestTrackingAuthorization(completionHandler: { _ in })
                }
        }
    }
}
