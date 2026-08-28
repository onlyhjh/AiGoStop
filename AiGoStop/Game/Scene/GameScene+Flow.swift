//
//  GameScene+Flow.swift
//  AiGoStop
//
//  게임 흐름 · 라운드 · 저장
//

import SpriteKit
import SwiftUI

extension GameScene {
    
    func startGame(savedDeckCards: [Card]? = nil, winnerIndex: Int? = nil) {
        let newDeckCards = savedDeckCards ?? DeckFactory().generateFullDeck()
        self.gameData.resetGameData(newDeckCards : newDeckCards, winnerIndex: winnerIndex)
        self.removeAllChildren()
        self.setBackgroundNodes()
        self.setDeckCardNodes(deckCards: newDeckCards)
        self.updateAllPlayerNodesAndStatus(isClear: true)
        
        Task {
            // Test : player captured영역 확인을 위해 전체 카드 주기 */
            //            for _ in 0..<self.gameData.deckCards.count - 1 {
            //                await self.moveDeckCardToPlayerCaptured(playerIndex: 2)
            //            }
            //            return
            
            // Test Deck카드 테이블로
            //            for _ in 0..<self.gameData.deckCards.count - 1 {
            //                await self.moveDeckCardToTable()
            //            }
            //            return
            
            // Test 특정카드 사용자에게
            //            for (i, card) in self.gameData.deckCards.enumerated().reversed() {
            //                var cards: [Card] = []
            //                if card.month == 1  {
            //                    let element = self.gameData.deckCards.remove(at: i)
            //                    if card.type == .gwang {
            //                        self.gameData.deckCards.append(element)
            //                    }
            //                    else {
            //                        cards.append(element)
            //                    }
            //                }
            //                self.gameData.deckCards.insert(contentsOf: cards, at: self.gameData.deckCards.count - 11)
            //            }
            //            for (i, card) in self.gameData.deckCards.enumerated().reversed() {
            //                if card.type == .yeol && card.month > 5 && card.piNum == 0 {
            //                    let element = self.gameData.deckCards.remove(at: i)
            //                    self.gameData.deckCards.insert(element, at: 26)
            //                    break
            //                }
            //            }
            
            
            // 테이블에 첫번째 3장 나눠주기
            await self.moveDeckCardsToTable(count: 3, soundType: nil)
            
            // 각 플레이어에게 첫번째 4장 나눠주기
            for i in 0...2 {
                let nextPlayerIndex = (self.gameData.winnerIndex + 1 + i) % 3
                await self.moveDeckCardToPlayerHand(playerIndex: nextPlayerIndex, count: 4)
            }
            
            // 테이블에 두번째 3장 나눠주기
            await self.moveDeckCardsToTable(count: 3, soundType: nil)
            
            // 각 플레이어에게 두번째 3장 나눠주기
            for i in 0...2 {
                let nextPlayerIndex = (self.gameData.winnerIndex + 1 + i) % 3
                await self.moveDeckCardToPlayerHand(playerIndex: nextPlayerIndex, count: 3)
                self.sortPlayerHandCards(playerIndex: nextPlayerIndex)
            }
            
            // 보너스 카드 지급 후 덱카드 테이블에 지급 (재귀반복)
            await self.moveBonusTableCardToPlayerCapturedAndMoveDeckCardToTableAgain(playerIndex: self.gameData.winnerIndex)
            // 총통 검사 1 (10점)
            if !self.checkChongTong() {
                // 테스트 한장씩 뺏어오기 테스트용
                //            for i in 0...8 {
                //                await self.moveDeckCardToPlayerCaptured(playerIndex: i % 3)
                //            }
                self.doPlay()
            }
        }
    }
    
    func doPlay() {
        print("\(#function) playerIndex:\(self.gameData.currentPlayerIndex)")
        
        //  이전 플레이어도 정리해 줘야 함
        for i in 0...2 {
            self.sortPlayerHandCards(playerIndex: i)
            self.setPlayerNodes(player: self.gameData.players[i], isBlink: i == self.gameData.currentPlayerIndex)
        }
        
        Task {
            do { try await Task.sleep(for: .seconds(1.0))
            } catch { print("error: \(error)")}
            
            
            switch self.gameData.currentPlayerIndex {
            case 0:
                self.isUserTouchCardEnabled = true
                // 보너스카드 뒤 뻑카드 테스트용
                if self.gameData.deckCards.count > 2 {
                    print("???? next Deck Cards: \(self.gameData.deckCards[self.gameData.deckCards.count - 1].month) > \(self.gameData.deckCards[self.gameData.deckCards.count - 2].month)")
                }
            case 1, 2:
                let playerIndex = self.gameData.currentPlayerIndex
                let handCards = self.gameData.players[playerIndex].handCards
                guard !handCards.isEmpty else { return }
                let card = self.aiManager.selectHandCard(gameData: self.gameData, playerIndex: playerIndex)
                self.playWithSelectedHandCard(handCard: card)
            default: break
            }
        }
    }
    
