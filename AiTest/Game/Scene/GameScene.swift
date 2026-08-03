//
//  GameScene.swift
//  AiGoStop Shared
//
//  Created by Joey's Mac mini on 4/29/26.
//

import SpriteKit
import SwiftUI
import Combine


class GameScene: SKScene, ObservableObject {
    
    @Binding var isPresentedCharacterSettingPopup: Bool
    var gameData: GameData
    var popupData: PopupData
    var isUserTouchCardEnabled = false
    
    let aiManager = AIEngineManager()
    let emptyCardMonth: Int = 100 // 폭탄 후 빈 카드
    // zPosition > tableCard = 10 ~ 140  deckCard = 1000~카드쌓기, 움직이는카드 10000 > 정지 후 0
    let deckZPosition: CGFloat = 1000
    var normalCardSize: CGSize = .zero
    var playerIconDiameter : CGFloat { normalCardSize.height }
    var cardGap: CGFloat = 0
    var cardLayeredGap: CGFloat = 0
    
    init(size: CGSize, gameData: GameData, popupData: PopupData, isPresentedCharacterSettingPopup: Binding<Bool>) {
        _isPresentedCharacterSettingPopup = isPresentedCharacterSettingPopup
        self.gameData = gameData
        self.popupData = popupData
        super.init(size: size)
        
        self.backgroundColor = .tableBG ?? .green
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        DispatchQueue.main.async {
            self.normalCardSize = CGSize(width: self.size.height / 14, height: self.size.height / 14 * 1.5)
            self.cardGap = self.normalCardSize.width / 10
            self.cardLayeredGap = self.normalCardSize.width / 5
        }
    }
    
    // 매 프레임마다 SwiftUI로부터 온 데이터를 감지하고 적용
    override func update(_ currentTime: TimeInterval) {
        switch self.gameData.gameStatus {
        case .start:
            self.replacePlayerIfNeeded(isShowPopup: false) {
                self.startGame()
            }
        case .restart:
            self.replacePlayerIfNeeded(isShowPopup: false) {
                self.startGame(savedDeckCards: self.gameData.origianalDeckCards, winnerIndex: self.gameData.winnerIndex)
            }
        case .updatePlayers:
            self.updateAllPlayerNodesAndStatus(isClear: false)
        default:
            break
        }
        self.gameData.gameStatus = .wait
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let loc = touches.first!.location(in: self)
        
        for n in nodes(at: loc) {
            if let cardNode = n as? CardNode, self.isUserTouchCardEnabled {
                if self.gameData.currentPlayerIndex == 0, let handCard = self.gameData.players[self.gameData.currentPlayerIndex].handCards.first(where: { $0.id == cardNode.card.id }) {
                    self.playWithSelectedHandCard(handCard: handCard)
                    self.isUserTouchCardEnabled = false
                }
            }
            else if let playerIconNode = n as? PlayerIconNode {
                SoundManager.shared.playSoundIfPossible(type: .click)
                if playerIconNode.name == PlayerIconNode.prefixName + "0" {
                    self.isPresentedCharacterSettingPopup = true
                }
            }
        }
    }
}
