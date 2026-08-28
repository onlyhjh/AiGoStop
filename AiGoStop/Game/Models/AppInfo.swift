//
//  AppInfo.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 8/6/26.
//

import Foundation

struct AppInfo: Codable {
    let appstoreUrl: String?
    let currentVersion: String?
    let minVersion: String?
    let noticeUrl: String?
    let maintananceText: String?
    let policyUrl: String?
    let licenseUrl: String?
    let contact: String?
    
    var isForcedUpdate: Bool {
        if let minVersion, let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if minVersion.compare(appVersion, options: .numeric) == .orderedDescending {
                return true
            }
        }
        return false
    }
    
    var isOptionalUpdate: Bool {
        if let currentVersion, let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if currentVersion.compare(appVersion, options: .numeric) == .orderedDescending {
                return true
            }
        }
        return false
    }
}
