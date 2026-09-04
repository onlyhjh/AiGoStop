//
//  PlayerFactory.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 6/15/26.
//

import Foundation

class PlayerFactory {
    
    static let imageNamePrefix = "player_"
    static let playerNames = ["최마담", "청담미씨", "아이린", "김선생", "영어쌤", "김원장", "에릭", "황교수", "정실장", "베거스", "훈나일", "정도령", "스티븐", "혜미", "겜블킹", "이도사", "정박사", "이시무라", "에릭킴", "왕웨이", "브루스"]
    
    func loadLocalPlayerData(playerIndex: Int) -> Player? {
        var playerData: Data?
        switch playerIndex {
        case 1: playerData = UserDefaults.standard.player1
        case 2: playerData = UserDefaults.standard.player2
        default : playerData = UserDefaults.standard.user
        }
        
        if let playerData, let player = try? JSONDecoder().decode(Player.self, from: playerData) {
            return player
        }
        
        return nil
    }
    
    func getRandomPlayers() -> [Player] {
        let random = (0...20).shuffled()
        var players: [Player] = []
        
        for i in 0...2 {
            var player = Player(index: i)
            player.characterIndex = random[i]
            player.name = PlayerFactory.playerNames[random[i]]
            player.imageName = PlayerFactory.imageNamePrefix + String(format: "%02d", random[i])
            players.append(player)
        }
        return players
    }
    
    func getRandomPlayer(playerIndex: Int, without: [Int]) -> Player {
        let withoutNumbers = (Set(without) as Set).symmetricDifference(1...20)
        let random = (withoutNumbers).shuffled()

        var player = Player(index: playerIndex)
        player.characterIndex = random[0]
        player.name = PlayerFactory.playerNames[random[0]]
        player.imageName = PlayerFactory.imageNamePrefix + String(format: "%02d", random[0])
        
        return player
    }
}
