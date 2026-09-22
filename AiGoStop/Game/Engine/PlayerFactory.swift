//
//  PlayerFactory.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 6/15/26.
//

import Foundation

class PlayerFactory {
    
    static let imageNamePrefix = "player_"
    static let playerKeys = [
        "PLAYER_CHOI_MADAM",
        "PLAYER_CHUNGDAM_MISSY",
        "PLAYER_IRENE",
        "PLAYER_KIM_TEACHER",
        "PLAYER_ENGLISH_TEACHER",
        "PLAYER_KIM_DIRECTOR",
        "PLAYER_ERIC",
        "PLAYER_PROFESSOR_HWANG",
        "PLAYER_DIRECTOR_JUNG",
        "PLAYER_VEGAS",
        "PLAYER_HOONNAIL",
        "PLAYER_DORYUNG_JUNG",
        "PLAYER_STEVEN",
        "PLAYER_HYEMI",
        "PLAYER_GAMBLE_KING",
        "PLAYER_DOSA_LEE",
        "PLAYER_DR_JUNG",
        "PLAYER_ISHIMURA",
        "PLAYER_ERIC_KIM",
        "PLAYER_WANG_WEI",
        "PLAYER_BRUCE"
    ]
    
    /// 현재 설정된 언어에 맞게 번역된 플레이어 이름 배열을 반환합니다.
    static var localizedPlayerNames: [String] {
        return playerKeys.map { key in
            // iOS 15 이상에서 지원하는 현대적인 다국어 문자열 로드 방식
            String(localized: String.LocalizationValue(key))
        }
    }
    
    
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
            player.name = PlayerFactory.localizedPlayerNames[random[i]]
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
        player.name = PlayerFactory.localizedPlayerNames[random[0]]
        player.imageName = PlayerFactory.imageNamePrefix + String(format: "%02d", random[0])
        
        return player
    }
}
