//
//  DeviceIdentifier.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 8/6/26.
//

import Security
import Foundation

final class DeviceIdentifier {

    static let shared = DeviceIdentifier()
    private let key = "deviceUUID"

    private init() {}

    func getUUID() -> String {

        if let existing = read() {
            return existing
        }

        let uuid = UUID().uuidString

        save(uuid)

        return uuid
    }


    private func save(_ value: String) {

        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }


    private func read() -> String? {

        let query: [String: Any] = [

            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrAccount as String:
                key,

            kSecReturnData as String:
                true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]


        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )


        guard status == errSecSuccess,
              let data = result as? Data
        else {
            return nil
        }


        return String(
            data: data,
            encoding: .utf8
        )
    }
}
