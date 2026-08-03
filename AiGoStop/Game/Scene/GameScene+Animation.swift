//
//  GameScene+Animation.swift
//  AiGoStop
//
//  카드 이동 · 정렬 · 보너스 애니메이션
//

import SpriteKit
import SwiftUI

extension GameScene {
    
    func collectPiCardsFromOthers(toPlayerIndex: Int, piCount: Int, completion: @escaping () -> Void) async {
        print("\(#function) 가져올 피 \(piCount)장")
        Task{
            await self.moveOtherPlayersCapturedCardsToPlayerCaptured(toPlayerIndex: toPlayerIndex, piCount: piCount)
            completion()
        }
    }
    
    func movePlayerPayouts(players: [Player], completion: @escaping () -> Void) {
        var didActCompletion = false // completion 중복실행 방지
        
        guard let winnerIconNode = self.childNode(withName: PlayerIconNode.prefixName + "\(players[0].index)") else { return }
        guard let loser1Node = self.childNode(withName: PlayerIconNode.prefixName + "\(players[1].index)") else { return }
        guard let loser2Node = self.childNode(withName: PlayerIconNode.prefixName + "\(players[2].index)") else { return }
        
        if players[1].finalScore != 0 {
            let loser1PayoutNode = MoneyNode(position: loser1Node.position)
            self.addChild(loser1PayoutNode)
            loser1PayoutNode.moveToWinner(movePosition: winnerIconNode.position, duration: self.gameData.cardDuration){
                if !didActCompletion {
                    completion()
                    didActCompletion = true
                }
            }
        }
        if players[2].finalScore != 0 {
            let loser2PayoutNode = MoneyNode(position: loser2Node.position)
            self.addChild(loser2PayoutNode)
            loser2PayoutNode.moveToWinner(movePosition: winnerIconNode.position, duration: self.gameData.cardDuration) {
                if !didActCompletion {
                    completion()
                    didActCompletion = true
                }
            }
        }
    }
    
    func isEmptyTable() -> Bool {
        for tableCardGroup in self.gameData.tableCardGroups {
            if tableCardGroup.count > 0 { return false }
        }
        return true
    }
    
