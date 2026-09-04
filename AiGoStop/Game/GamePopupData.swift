//
//  PopupData.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 6/10/26.
//

import SwiftUI
import Combine

enum GamePopupType {
    case selectCard
    case selectButton
    case autoCloseMessage
    case message
    case winner
    case specialWinner
    case alert
    case none
}

class GamePopupData: ObservableObject {
    static let defaultAutoCloseDuration: Double = 1.5
    
    @Published var type: GamePopupType = .none
    var title: String? = nil
    var message: String? = nil
    var cards: [Card] = []
    var players: [Player] = []
    var playerEmotion: PlayerEmotion = .normal
    var button1Text: String = ""
    var button2Text: String = ""
    var completion: (_ select: Int) -> Void = { select in }
    var autoCloseDuration: Double = 2.0 * (UserDefaults.standard.gameSpeed ?? 1)
    
    init() {
        self.setAutoCloseDuration(gameSpeed: UserDefaults.standard.gameSpeed ?? 0.0)
    }
    
    func setAutoCloseDuration(gameSpeed: Double) {
        self.autoCloseDuration = GamePopupData.defaultAutoCloseDuration + gameSpeed * -1.0
    }
}
