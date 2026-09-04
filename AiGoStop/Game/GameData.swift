//
//  GameData.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 5/21/26.
//

import SwiftUI
import Combine

enum GameStatus {
    case start
    case restart
    case next
    case wait
    case updatePlayers
}

class GameData: ObservableObject {
    static let defaultCardDuration: Double = 0.3
    
    @Published var gameStatus: GameStatus = .wait
    var origianalDeckCards: [Card] = []  // 최초 저장용
    var deckCards: [Card] = []
    var tableCardGroups: [[Card]] = []
    var cardDuration: Double = 0
    var winnerIndex = 0
    var players: [Player] = [Player(index: 0), Player(index: 1), Player(index: 2)]
    var currentPlayerIndex = 0
    var goHistory: [Int] = []
    var allTableCards: [Card] {
        tableCardGroups.flatMap { $0 }
    }
    
    init() {
        setCardDuration(gameSpeed: UserDefaults.standard.gameSpeed ?? 0.0)
    }
    
    func resetGameData(newDeckCards: [Card], winnerIndex: Int? = nil) {
        if let winnerIndex {
            self.winnerIndex = winnerIndex
            self.currentPlayerIndex = winnerIndex
        }
        else {
            self.winnerIndex = UserDefaults.standard.winnerHistory?.last ?? 0
            self.currentPlayerIndex = self.winnerIndex
        }
        self.tableCardGroups = [[], [], [], [], [], [], [], [], [], [], [], [], [], []]
        self.goHistory = []
        self.origianalDeckCards = newDeckCards // (최초 사용전 저장용)
        self.deckCards = newDeckCards
    }
    
    func setCardDuration(gameSpeed: Double) {
        cardDuration = GameData.defaultCardDuration + (gameSpeed * -0.2)
    }
}
