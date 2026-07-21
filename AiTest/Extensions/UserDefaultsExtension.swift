//
//  UserDefaultsExtension.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/15/26.
//

import Foundation

enum UserDefaultKey: String, CaseIterable {
    case savedGameDeckCards
    case savedGameWinnerIndex
    case user
    case player1
    case player2
    case winnerHistory
    case wasNagari
    case gameSpeed
    case bestRecords
    case winningCounts // 0, 1, 2, 무승부
    case effectSound
    case backgroundSound
}

extension UserDefaults {
    var savedGameDeckCards: Data? {
        get { data(forKey: UserDefaultKey.savedGameDeckCards.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.savedGameDeckCards.rawValue)}
    }
    
    var savedGameWinnerIndex: Int? {
        get { value(forKey: UserDefaultKey.savedGameWinnerIndex.rawValue) as? Int }
        set { setValue(newValue, forKey: UserDefaultKey.savedGameWinnerIndex.rawValue)}
    }
    
    var user: Data? {
        get { data(forKey: UserDefaultKey.user.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.user.rawValue)}
    }
    
    var player1: Data? {
        get { data(forKey: UserDefaultKey.player1.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.player1.rawValue)}
    }
    
    var player2: Data? {
        get { data(forKey: UserDefaultKey.player2.rawValue) }
        set { setValue(newValue, forKey: UserDefaultKey.player2.rawValue)}
    }
    
    var winnerHistory: [Int]? {
        get { value(forKey: UserDefaultKey.winnerHistory.rawValue) as? [Int]}
        set { setValue(newValue, forKey: UserDefaultKey.winnerHistory.rawValue)}
    }
    
    var wasNagari: Bool? {
        get { value(forKey: UserDefaultKey.wasNagari.rawValue) as? Bool }
        set { setValue(newValue, forKey: UserDefaultKey.wasNagari.rawValue)}
    }
    
    var gameSpeed: Double? {
        get { value(forKey: UserDefaultKey.gameSpeed.rawValue) as? Double }
        set { setValue(newValue, forKey: UserDefaultKey.gameSpeed.rawValue)}
    }
    
    var bestRecords: [Int]? {
        get { value(forKey: UserDefaultKey.bestRecords.rawValue) as? [Int] }
        set { setValue(newValue, forKey: UserDefaultKey.bestRecords.rawValue)}
    }
    
    var backgroundSound: Bool {
        get { value(forKey: UserDefaultKey.backgroundSound.rawValue) as? Bool ?? true }
        set { setValue(newValue, forKey: UserDefaultKey.backgroundSound.rawValue)}
    }
    
    var effectSound: Bool {
        get { value(forKey: UserDefaultKey.effectSound.rawValue) as? Bool ?? true }
        set { setValue(newValue, forKey: UserDefaultKey.effectSound.rawValue)}
    }
}