    func clearPlayerGameStatus(_ i: Int) {
        self.gameData.players[i].capturedCardTypeGroups = [[],[],[],[]]
        self.gameData.players[i].handCards = []
        self.gameData.players[i].goCount = 0
        self.gameData.players[i].lastGoScore = 0
        self.gameData.players[i].fuckCardMonths = []
        self.gameData.players[i].waveCount = 0
        
        // winner
        self.gameData.players[i].isChongTongWin = false
        self.gameData.players[i].is3FuckWin = false
        self.gameData.players[i].isGokbak = false
        self.gameData.players[i].wasNagari = false
        // looser
        self.gameData.players[i].isPiBak = false
        self.gameData.players[i].isGwangBak = false
        self.gameData.players[i].isGoBak = false // 독박과 동일
        self.gameData.players[i].finalScore = 0
    }
    
    func stopPlayerGame(winnderIndex: Int) {
        let goBakPlayerIndex = self.getGoBakPlayerIndex(winnerIndex: self.gameData.currentPlayerIndex)
        let players = ScoreEngine().getPlayersFinalScore(type: .regularWin ,winnerIndex: self.gameData.currentPlayerIndex, gameData: self.gameData, wasNagari: UserDefaults.standard.wasNagari ?? false, goBakPlayerIndex: goBakPlayerIndex)
        self.gameData.winnerIndex = self.gameData.currentPlayerIndex
        self.saveGameData(winnerIndex: winnderIndex, players: players, isNagari: false)
        self.setPlayerNodes(player: players[0], isBlink: false)
        SoundManager.shared.playSoundIfPossible(type: .win)
        GamePopupManager.shared.showPopup(popupData: self.popupData, type: .winner, cards: [], players: players, completion: { _ in
            self.movePlayerPayouts(players: players) {
                self.updatePlayersCoinNodes(players: players)
                self.replacePlayerIfNeeded(isShowPopup: true) {
                    AdManager.shared.showAd(completion: {self.startGame()})
                }
            }
        })
    }
    
    func replacePlayerIfNeeded(isShowPopup: Bool, completion: @escaping () -> Void) {
        for i in 0 ... 2 {
            if self.gameData.players[i].coin <= 0 {
                let oldPlayer = self.gameData.players[i]
                let without = [self.gameData.players[0].characterIndex, self.gameData.players[1].characterIndex, self.gameData.players[2].characterIndex]
                let newPlayer = PlayerFactory().getRandomPlayer(playerIndex: i, without: without)
                self.gameData.players[i].characterIndex = newPlayer.characterIndex
                self.gameData.players[i].name = newPlayer.name
                self.gameData.players[i].imageName = newPlayer.imageName
                self.gameData.players[i].coin = Player.defaultCoin
                self.savePlayer(index: i)
                
                print("\(#function) isShowPopup:\(isShowPopup), old player:\(oldPlayer.name) >>> new player: \(newPlayer.name)")
                
                if isShowPopup {
                    SoundManager.shared.playSoundIfPossible(type: .bustedPlayer)
                    GamePopupManager.shared.showPopup(popupData: self.popupData, type: .bustedPlayer, cards: [], players: [oldPlayer]) { _ in
                        SoundManager.shared.playSoundIfPossible(type: .newPlayerJoins)
                        GamePopupManager.shared.showPopup(popupData: self.popupData, type: .newPlayerJoins, cards: [], players: [newPlayer]) { _ in
                            self.replacePlayerIfNeeded(isShowPopup: isShowPopup, completion: completion)
                        }
                    }
                }
                else {
                    self.replacePlayerIfNeeded(isShowPopup: isShowPopup, completion: completion)
                }
                return
            }
        }
        completion()
    }
    
