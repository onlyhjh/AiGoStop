//
//  ScoreEngine.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 6/25/26.
//
import Foundation

enum WinningType {
    case regularWin
    case thirdFuckWin
    case chongtongWin
}

class ScoreEngine {
    func getPlayersFinalScore(type: WinningType, winnerIndex: Int, gameData: GameData, wasNagari: Bool, goBakPlayerIndex: Int?) -> [Player] {
        var winner = gameData.players[winnerIndex]
        var loser1 = gameData.players[(winnerIndex + 1) % 3]
        var loser2 = gameData.players[(winnerIndex + 2) % 3]
        
        switch type {
        case .chongtongWin:
            loser1.finalScore = -10
            loser2.finalScore = -10
        case .thirdFuckWin:
            loser1.finalScore = -3
            loser2.finalScore = -3
        default: // 일반 승리
            if winner.gwangScore > 0 {
                loser1.isGwangBak = loser1.gwangCount == 0
                loser2.isGwangBak = loser2.gwangCount == 0
            }
            
            if winner.piScore > 0 {
                loser1.isPiBak = loser1.piCount > 0 && loser1.piCount < 6
                loser2.isPiBak = loser2.piCount > 0 && loser2.piCount < 6
            }
        
            // 아무것도 못먹은 경우 0
            // 승자점수에 광박, 피박 적용
            loser1.finalScore = loser1.allCount == 0 ? 0 : -winner.subtotalScore * (loser1.isGwangBak ? 2 :1) * (loser1.isPiBak ? 2 : 1)
            loser2.finalScore = loser2.allCount == 0 ? 0 : -winner.subtotalScore * (loser2.isGwangBak ? 2 :1) * (loser2.isPiBak ? 2 : 1)
        }

        // 독박 확인
        if let goBakPlayerIndex {
            if goBakPlayerIndex == loser1.index {
                loser1.isGoBak = true
                loser1.finalScore += loser2.finalScore
                loser2.finalScore = 0
            }
            else if goBakPlayerIndex == loser2.index {
                loser2.isGoBak = true
                loser2.finalScore += loser1.finalScore
                loser1.finalScore = 0
            }
        }
        
        // 이전판 나가리 두배
        winner.wasNagari = wasNagari
        if wasNagari {
            loser1.finalScore *= 2
            loser2.finalScore *= 2
        }
        
        winner.finalScore = -(loser1.finalScore + loser2.finalScore)
        
        // 승률, 기대수익 임시 저장 (save할때)
        winner.updateStatisticsData(isWin: true, profit: winner.finalScore)
        loser1.updateStatisticsData(isWin: false, profit: loser1.finalScore)
        loser2.updateStatisticsData(isWin: false, profit: loser2.finalScore)
        
        // money 임시 저장 (save할때)
        winner.money += winner.finalScore
        loser1.money += loser1.finalScore
        loser2.money += loser2.finalScore
        
        return [winner, loser1, loser2]
    }
}
