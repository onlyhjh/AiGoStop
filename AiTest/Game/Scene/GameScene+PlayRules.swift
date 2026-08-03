//
//  GameScene+PlayRules.swift
//  AiTest
//
//  패 플레이 · 뻑/폭탄/따닥 규칙
//

import SpriteKit
import SwiftUI

extension GameScene {
    
    func playWithSelectedHandCard(handCard: Card) {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        let sameMonthPlayerHandCards = player.handCards.filter({$0.month == handCard.month}) //폭탄, 흔들기
        
        Task {
            // 선택카드가 bonus 카드인경우
            if handCard.month == 0 {
                SoundManager.shared.playSoundIfPossible(type: .handBonus)
                PopupManager.shared.showPopup(popupData: self.popupData, type: .handBonus, cards: [handCard], players: [player], completion: {_ in
                    Task {
                        await self.moveBonusPlayerHandBonusCardToPlayerCaptured(playerIndex: player.index, handCard: handCard)
                        self.sortPlayerHandCards(playerIndex: player.index)
                        // 총통 검사 2 (10점)
                        if !self.checkChongTong() {
                            self.doPlay() // 다시
                        }
                    }
                })
                return
            }
            
            // 다음 덱카드를 미리 확인하여 연속된 보너스 카드 갯수 가져오기
            var nextBonusDeckCardCount = 0
            var nextDeckCardExceptBonus: Card = self.gameData.deckCards.last!
            for card in (self.gameData.deckCards).reversed() {
                if card.month == 0 {
                    nextBonusDeckCardCount += 1
                }
                else {
                    nextDeckCardExceptBonus = card
                    break
                }
            }
            
            // 매칭카드가 갯수에 따른 처리
            let matchingTableCards = self.getMatchingTableCards(cardMonth: handCard.month)
            print("\(#function) handCard: \(handCard.month), \(handCard.type), nextDeckCardExceptBonus: \(nextDeckCardExceptBonus.month), \(nextDeckCardExceptBonus.type)")
            for card in matchingTableCards {
                print("... matchingTableCard: \(card.month), \(card.type)")
            }
            
            switch matchingTableCards.count {
            case 0: // 매칭카드 없는 경우
                // 흔들기
                if sameMonthPlayerHandCards.count == 3 {
                    // user
                    if self.gameData.currentPlayerIndex == 0 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .selectWave, cards: sameMonthPlayerHandCards, players: [player]) { select in
                            self.afterWave(isWave: select == 0, player: player, handCard: handCard, sameMonthPlayerHandCards: sameMonthPlayerHandCards, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                        }
                    }
                    // ai
                    else {
                        let isWave = self.aiManager.selectWave(gameData: self.gameData, playerIndex: player.index, cards: sameMonthPlayerHandCards)
                        self.afterWave(isWave: isWave, player: player, handCard: handCard, sameMonthPlayerHandCards: sameMonthPlayerHandCards, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                    }
                }
                else {
                    await self.playWithNoMatchingCard(playerIndex: player.index, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                }
            case 1: // 매칭카드 1개
                // 폭탄
                if sameMonthPlayerHandCards.count == 3 {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: sameMonthPlayerHandCards, tableCards: matchingTableCards)
                    self.gameData.players[player.index].waveCount += 1
                    SoundManager.shared.playSoundIfPossible(type: .bomb)
                    PopupManager.shared.showPopup(popupData: self.popupData, type: .bomb, cards: sameMonthPlayerHandCards, players: [player], completion: {_ in
                        Task{
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: sameMonthPlayerHandCards, tableCards: matchingTableCards) {
                                Task{
                                    await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 2) {
                                        Task{
                                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                                Task {
                                                    await self.flipDeckCardAfterBonusCard()
                                                    await self.setEmptyPlayerHandCards(playerIndex: player.index, count: 2)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
                //덱카드 뻑 처리(첫뻑, 첫뻑후 연속뻑, 연속뻑3회, 막장 제외)
                else if nextDeckCardExceptBonus.month == handCard.month && player.handCards.count > 1 {
                    await self.movePlayerHandCardsToTable(playerIndex: player.index, handCards: [handCard])
                    let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: handCard.month)
                    let fuckCards = [handCard, nextDeckCardExceptBonus] + matchingTableCards
                    await self.moveBonusDeckCardsToTable(tableCardGroupIndex: tableCardGroupIndex)
                    // await self.flipDeckCardAfterBonusCard() 가져가면 안됨
                    await self.moveDeckCardsToTable(soundType: .matching)
                    
                    // 점수 계산 순서정렬
                    var players = [self.gameData.players[player.index], self.gameData.players[((player.index + 1) % 3)] , self.gameData.players[((player.index + 2) % 3)]]
                    
                    // 시작 첫뻑
                    if player.handCards.count > 6 {
                        players[0].finalScore = 10
                        players[1].finalScore = -5
                        players[2].finalScore = -5
                        self.saveGameData(winnerIndex: nil, players: players, isNagari: nil)
                        SoundManager.shared.playSoundIfPossible(type: .fuck)
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .firstFuck, cards: fuckCards, players: [player]) {_ in
                            self.movePlayerPayouts(players: players) {
                                self.updatePlayersMoneyNodes(players: players)
                                self.checkScoreAndDoNextPlay()
                            }
                        }
                    }
                    //  2연뻑
                    else if player.handCards.count > 5 && player.fuckCardMonths.count == 1 {
                        players[0].finalScore = 20
                        players[1].finalScore = -10
                        players[2].finalScore = -10
                        self.saveGameData(winnerIndex: nil, players: players, isNagari: nil)
                        SoundManager.shared.playSoundIfPossible(type: .fuck)
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .secondFuck, cards: fuckCards, players: [player]) {_ in
                            self.movePlayerPayouts(players: players) {
                                self.updatePlayersMoneyNodes(players: players)
                                self.checkScoreAndDoNextPlay()
                            }
                        }
                    }
                    // 3번뻑 > 게임끝
                    else if player.fuckCardMonths.count == 2 {
                        let goBakPlayerIndex = self.getGoBakPlayerIndex(winnerIndex: player.index)
                        let players = ScoreEngine().getPlayersFinalScore(type: .thirdFuckWin ,winnerIndex: player.index, gameData: self.gameData, wasNagari: UserDefaults.standard.wasNagari ?? false, goBakPlayerIndex: goBakPlayerIndex)
                        self.gameData.winnerIndex = player.index
                        self.saveGameData(winnerIndex: player.index, players: players, isNagari: false)
                        
                        SoundManager.shared.playSoundIfPossible(type: .fuck)
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .thirdFuckWin, cards: fuckCards, players: players) {_ in
                            self.movePlayerPayouts(players: players) {
                                self.updatePlayersMoneyNodes(players: players)
                                self.replacePlayerIfNeeded(isShowPopup: true) {
                                    self.startGame()
                                }
                            }
                        }
                        return
                    }
                    else {
                        SoundManager.shared.playSoundIfPossible(type: .fuck)
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .fuck, cards: fuckCards, players: players, completion: {_ in
                            self.checkScoreAndDoNextPlay()
                        })
                    }
                    
                    self.gameData.players[self.gameData.currentPlayerIndex].fuckCardMonths.append(handCard.month)
                }
                else {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: matchingTableCards) {
                        Task {
                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index) {
                                Task {
                                    await self.flipDeckCardAfterBonusCard()
                                }
                            }
                        }
                    }
                }
            case 2: // 매칭카드 2개
                // 따닥 (첫따닥은 첫뻑과 동일)
                if nextDeckCardExceptBonus.month == handCard.month {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    let isFirstCardTadak = player.handCards.count > 5
                    SoundManager.shared.playSoundIfPossible(type: .tadak)
                    PopupManager.shared.showPopup(popupData: self.popupData, type: isFirstCardTadak  ? .firstTadak : .tadak, cards: [handCard, nextDeckCardExceptBonus] + matchingTableCards, players: [player]) { _ in
                        Task {
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: [matchingTableCards[0]]) {
                                Task {
                                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                        Task {
                                            await self.flipDeckCardAfterBonusCard()
                                            await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 1, completion: {
                                                // 첫따닥 5만냥
                                                if isFirstCardTadak {
                                                    // 점수 계산 순서정렬
                                                    var players = [self.gameData.players[player.index], self.gameData.players[((player.index + 1) % 3)] , self.gameData.players[((player.index + 2) % 3)]]
                                                    players[0].finalScore = 10
                                                    players[1].finalScore = -5
                                                    players[2].finalScore = -5
                                                    self.saveGameData(winnerIndex: nil, players: players, isNagari: nil)
                                                    self.movePlayerPayouts(players: players) {
                                                        self.updatePlayersMoneyNodes(players: players)
                                                    }
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // 매칭카드가 같은 종류이면 아무거나 가져가기
                else if matchingTableCards[0].type == matchingTableCards[1].type && matchingTableCards[0].isDoublePi == matchingTableCards[1].isDoublePi {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: [matchingTableCards[0]]){
                        Task {
                            await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                Task {
                                    await self.flipDeckCardAfterBonusCard()
                                }
                            }
                        }
                    }
                }
                // 카드선택
                else {
                    await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                    // user
                    if self.gameData.currentPlayerIndex == 0 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .selectCard, cards: [handCard] + matchingTableCards, players: [player]) { select in
                            self.afterSelectCard(player: player, deckOrHandCard: handCard, tableCard: self.popupData.cards[1])
                        }
                    }
                    // ai
                    else {
                        let tableCard = self.aiManager.selectCard(gameData: self.gameData,
                                                                  playerIndex: player.index,
                                                                  deckOrHandCard: handCard,
                                                                  tableCards: matchingTableCards
                        )
                        self.afterSelectCard(player: player, deckOrHandCard: handCard, tableCard: tableCard)
                    }
                }
            default:  // 매칭카드 3개 이상 (뻑하고 보너스가 함께 있을수 있음)
                // 3장 가져오기 ~ 한장씩 뺏기
                let isPlayerFuckCard = player.fuckCardMonths.first(where: { $0 == handCard.month }) != nil
                await self.movePlayerHandCardsToMatchingTableCards(handCards: [handCard], tableCards: matchingTableCards)
                SoundManager.shared.playSoundIfPossible(type: .threeTableCards)
                PopupManager.shared.showPopup(popupData: self.popupData, type: isPlayerFuckCard ? .threeTableCardsWithPlayerFuck : .threeTableCards, cards: [handCard] + matchingTableCards, players: [player], completion: { _ in
                    Task {
                        await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [handCard], tableCards: matchingTableCards) {
                            Task {
                                await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: isPlayerFuckCard ? 2 : 1) {
                                    Task{
                                        await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                                            Task {
                                                await self.flipDeckCardAfterBonusCard()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    // Winner가 고 한 경우가 이닌 마지막 사용자 index반환
    func getGoBakPlayerIndex(winnerIndex: Int) -> Int? {
        return gameData.goHistory.last{ $0 != winnerIndex }
    }
    
    // 덱카드 뒤집기 (보너스카드 이후)
    func flipDeckCardAfterBonusCard(kissHandCard: Card? = nil) async {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        guard let deckCard = self.gameData.deckCards.last else { return }
        
        Task {
            // 매칭카드가 갯수에 따른 처리
            let matchingTableCards = self.getMatchingTableCards(cardMonth: deckCard.month)
            print("\(#function) deckCard: \(deckCard.month), \(deckCard.type)")
            for card in matchingTableCards {
                print("... matchingTableCard: \(card.month), \(card.type)")
            }
            
            switch matchingTableCards.count {
            case 0: // 매칭카드 없는 경우
                await self.moveDeckCardsToTable(soundType: .noMatching)
                self.checkScoreAndDoNextPlay()
            case 1: // 매칭카드 1개 (
                await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                // 쪽인경우
                if let kissHandCard {
                    SoundManager.shared.playSoundIfPossible(type: .kiss)
                    PopupManager.shared.showPopup(popupData: popupData, type: .kiss, cards: [kissHandCard, deckCard], players: [player]) { select in
                        Task {
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: matchingTableCards){
                                // 쓸인경우
                                if !player.handCards.isEmpty && self.isEmptyTable() {
                                    SoundManager.shared.playSoundIfPossible(type: .ssl)
                                    PopupManager.shared.showPopup(popupData: self.popupData, type: .ssl, cards: [], players: [player]) { select in
                                        Task {
                                            await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 2) {
                                                self.checkScoreAndDoNextPlay()
                                            }
                                        }
                                    }
                                }
                                else {
                                    Task {
                                        await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 1) {
                                            self.checkScoreAndDoNextPlay()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: matchingTableCards){
                        
                        // 쓸인경우
                        if !player.handCards.isEmpty && self.isEmptyTable() {
                            SoundManager.shared.playSoundIfPossible(type: .ssl)
                            PopupManager.shared.showPopup(popupData: self.popupData, type: .ssl, cards: [], players: [player]) { select in
                                Task {
                                    await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: 1) {
                                        self.checkScoreAndDoNextPlay()
                                    }
                                }
                            }
                        }
                        else {
                            self.checkScoreAndDoNextPlay()
                        }
                    }
                    
                }
            case 2: // 매칭카드 2개
                // 매칭카드가 같은 종류이면 아무거나 가져가기
                if matchingTableCards[0].type == matchingTableCards[1].type && matchingTableCards[0].isDoublePi == matchingTableCards[1].isDoublePi {
                    await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                    await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: [matchingTableCards[0]]){
                        self.checkScoreAndDoNextPlay()
                    }
                }
                // 카드 선택
                else {
                    await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                    if self.gameData.currentPlayerIndex == 0 {
                        PopupManager.shared.showPopup(popupData: self.popupData, type: .selectCard, cards: [deckCard] + matchingTableCards, players: [player], completion: { select in
                            Task {
                                await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: [self.popupData.cards[1]]){
                                    self.checkScoreAndDoNextPlay()
                                }
                            }
                        })
                    }
                    else {
                        let selectCard = self.aiManager.selectCard(gameData: self.gameData, playerIndex: self.gameData.currentPlayerIndex, deckOrHandCard: deckCard, tableCards: matchingTableCards)
                        Task {
                            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: [selectCard]){
                                self.checkScoreAndDoNextPlay()
                            }
                        }
                    }
                }
            default:  // 매칭카드 3개 이상 (뻑하고 보너스가 함께 있을수 있음)
                let isPlayerFuckCard = player.fuckCardMonths.first(where: { $0 == deckCard.month }) != nil
                await self.moveDeckCardToMatchingTableCards(deckCard: deckCard, tableCards: matchingTableCards)
                SoundManager.shared.playSoundIfPossible(type: .threeTableCards)
                PopupManager.shared.showPopup(popupData: self.popupData, type: isPlayerFuckCard ? .threeTableCardsWithPlayerFuck : .threeTableCards, cards: [deckCard] + matchingTableCards, players: [player], completion: { _ in
                    Task {
                        await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckCard], tableCards: matchingTableCards) {
                            // 쓸인경우
                            if !player.handCards.isEmpty && self.isEmptyTable() {
                                SoundManager.shared.playSoundIfPossible(type: .ssl)
                                PopupManager.shared.showPopup(popupData: self.popupData, type: .ssl, cards: [], players: [player]) { select in
                                    Task {
                                        await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: isPlayerFuckCard ? 3 : 2) {
                                            self.checkScoreAndDoNextPlay()
                                        }
                                    }
                                }
                            }
                            else {
                                Task {
                                    await self.collectPiCardsFromOthers(toPlayerIndex: player.index, piCount: isPlayerFuckCard ? 2 : 1) {
                                        self.checkScoreAndDoNextPlay()
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    func afterSelectGoOrStop(isGo: Bool, player: Player) {
        if isGo {
            SoundManager.shared.playSoundIfPossible(type: .go)
            PopupManager.shared.showPopup(popupData: self.popupData, type: .go, cards: [], players: [player], message: "\(player.goCount + 1) 고!") { _ in
                self.gameData.currentPlayerIndex = (self.gameData.currentPlayerIndex + 1) % 3
                self.doPlay()
            }
            self.gameData.players[player.index].goCount += 1
            self.gameData.players[player.index].lastGoScore = player.baseScore
            self.gameData.goHistory.append(player.index)
        }
        else {
            SoundManager.shared.playSoundIfPossible(type: .stop)
            PopupManager.shared.showPopup(popupData: self.popupData, type: .stop, cards: [], players: [player]) { _ in
                self.stopPlayerGame(winnderIndex: player.index)
            }
        }
    }
    
    func afterWave(isWave: Bool, player: Player, handCard: Card, sameMonthPlayerHandCards: [Card], nextDeckCardExceptBonus: Card) {
        //  흔들기 선택
        if isWave {
            self.gameData.players[player.index].waveCount += 1
            SoundManager.shared.playSoundIfPossible(type: .wave)
            //  흔들기 확인 팝업 다시 보이기
            PopupManager.shared.showPopup(popupData: self.popupData, type: .wave, cards: sameMonthPlayerHandCards, players: [player]) { select in
                Task{
                    await self.playWithNoMatchingCard(playerIndex: player.index, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
                }
            }
        }
        else {
            Task{
                await self.playWithNoMatchingCard(playerIndex: player.index, handCard: handCard, nextDeckCardExceptBonus: nextDeckCardExceptBonus)
            }
        }
    }
    
    func afterSelectCard(player: Player, deckOrHandCard: Card, tableCard: Card) {
        Task {
            await self.moveMatchingCardsToPlayerCaptured(playerIndex: player.index, deckOrHandCards: [deckOrHandCard], tableCards: [tableCard]) {
                Task {
                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: player.index){
                        Task {
                            await self.flipDeckCardAfterBonusCard()
                        }
                    }
                }
            }
        }
    }
    
    func afterSelectGukjin(isDoublePi: Bool, playerIndex: Int, card: Card, tableCardGroupIndex: Int, completion: () -> Void) {
        //  쌍피 선택
        if isDoublePi {
            self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: card, forcedType: .pi)
        }
        // 열끗 선택
        else {
            self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: card)
        }
        self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
        completion()
    }
    
    func setEmptyPlayerHandCards(playerIndex: Int, count: Int) async {
        let scaleRate = playerIndex == 0 ? CardNodeScale.normal.rawValue : CardNodeScale.small.rawValue
        let cardSize = CGSize(width: self.normalCardSize.width * scaleRate, height: self.normalCardSize.height * scaleRate)
        
        for i in 0..<count {
            let card = Card(month: self.emptyCardMonth, type: .gwang, imageName: Card.emptyImageName)
            self.gameData.players[self.gameData.currentPlayerIndex].handCards.append(card)
            let node = CardNode(name: card.id.uuidString, card: card, cardSize: cardSize, isFront: true)
            node.position = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: self.gameData.players[playerIndex].handCards.count)
            node.zPosition = self.deckZPosition + CGFloat(i)
            self.addChild(node)
        }
    }
    
    func playWithNoMatchingCard(playerIndex: Int, handCard: Card, nextDeckCardExceptBonus: Card) async {
        let player = self.gameData.players[self.gameData.currentPlayerIndex]
        Task {
            // 폭탄으로 생긴 빈카드는 그냥 제거하고 덱카드 뒤집기
            if handCard.month == self.emptyCardMonth {
                self.removePlayerHandCards(playerIndex: player.index, handCards: [handCard])
            }
            // 먼저 선택카드를 테이블에 내려놓기
            else {
                await self.movePlayerHandCardsToTable(playerIndex: player.index, handCards: [handCard])
            }
            
            // 쪽이면 > 쪽카드 받아가기 (막장 제외)
            if nextDeckCardExceptBonus.month == handCard.month && player.handCards.count > 1 {
                await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: playerIndex) {
                    Task {
                        await self.flipDeckCardAfterBonusCard(kissHandCard: handCard)
                    }
                }
            }
            else {
                // 덱 보너스 카드 처리 후 카드 뒤집기
                await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: playerIndex) {
                    Task {
                        await self.flipDeckCardAfterBonusCard()
                    }
                }
            }
        }
    }
}
