//
//  GameScene+Layout.swift
//  AiTest
//
//  레이아웃 · 테이블 상태 · 배경
//

import SpriteKit
import SwiftUI

extension GameScene {
    
    // 존재하는 테이블 그룹 찾기 (없으면 nil)
    func getTableCardGroupIndex(cardMonth: Int) -> Int? {
        for (i, tableCardGroup) in self.gameData.tableCardGroups.enumerated() {
            if let card  = tableCardGroup.first {
                if card.month == cardMonth {
                    return i
                }
            }
        }
        return nil
    }
    
    // 비어있는 테이블 그룹 반환 (getTableCardGroupIndex이 없으면 )
    func getEmptyTableCardGroupIndex(cardMonth: Int) -> Int {
        for (i, tableCardGroup) in self.gameData.tableCardGroups.enumerated() {
            if tableCardGroup.isEmpty {
                return i
            }
        }
        return 0
    }
    
    func getMatchingTableCards(cardMonth: Int) -> [Card] {
        var cards: [Card] = []
        for tableCardGroup in self.gameData.tableCardGroups {
            // 첫번째 카드로만 같은 그룹인지 확인 후 보너스카드까지 가져가야 함
            if tableCardGroup.first?.month == cardMonth {
                for card in tableCardGroup {
                    cards.append(card)
                }
            }
        }
        return cards
    }
    
    func removeTableCard(card: Card) {
        for i in 0..<self.gameData.tableCardGroups.count {
            self.gameData.tableCardGroups[i].removeAll { $0.id == card.id }
        }
    }
    
    func setDeckCardNodes(deckCards: [Card]) {
        let startX = round(size.width / 2)
        let startY = round(size.height / 2) - cardGap * 5
        
        for i in 0 ..< deckCards.count {
            let node = CardNode(name: deckCards[i].id.uuidString, card: deckCards[i], cardSize: self.normalCardSize, isFront: false)
            node.position = CGPoint(x: startX + CGFloat(i), y: startY - CGFloat(i))
            node.zPosition = self.deckZPosition + CGFloat(i)
            self.addChild(node)
            
            let scaleAction = SKAction.scale(to: CardNodeScale.large.rawValue, duration: 0)
            node.run(scaleAction)
        }
    }
    
    func getTableCardPosition(groupIndex: Int, cardIndexByGroup: Int) -> CGPoint {
        print("\(#function): \(groupIndex), \(cardIndexByGroup)")
        let startX = round(size.width / 2)
        let startY = round(size.height / 2) - cardGap * 5
        
        let cardWidthWithGap = self.normalCardSize.width * CardNodeScale.large.rawValue + self.cardGap
        let sp = CGFloat(cardIndexByGroup) * self.cardLayeredGap * CardNodeScale.large.rawValue
        if groupIndex % 2 == 0 {
            return CGPoint(x:startX - cardWidthWithGap / 2 - cardWidthWithGap * CGFloat(groupIndex / 2 + 1) + sp, y: startY - sp)
        }
        else {
            return CGPoint(x:startX + cardWidthWithGap / 2 + cardWidthWithGap * round(CGFloat(groupIndex / 2 + 1)) + sp, y: startY - sp)
        }
    }
    
    func getPlayerHandCardPosition(playerIndex: Int, cardIndex: Int) -> CGPoint {
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점
        var cardWidth: CGFloat = 0
        
        if playerIndex == 0 {
            cardWidth = self.normalCardSize.width * CardNodeScale.large.rawValue
            startPosition.x = self.size.width / 2 + (cardWidth / 2)
            startPosition.y = self.normalCardSize.height * CardNodeScale.large.rawValue / 2 + self.cardGap
        }
        else if let playerMoneyNode = self.childNode(withName: CapsuledLabelNode.prefixPlayerMoney + "\(playerIndex)") as? SKLabelNode {
            cardWidth = self.normalCardSize.width * CardNodeScale.small.rawValue
            startPosition.x = playerMoneyNode.position.x + (playerMoneyNode.bounds.size.width / 2) + cardWidth + 5
            startPosition.y = self.size.height - (self.normalCardSize.height * CardNodeScale.small.rawValue / 2) - 7
        }
        else {
            print("\(#function) empty childNode: \(CapsuledLabelNode.prefixPlayerMoney)\(playerIndex)")
        }
        
        var position: CGPoint = .zero
        position.x = startPosition.x + CGFloat(cardIndex) * (cardWidth + self.cardGap)
        position.y = startPosition.y
        return position
    }
    
    func getPlayerCapturedCardPosition(playerIndex: Int, cardIndexByType: Int, cardType: CardType) -> CGPoint {
        print("\(#function) cardIndexByType: \(cardIndexByType), cardType: \(cardType)")
        let playerNameNodeHeight = self.childNode(withName: CapsuledLabelNode.prefixPlayerName + "0")?.frame.height ?? self.playerIconDiameter / 2
        let cardHeightWithGap = self.normalCardSize.height + self.cardGap
        var startPosition: CGPoint = .zero // 좌측 하단이 시작점
        startPosition.x = (playerIndex == 1 ? self.size.width / 2 : 0.0) + self.normalCardSize.height + (self.cardGap * 2)
        startPosition.y = playerIndex == 0 ? self.cardGap : self.size.height - playerNameNodeHeight - cardHeightWithGap * 3 - self.cardGap * 3
        var position: CGPoint = .zero
        position.x = startPosition.x  + (self.normalCardSize.width / 2) + (self.normalCardSize.width / 2.5) * CGFloat(cardIndexByType) + ( cardType == .tti ? self.size.width / 5 : 0)
        position.y = startPosition.y + (self.normalCardSize.height / 2) + cardHeightWithGap * (cardType == .gwang ? 2.0 : cardType == .pi ? 0.0 : 1.0)
        return position
    }
    
    func setBackgroundNodes() {
        let startY = round(size.height / 2) - cardGap * 5
        
        let deckAreaNode = SKShapeNode(rect: CGRect(x: 0, y: startY - self.normalCardSize.height , width: self.size.width, height: self.normalCardSize.height * 2))
        deckAreaNode.fillColor = .black.withAlphaComponent(0.7)
        deckAreaNode.strokeColor = .clear
        self.addChild(deckAreaNode)
        
        for playerIndex in 0...2 {
            let playerAreaNode = SKShapeNode(circleOfRadius: playerIndex == 0 ? self.size.width : self.size.width / 2 )
            
            switch playerIndex {
            case 1:
                playerAreaNode.position.x = 0
                playerAreaNode.position.y = self.size.height * 4 / 3
            case 2:
                playerAreaNode.position.x = self.size.width
                playerAreaNode.position.y = self.size.height * 4 / 3
            default: // user
                playerAreaNode.position.x = self.size.width / 2
                playerAreaNode.position.y = -self.size.height * 1.5
            }
            
            playerAreaNode.fillColor = .white.withAlphaComponent(0.2)
            playerAreaNode.strokeColor = .clear
            playerAreaNode.zPosition = -100
            addChild(playerAreaNode)
        }
    }
}
