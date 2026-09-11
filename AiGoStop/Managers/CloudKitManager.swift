//
//  CloudKitManager.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 8/6/26.
//

import CloudKit
import Foundation


final class CloudKitManager {

    static let shared = CloudKitManager()
    private let container = CKContainer(identifier: "iCloud.com.AiGoStop")
    private var database: CKDatabase { container.publicCloudDatabase }


    private init(){}

    func saveUserData(_ user: Player) async {
        let uuid = DeviceIdentifier.shared.getUUID()
        let recordID = CKRecord.ID(recordName: uuid)

        do {
            let record: CKRecord

            do {
                // 기존 Record가 있는지 확인
                record = try await database.record(for: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                // 없으면 새 Record 생성
                record = CKRecord(
                    recordType: "UserData",
                    recordID: recordID
                )
            }

            record["name"] = user.name
            record["characterIndex"] = user.characterIndex
            record["coin"] = user.coin
            record["imageName"] = user.imageName
            record["updatedAt"] = Date()

            try await database.save(record)
            print("CloudKit save success:", uuid)
        } catch {
            print("CloudKit save error:", error)
        }
    }


    func loadCloudUserData() async -> Player? {
        let uuid = DeviceIdentifier.shared.getUUID()
        let recordID = CKRecord.ID(recordName: uuid)

        do {
            let record: CKRecord

            // 기존 Record가 있는지 확인
            record = try await database.record(for: recordID)
            
            var player = Player(index: 0)
            if let name = record["name"] as? String { player.name = name }
            if let coin = record["coin"] as? Int { player.coin = coin }
            if let characterIndex = record["characterIndex"] as? Int { player.characterIndex = characterIndex }
            if let imageName = record["imageName"] as? String { player.imageName = imageName }
            if let updatedAt = record["updatedAt"] as? Date { player.updatedAt = updatedAt }
            return player
        } catch {
            print("CloudKit loadUserData error or first user:", error)
            return nil
        }
    }
    
    func loadCloudAppData() async -> AppInfo? {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "AppData", predicate: predicate)
        
        do {
            let result = try await database.records(matching: query)
            guard let first = result.matchResults.first, let record = try? first.1.get() else {
                return nil
            }
            
            let appstoreUrl = record["appstoreUrl"] as? String
            let currentVersion = record["currentVersion"] as? String
            let maintananceText = record["maintananceText"] as? String
            let minVersion = record["minVersion"] as? String
            let noticeUrl = record["noticeUrl"] as? String
            let licenseUrl = record["licenseUrl"] as? String
            let policyUrl = record["policyUrl"] as? String
            let contact = record["contact"] as? String
            return AppInfo(appstoreUrl: appstoreUrl, currentVersion: currentVersion, minVersion: minVersion, noticeUrl: noticeUrl, maintananceText: maintananceText, policyUrl: policyUrl, licenseUrl: licenseUrl, contact: contact)
        } catch {
            print("CloudKit loadAppData error:", error)
            return nil
        }
    }
}