    // Test : 한사람에게 카드 몰빵
    func moveDeckCardToPlayerCaptured(playerIndex: Int) async {
        let deckCard = self.gameData.deckCards.removeLast()
        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: deckCard)
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func moveCardToPlayerCaptured(playerIndex: Int, card: Card, forcedType: CardType? = nil) {
        print("\(#function) card: \(card.month), \(card.type)")
        guard let cardNode = self.childNode(withName: card.id.uuidString) as? CardNode else { return }
        cardNode.removeStroke()
        
        // 국진일 경우 type 강제 할당
        let cardIndexByType = self.gameData.players[playerIndex].capturedCardTypeGroups[forcedType?.rawValue ?? card.type.rawValue].count
        self.gameData.players[playerIndex].capturedCardTypeGroups[forcedType?.rawValue ?? card.type.rawValue].append(card)
        
        let movePosition = self.getPlayerCapturedCardPosition(playerIndex: playerIndex, cardIndexByType: cardIndexByType, cardType: forcedType ?? card.type)
        cardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: true, zPosition: cardIndexByType, afterCardNodeScale: .normal, soundType: nil, completion: {
            self.setPlayerScoreNodes(playerIndex: playerIndex)
        })
    }
    
    func moveCardToTable(card: Card, tableCardGroupIndex: Int, soundType: SoundType?) {
        print("\(#function) card: \(card.month), \(card.type)")
        guard let cardNode = childNode(withName: card.id.uuidString) as? CardNode else { return }
        cardNode.removeStroke()
        let cardIndexByGroup = self.gameData.tableCardGroups[tableCardGroupIndex].count
        let zPosition = self.getTableCardZPosition(groupIndex: tableCardGroupIndex, cardIndexByGroup: cardIndexByGroup)
        let movePosition = self.getTableCardPosition(groupIndex: tableCardGroupIndex, cardIndexByGroup: cardIndexByGroup)
        self.gameData.tableCardGroups[tableCardGroupIndex].append(card)
        cardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: true, zPosition: Int(zPosition), afterCardNodeScale: .large, soundType: soundType)
    }
    
    func moveDeckCardsToTable(count: Int = 1, soundType: SoundType?) async {
        for _ in 0..<count {
            if self.gameData.deckCards.count == 0 { return }
            let deckCard = self.gameData.deckCards.removeLast()
            print("\(#function) deckCard: \(deckCard.month), \(deckCard.type)")
            let existedTableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: deckCard.month)
            let tableCardGroupIndex = existedTableCardGroupIndex ?? self.getEmptyTableCardGroupIndex(cardMonth: deckCard.month)
            //self.moveCardToTable(card: deckCard, tableCardGroupIndex: tableCardGroupIndex, soundType: existedTableCardGroupIndex == nil ? .noMatching : .matching)
            self.moveCardToTable(card: deckCard, tableCardGroupIndex: tableCardGroupIndex, soundType: soundType)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func isGukjinCard(card: Card) -> Bool {
        return card.month == 9 && card.type == .yeol
    }
    
    func moveBonusPlayerHandBonusCardToPlayerCaptured(playerIndex: Int, handCard: Card) async {
        // 가지고 있는 카드를 수집카드로// 손에서 비움
        self.gameData.players[playerIndex].handCards.removeAll { $0.id == handCard.id }
        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: handCard)
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
        
        // 덱에서 카드 한장 새로 받기
        await self.moveDeckCardToPlayerHand(playerIndex: playerIndex)
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func getTableCardZPosition(groupIndex: Int, cardIndexByGroup: Int) -> Int {
        // 왼쪽 테이블 카드가 zPiosition이 높아야 함
        // 14개 기준
        if groupIndex % 2 == 0 {
            return (groupIndex + 1) * 10 + cardIndexByGroup
        }
        else {
            return (20 - groupIndex) * 10 + cardIndexByGroup
        }
    }
    
    func moveDeckCardToMatchingTableCards(deckCard: Card, tableCards: [Card]) async {
        guard let deckCardNode = childNode(withName: deckCard.id.uuidString) as? CardNode else { return }
        guard let matchingTableCardNode = childNode(withName: tableCards.last!.id.uuidString) as? CardNode else { return }
        
        let groupIndex = self.getTableCardGroupIndex(cardMonth: deckCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: deckCard.month)
        let cardIndexByGroup = self.gameData.tableCardGroups[groupIndex].count
        let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
        
        print("tablecarscount:\(tableCards.count), groupIndex = \(groupIndex), cardIndexByGroup = \(cardIndexByGroup), zposition =\(zPosition)")
        var matchPosition = matchingTableCardNode.position
        matchPosition.x += 10
        matchPosition.y -= 10
        
        deckCardNode.moveAndTurnCard(movePosition: matchPosition, duration: self.gameData.cardDuration, isFront: true, zPosition: zPosition, afterCardNodeScale: .large, soundType: .matching)
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func movePlayerHandCardsToMatchingTableCards(handCards: [Card], tableCards: [Card]) async {
        for (i, handCard) in handCards.enumerated() {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            guard let matchingTableCardNode = childNode(withName: tableCards.last!.id.uuidString) as? CardNode else { return }
            
            let groupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: handCard.month)
            let cardIndexByGroup = self.gameData.tableCardGroups[groupIndex].count + (i + 1)
            let zPosition = self.getTableCardZPosition(groupIndex: groupIndex, cardIndexByGroup: cardIndexByGroup)
            
            var matchPosition = matchingTableCardNode.position
            matchPosition.x += CGFloat(10 * (i + 1))
            matchPosition.y -= CGFloat(10 * (i + 1))
            
            handCardNode.removeStroke()
            handCardNode.moveAndTurnCard(movePosition: matchPosition, duration: self.gameData.cardDuration, isFront: true, zPosition: zPosition, afterCardNodeScale: .large, soundType: .matching)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func moveMatchingDeckOrHandCardToPlayerCaptured(playerIndex: Int, deckOrHandCards: [Card] = [], tableCards: [Card], completion: @escaping () -> Void) {
        let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: tableCards.last!.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: tableCards.last!.month)
        var gukjinCard: Card? = nil
        
        for deckOrHandCard in deckOrHandCards {
            self.gameData.players[playerIndex].handCards.removeAll { $0.id == deckOrHandCard.id }
            self.gameData.deckCards.removeAll { $0.id == deckOrHandCard.id }
            
            // 국진 위치
            if self.isGukjinCard(card: deckOrHandCard) {
                gukjinCard = deckOrHandCard
            }
            else {
                self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: deckOrHandCard)
            }
        }
        
        if let gukjinCard {
            // user
            if self.gameData.currentPlayerIndex == 0 {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [gukjinCard], players: [self.gameData.players[playerIndex]]) { select in
                    self.afterSelectGukjin(isDoublePi: select == 0, playerIndex: playerIndex, card: gukjinCard, tableCardGroupIndex: tableCardGroupIndex, completion: completion)
                }
            }
            // ai
            else {
                //  쌍피 선택
                let isDoublePi = self.aiManager.selectGukjin(gameData: self.gameData, playerIndex: playerIndex)
                self.afterSelectGukjin(isDoublePi: isDoublePi, playerIndex: playerIndex, card: gukjinCard, tableCardGroupIndex: tableCardGroupIndex, completion: completion)
            }
        }
        else {
            self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
            completion()
        }
    }
    
    func moveMatchingTableCardsToPlayerCaptured(playerIndex: Int, tableCards: [Card], completion: @escaping () -> Void) {
        let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: tableCards.last!.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: tableCards.last!.month)
        var gukjinCard: Card? = nil
        
        for tableCard in tableCards {
            self.removeTableCard(card: tableCard)
            
            
            // 국진 위치
            if self.isGukjinCard(card: tableCard) {
                gukjinCard = tableCard
            }
            else {
                self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: tableCard)
            }
        }
        
        if let gukjinCard {
            // user
            if playerIndex == 0 {
                PopupManager.shared.showPopup(popupData: self.popupData, type: .selectGukjin, cards: [gukjinCard], players: [self.gameData.players[playerIndex]]) { select in
                    //  쌍피 선택
                    if select == 0 {
                        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard, forcedType: .pi)
                        self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    }
                    // 열끗 선택
                    else {
                        self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard)
                        self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    }
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    completion()
                }
            }
            // ai
            else {
                //  쌍피 선택
                if self.aiManager.selectGukjin(gameData: self.gameData, playerIndex: playerIndex) {
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard, forcedType: .pi)
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                }
                // 열끗 선택
                else {
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: gukjinCard)
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                }
                self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                completion()
            }
            
        }
        else {
            self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
            completion()
        }
    }
    
    func moveMatchingCardsToPlayerCaptured(playerIndex: Int, deckOrHandCards: [Card] = [], tableCards: [Card], completion: @escaping () -> Void) async {
        print("\(#function) playerIndex: \(playerIndex), deckOrHandCards: \(deckOrHandCards.count), tableCards: \(tableCards.count)")
        self.moveMatchingDeckOrHandCardToPlayerCaptured(playerIndex: playerIndex, deckOrHandCards: deckOrHandCards, tableCards: tableCards) {
            self.moveMatchingTableCardsToPlayerCaptured(playerIndex: playerIndex, tableCards: tableCards) {
                Task{
                    do { try await Task.sleep(for: .seconds(self.self.gameData.cardDuration))
                    } catch { print("error: \(error)")}
                    completion()
                }
            }
        }
    }
    
    // 테이블 바닥카드 가져갈때 해당 그룹 정렬
    func sortTableCardGroup(tableCardGroupIndex: Int) {
        for (i, card) in self.gameData.tableCardGroups[tableCardGroupIndex].enumerated() {
            guard let cardNode = childNode(withName: card.id.uuidString) as? CardNode else { continue }
            let zPosition = self.getTableCardZPosition(groupIndex: tableCardGroupIndex, cardIndexByGroup: i)
            let movePosition = self.getTableCardPosition(groupIndex: tableCardGroupIndex, cardIndexByGroup: i)
            cardNode.moveAndTurnCard(movePosition: movePosition, isFront: true, zPosition: zPosition, movingUpScale: nil, afterCardNodeScale: .large, soundType: nil)
        }
    }
    
    func moveDeckCardToPlayerHand(playerIndex: Int, count: Int = 1) async {
        for _ in 0..<count {
            guard let deckCardNode = childNode(withName: self.gameData.deckCards.last?.id.uuidString ?? "") as? CardNode else { return }
            let lastDeckCard = self.gameData.deckCards.removeLast()
            let cardIndex = self.gameData.players[playerIndex].handCards.count
            let movePosition = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: cardIndex)
            self.gameData.players[playerIndex].handCards.append(lastDeckCard)
            deckCardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: playerIndex == 0, afterCardNodeScale: playerIndex == 0 ? .large : .small, soundType: nil)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func movePlayerHandCardsToTable(playerIndex: Int, handCards: [Card]) async {
        for handCard in handCards {
            self.gameData.players[playerIndex].handCards.removeAll { $0.id == handCard.id }
            let existTableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: handCard.month)
            let tableCardGroupIndex = existTableCardGroupIndex ?? self.getEmptyTableCardGroupIndex(cardMonth: handCard.month)
            self.moveCardToTable(card: handCard, tableCardGroupIndex: tableCardGroupIndex, soundType: existTableCardGroupIndex == nil ? .noMatching : .matching)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func removePlayerHandCards(playerIndex: Int, handCards: [Card]) {
        var handCardNodes: [SKNode] = []
        for handCard in handCards {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            handCardNodes.append(handCardNode)
            self.gameData.players[playerIndex].handCards.removeAll { $0.id == handCard.id }
        }
        self.removeChildren(in: handCardNodes)
    }
    
    func sortPlayerHandCards(playerIndex: Int) {
        self.gameData.players[playerIndex].handCards.sort { (card1, card2) -> Bool in
            if card1.month < card2.month { return true }
            else if card1.month > card2.month { return false }
            else { return card1.type.rawValue > card2.type.rawValue }
        }
        for (i, handCard) in self.gameData.players[playerIndex].handCards.enumerated() {
            guard let handCardNode = childNode(withName: handCard.id.uuidString) as? CardNode else { return }
            
            // 사용자 카드가 테이블에 있으면 깜빡이게 표시하기 or 보너스카드
            if self.gameData.currentPlayerIndex == 0 && playerIndex == 0 && (handCard.month == 100 || handCard.month == 0 || self.getTableCardGroupIndex(cardMonth: handCard.month) != nil) {
                handCardNode.addStrokeWithBlink(size: self.normalCardSize)
            }
            else {
                handCardNode.removeStroke()
            }
            
            let movePosition = self.getPlayerHandCardPosition(playerIndex: playerIndex, cardIndex: i)
            // 동일위치 다시 그리기 방지 (위치값 소숫점 미세하게 변경 무시)
            if Int(movePosition.x) == Int(handCardNode.position.x) && Int(movePosition.y) == Int(handCardNode.position.y) {
                //print("\(#function) same positioin \(i)")
            }
            else {
                //print("\(#function) different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
                handCardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: playerIndex == 0, movingUpScale: nil, afterCardNodeScale: playerIndex == 0 ? .large : .small, soundType: nil)
            }
        }
    }
    
    func sortPlayerCapturedPiCards(playerIndex: Int) {
        for capturedCard in self.gameData.players[playerIndex].capturedCardTypeGroups[CardType.pi.rawValue] {
            guard let capturedCardNode = childNode(withName: capturedCard.id.uuidString) as? CardNode else { return }
            let cardIndexByType = self.gameData.players[playerIndex].capturedCardTypeGroups[capturedCard.type.rawValue].firstIndex{ c in c.id == capturedCard.id } ?? 0
            // 6쌍피가 있어 강제 pi로만 위치 가져오기
            let movePosition = self.getPlayerCapturedCardPosition(playerIndex: playerIndex, cardIndexByType: cardIndexByType, cardType: .pi)
            // 동일위치 다시 그리기 방지 (위치값 소숫점 미세하게 변경 무시)
            if Int(movePosition.x) == Int(capturedCardNode.position.x) && Int(movePosition.y) == Int(capturedCardNode.position.y) {
                //print("\(#function) same positioin \(i)")
            }
            else {
                //print("\(#function) different positioin \(i) current(\(handCardNode.position.x),\(handCardNode.position.y)),target(\(movePosition.x),\(movePosition.y))")
                capturedCardNode.moveAndTurnCard(movePosition: movePosition, duration: self.gameData.cardDuration, isFront: true, zPosition: cardIndexByType, movingUpScale: nil, afterCardNodeScale: .normal, soundType: nil)
            }
        }
    }
    
    // 테이블 카드가 보너스 카드인 경우(복수가능) > 덱카드 다시받기 > 다시받은 카드가 보너스카드인경우 재귀반복
    func moveBonusTableCardToPlayerCapturedAndMoveDeckCardToTableAgain(playerIndex: Int) async  {
        var bounsCardCount = 0
        
        for i in (0..<self.gameData.tableCardGroups.count).reversed() {
            for j in (0..<self.gameData.tableCardGroups[i].count).reversed() {
                let tableCard = self.gameData.tableCardGroups[i][j]
                if tableCard.month == 0 {
                    // table에서 제거하고 winner에게 지급
                    let tableCardGroupIndex = self.getTableCardGroupIndex(cardMonth: tableCard.month) ?? self.getEmptyTableCardGroupIndex(cardMonth: tableCard.month)
                    self.removeTableCard(card: tableCard)
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: tableCard)
                    self.sortTableCardGroup(tableCardGroupIndex: tableCardGroupIndex)
                    
                    do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
                    } catch { print("error: \(error)")}
                    
                    bounsCardCount += 1
                }
            }
        }
        
        // 재귀함수 호출
        if bounsCardCount > 0 {
            for _ in 0..<bounsCardCount {
                await self.moveDeckCardsToTable(soundType: .noMatching)
                await moveBonusTableCardToPlayerCapturedAndMoveDeckCardToTableAgain(playerIndex: playerIndex)
            }
        }
    }
    
    // 보너스 카드가 연속인 경우 처리, 보너스 카드가 아닌경우
    func moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: Int, completion: @escaping () -> Void) async  {
        guard let deckCard = self.gameData.deckCards.last else { return }
        if deckCard.month == 0 {
            SoundManager.shared.playSoundIfPossible(type: .deckBonus)
            PopupManager.shared.showPopup(popupData: self.popupData, type: .deckBonus, cards: [deckCard], players: [self.gameData.players[playerIndex]]) { _ in
                Task {
                    // table에서 제거하고 winner에게 지급
                    self.gameData.deckCards.removeLast()
                    self.moveCardToPlayerCaptured(playerIndex: playerIndex, card: deckCard)
                    
                    do { try await Task.sleep(for: .seconds(self.self.gameData.cardDuration))
                    } catch { print("error: \(error)")}
                    
                    // 다시 시도
                    await self.moveBonusDeckCardsToPlayerCapturedIfNeeded(playerIndex: playerIndex, completion: completion)
                }
            }
        }
        else {
            completion()
        }
    }
    
    func moveOtherPlayersCapturedCardsToPlayerCaptured(toPlayerIndex: Int, piCount: Int) async  {
        for anotherPlayer in self.gameData.players {
            if anotherPlayer.index == toPlayerIndex { continue }
            
            let doublePi: Card? = anotherPlayer.capturedCardTypeGroups[CardType.pi.rawValue].last{ $0.isDoublePi == true }
            let onePis: [Card] = anotherPlayer.capturedCardTypeGroups[CardType.pi.rawValue].filter{ $0.isDoublePi == false }.suffix(2) // 뒤에 쌍피가 아닌 일반피 두개 가져오기
            
            var movingCards: [Card] = []
            
            switch piCount {
            case 1: // 피가 한개있으면 가져오고 없으면 쌍피가져오기
                if let onePi = onePis.last {
                    movingCards.append(onePi)
                }
                else if let pi2 = doublePi {
                    movingCards.append(pi2)
                }
            case 2: // 쌍피 있으면 가져오고 없으면 피 두개 가져오기
                if let pi2 = doublePi {
                    movingCards.append(pi2)
                }
                else {
                    movingCards = onePis
                }
            default :
                break
            }
            
            for movingCard in movingCards {
                self.gameData.players[anotherPlayer.index].capturedCardTypeGroups[CardType.pi.rawValue].removeAll { $0.id == movingCard.id }
                self.moveCardToPlayerCaptured(playerIndex: toPlayerIndex, card: movingCard, forcedType: .pi) // 국진도 피로!
            }
            
            self.sortPlayerCapturedPiCards(playerIndex: anotherPlayer.index)
            self.setPlayerScoreNodes(playerIndex: anotherPlayer.index)
        }
        
        do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
        } catch { print("error: \(error)")}
    }
    
    func moveBonusDeckCardsToTable(tableCardGroupIndex: Int) async  {
        if self.gameData.deckCards.last?.month == 0 {
            // table에서 제거하고 winner에게 지급
            let deckCard = self.gameData.deckCards.removeLast()
            self.moveCardToTable(card: deckCard, tableCardGroupIndex: tableCardGroupIndex, soundType: .noMatching)
            
            do { try await Task.sleep(for: .seconds(self.gameData.cardDuration))
            } catch { print("error: \(error)")}
            // 반복
            Task {
                await self.moveBonusDeckCardsToTable(tableCardGroupIndex: tableCardGroupIndex)
            }
        }
        else {
            return
        }
    }
}
