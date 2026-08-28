//
//  GameScene+PlayerUI.swift
//  AiGoStop
//
//  플레이어 HUD · 점수 표시
//

import SpriteKit
import SwiftUI

extension GameScene {
    
    func updateAllPlayerNodesAndStatus(isClear: Bool) {
        for i in 0...2 {
            if isClear { self.clearPlayerGameStatus(i) }
            self.setPlayerNodes(player: self.gameData.players[i], isBlink: i == self.gameData.currentPlayerIndex)
        }
    }
    
    func setPlayerNodes(player: Player, isBlink: Bool) {
        var startPosition: CGPoint = .zero
        let playerIconNodeSize = CGSize(width: self.playerIconDiameter * (isBlink ? 1.5 : 1),  height: self.playerIconDiameter * (isBlink ? 1.5 : 1))
        let playerIconNode = PlayerIconNode(player: player, size: playerIconNodeSize, isBlink: isBlink)
        let playerNameNode = CapsuledLabelNode(playerIndex: player.index, playerName: player.name)
        let playerCoinNode = CapsuledLabelNode(playerIndex: player.index, coin: player.coin)
        // remove old node
        if let oldOne = self.childNode(withName: PlayerIconNode.prefixName + "\(player.index)") { oldOne.removeFromParent() }
        if let oldOne = self.childNode(withName: CapsuledLabelNode.prefixPlayerName + "\(player.index)") { oldOne.removeFromParent() }
        if let oldOne = self.childNode(withName: CapsuledLabelNode.prefixPlayerWinningCount + "\(player.index)") { oldOne.removeFromParent() }
        if let oldOne = self.childNode(withName: CapsuledLabelNode.prefixPlayerCoin + "\(player.index)") { oldOne.removeFromParent() }
        
        switch player.index {
        case 1:
            startPosition.x = (self.size.width / 2) + self.cardGap
            startPosition.y = self.size.height - self.cardGap
        case 2:
            startPosition.x = self.cardGap
            startPosition.y = self.size.height - self.cardGap
        default: // user
            startPosition.x = (self.size.width / 2) + self.cardGap
            // 카드 위
            startPosition.y = self.normalCardSize.height * CardNodeScale.large.rawValue + self.cardGap + self.cardGap
        }
        
        if player.index == 0 {
            playerIconNode.position.x = startPosition.x + (self.playerIconDiameter * (isBlink ? 1.5 : 1) / 2)
            playerIconNode.position.y = startPosition.y + (self.playerIconDiameter * (isBlink ? 1.5 : 1) / 2)
            playerNameNode.position.x = startPosition.x + self.playerIconDiameter + playerNameNode.bounds.width / 2 + 10
            playerNameNode.position.y = startPosition.y + self.playerIconDiameter / 4
        }
        else {
            playerIconNode.position.x = startPosition.x + (self.playerIconDiameter * (isBlink ? 1.5 : 1) / 2)
            playerIconNode.position.y = startPosition.y - (self.playerIconDiameter * (isBlink ? 1.5 : 1) / 2)
            playerNameNode.position.x = startPosition.x + self.normalCardSize.height + playerNameNode.bounds.width / 2 + 10
            playerNameNode.position.y = startPosition.y - self.normalCardSize.height / 2
        }
        
        playerCoinNode.position.y = playerNameNode.position.y
        playerCoinNode.position.x = playerNameNode.position.x + playerNameNode.frame.width / 2 + playerCoinNode.frame.width / 2 + 20
        
        if let winnerHistory = UserDefaults.standard.winnerHistory, winnerHistory.last == player.index {
            let winningCount = winnerHistory.reversed().prefix(while: { $0 == player.index }).count
            let playerWinningCountNode = CapsuledLabelNode(playerIndex: player.index, winningCount: winningCount)
            playerWinningCountNode.position.y = playerNameNode.position.y
            playerWinningCountNode.position.x = playerNameNode.position.x + playerNameNode.frame.width / 2 + playerWinningCountNode.frame.width / 2 + 20
            self.addChild(playerWinningCountNode)
            // moeny 위치 변경
            playerCoinNode.position.x = playerWinningCountNode.position.x + playerWinningCountNode.frame.width / 2 + playerCoinNode.frame.width / 2 + 20
        }
        
        self.addChild(playerIconNode)
        self.addChild(playerNameNode)
        self.addChild(playerCoinNode)
    }
    
    func updatePlayersCoinNodes(players: [Player]) {
        for player in players {
            if let oldOne = self.childNode(withName: CapsuledLabelNode.prefixPlayerCoin + "\(player.index)") {
                let playerCoinNode = CapsuledLabelNode(playerIndex: player.index, coin: player.coin)
                playerCoinNode.position = oldOne.position
                oldOne.removeFromParent()
                self.addChild(playerCoinNode)
            }
        }
    }
    
    func setPlayerScoreNodes(playerIndex: Int) {
        let player = self.gameData.players[playerIndex]
        
        for i in 0..<player.capturedCardTypeGroups.count {
            if let node = self.childNode(withName: CapsuledLabelNode.prefixPlayerCapturedGroup + "\(player.index)_\(i)") {
                self.removeChildren(in: [node])
            }
            
            let cardIndexByType = player.capturedCardTypeGroups[i].count
            if cardIndexByType == 0 { continue }
            var position = self.getPlayerCapturedCardPosition(playerIndex: player.index, cardIndexByType: cardIndexByType, cardType: CardType(rawValue: i) ?? .gwang)
            var score = 0
            switch i {
            case 0: score = player.gwangCount
            case 1: score = player.yeolCount
            case 2: score = player.ttiCount
            case 3: score = player.piCount
            default: break
            }
            let capturedCountNode = CapsuledLabelNode(playerIndex: player.index, groupIndex: i, score: score)
            position.x += capturedCountNode.frame.width
            position.y -= capturedCountNode.frame.height + 3
            capturedCountNode.position = position
            self.addChild(capturedCountNode)
        }
    }
}