    func checkScoreAndDoNextPlay() {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        print("\(#function) player:\(player.index), baseScore: \(player.baseScore), lastGoScore: \(player.lastGoScore)")
        // 3점 이상이고 이전에 고한 점수 보다 높아야 함 (고1점  -1 제외)
        if player.baseScore > 2 && player.baseScore - 1 > player.lastGoScore {
            // 막장이었으면 고/스톱 선택없이 바로 결과 출력
            if player.handCards.isEmpty {
                self.stopPlayerGame(winnderIndex: player.index)
            }
            // User
            else if player.index == 0 {
                GamePopupManager.shared.showPopup(popupData: self.popupData, type: .selectGoOrStop, cards: [], players: [player]) { select in
                    self.afterSelectGoOrStop(isGo: select == 0, player: player)
                }
            }
            // Ai
            else {
                let isGo = self.aiManager.selectGoOrStop(
                    gameData: self.gameData,
                    playerIndex: player.index
                )
                self.afterSelectGoOrStop(isGo: isGo, player: player)
            }
        }
        // 전체 사용자 막장이었으면 나가리>> 다음판 두배
        else if self.gameData.players[0].handCards.isEmpty && self.gameData.players[1].handCards.isEmpty && self.gameData.players[2].handCards.isEmpty {
            SoundManager.shared.playSoundIfPossible(type: .nagari)
            GamePopupManager.shared.showPopup(popupData: self.popupData, type: .nagari, cards: [], players: []) { _ in
                self.saveGameData(winnerIndex: nil, players: [], isNagari: true)
                self.replacePlayerIfNeeded(isShowPopup: true) {
                    AdManager.shared.showAd(completion: {self.startGame()})
                }
            }
        }
        else {
            self.gameData.currentPlayerIndex = (self.gameData.currentPlayerIndex + 1) % 3
            self.doPlay()
        }
    }
    
    
    func saveGameData(winnerIndex: Int?, players: [Player], isNagari: Bool?) {
        if let winnerIndex {
            // 선/연승 표시용
            var winnerHistory: [Int] = UserDefaults.standard.winnerHistory ?? []
            winnerHistory.append(winnerIndex)
            UserDefaults.standard.winnerHistory = winnerHistory.suffix(100)
            
            // 사용자 최고기록 표시용
            if winnerIndex == 0 {
                var bestRecords: [Int] = UserDefaults.standard.bestRecords ?? []
                bestRecords.append(players[0].finalScore)
                bestRecords = Array(Set(bestRecords)) // remove duplicate elements
                bestRecords.sort(by: >)
                bestRecords = Array(bestRecords.prefix(10))
                UserDefaults.standard.bestRecords = bestRecords
            }
        }
        
        // 나가리 저장할 필요가 있을때만  (뻑등은 게임중이니 나가리저장 안함)
        if let isNagari {
            UserDefaults.standard.wasNagari = isNagari
        }
        
        // 나가리인경우 플레이어 없음
        if players.count > 2 {
            self.gameData.players[players[0].index].coin += players[0].finalScore
            self.gameData.players[players[1].index].coin += players[1].finalScore
            self.gameData.players[players[2].index].coin += players[2].finalScore
            
            // 승률, 기대수익 저장
            self.gameData.players[players[0].index].updateStatisticsData(isWin: true, profit: players[0].finalScore)
            self.gameData.players[players[1].index].updateStatisticsData(isWin: false, profit: players[1].finalScore)
            self.gameData.players[players[2].index].updateStatisticsData(isWin: false, profit: players[2].finalScore)
            
            self.savePlayer(index: 0)
            self.savePlayer(index: 1)
            self.savePlayer(index: 2)
        }
    }
    
    func savePlayer(index: Int) {
        guard let encodedData = try? JSONEncoder().encode(self.gameData.players[index]) else { return }
        
        switch index {
        case 0: UserDefaults.standard.user = encodedData
        case 1: UserDefaults.standard.player1 = encodedData
        case 2: UserDefaults.standard.player2 = encodedData
        default : break
        }
    }
    
    // 총통 검사 2 (10점)
    func checkChongTong() -> Bool  {
        for (i, player) in self.gameData.players.enumerated() {
            for handCard in player.handCards {
                let sameMonthCards = player.handCards.filter({$0.month == handCard.month})
                
                if player.handCards.count == 7 && sameMonthCards.count == 4 {
                    let players = ScoreEngine().getPlayersFinalScore(type: .chongtongWin ,winnerIndex: i, gameData: self.gameData, wasNagari: UserDefaults.standard.wasNagari ?? false, goBakPlayerIndex: nil)
                    self.gameData.winnerIndex = self.gameData.currentPlayerIndex
                    self.saveGameData(winnerIndex: player.index, players: players, isNagari: false)
                    SoundManager.shared.playSoundIfPossible(type: .win)
                    GamePopupManager.shared.showPopup(popupData: self.popupData, type: .chongtongWin, cards: sameMonthCards, players: players, completion: { _ in
                        self.movePlayerPayouts(players: players) {
                            self.updatePlayersCoinNodes(players: players)
                            self.replacePlayerIfNeeded(isShowPopup: true) {
                                AdManager.shared.showAd(completion: {self.startGame()})
                            }
                        }
                    })
                    return true
                }
            }
        }
        // 바닥패 4장인 경우 무효 (뻑 with 보너스카드 제외)
        for groupCards in self.gameData.tableCardGroups {
            let count = groupCards.count{ $0.month != 0 }
            if count == 4 {
                SoundManager.shared.playSoundIfPossible(type: .nagari)
                GamePopupManager.shared.showPopup(popupData: self.popupData, type: .fourTableCards, cards: [], players: [], completion: { _ in
                    self.replacePlayerIfNeeded(isShowPopup: true) {
                        AdManager.shared.showAd(completion: {self.startGame()})
                    }
                })
            }
        }
        return false
    }
}
