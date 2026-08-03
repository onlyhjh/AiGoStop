//
//  CursorAIEngine.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 6/25/26.
//

import Foundation

/// 고스톱 AI — 점수·족보·상대 견제를 반영한 휴리스틱 엔진
final class CursorAIEngine: AIEngine {

    /// true = 고, false = 스톱
    func selectGoOrStop(gameData: GameData, playerIndex: Int) -> Bool {
        let player = gameData.players[playerIndex]
        let opponents = opponentPlayers(gameData: gameData, excluding: playerIndex)
        let myScore = player.baseScore
        let mySubtotal = player.subtotalScore
        let maxOpponentScore = opponents.map(\.baseScore).max() ?? 0
        let maxOpponentSubtotal = opponents.map(\.subtotalScore).max() ?? 0
        let scoreGain = myScore - player.lastGoScore
        let deckRemaining = gameData.deckCards.count
        let upside = handUpside(gameData: gameData, for: player, tableCards: gameData.allTableCards)

        // 막장이면 무조건 스톱
        if player.handCards.isEmpty {
            return false
        }

        // 실질 점수(배수 반영)로 크게 앞서면 스톱
        if mySubtotal >= maxOpponentSubtotal + 8 && myScore >= 6 {
            return false
        }

        // 8점 이상이면서 앞서면 스톱 (배수 리스크 감수 한계)
        if myScore >= 8 && myScore > maxOpponentScore {
            return false
        }

        // 상대 실질 점수가 높으면 적극적으로 고
        if maxOpponentSubtotal > mySubtotal || maxOpponentScore >= 5 && myScore <= maxOpponentScore {
            return shouldGoAggressively(
                player: player,
                scoreGain: scoreGain,
                deckRemaining: deckRemaining,
                upside: upside
            )
        }

        // 이미 고를 한 상태
        if player.goCount > 0 {
            if scoreGain <= 0 {
                return false
            }
            // 3고 이상 + 낮은 기본점 → 스톱
            if player.goCount >= 3 && myScore < 4 {
                return false
            }
            // 실질 점수로 충분히 앞서고 점수도 올랐으면 스톱
            if mySubtotal > maxOpponentSubtotal && myScore >= 5 && scoreGain >= 2 {
                return false
            }
            return scoreGain >= 1 && upside >= 5
        }

        // 첫 고: 앞서거나 비슷하면 손익 보고 고
        if myScore >= 4 {
            if mySubtotal <= maxOpponentSubtotal {
                return scoreGain >= 1 || upside >= 6
            }
            return upside >= 8 && deckRemaining > 4
        }

        if myScore >= 3 {
            if maxOpponentScore >= myScore || maxOpponentSubtotal >= mySubtotal {
                return scoreGain >= 1 || upside >= 6
            }
            return upside >= 10 && deckRemaining > 6
        }

        // 3점 미만이어도 상대보다 뒤처지고 여지가 있으면 고
        if myScore >= 2 && maxOpponentScore >= 3 && upside >= 8 {
            return true
        }

        return false
    }

    /// 매칭 테이블 카드 2장 중 가져갈 카드 선택
    func selectCard(gameData: GameData, playerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card {
        guard tableCards.count >= 2 else {
            return tableCards.last ?? deckOrHandCard
        }

        let player = gameData.players[playerIndex]
        return tableCards.max { lhs, rhs in
            capturePairValue(gameData: gameData, handOrDeck: deckOrHandCard, table: lhs, player: player)
                < capturePairValue(gameData: gameData, handOrDeck: deckOrHandCard, table: rhs, player: player)
        } ?? tableCards[0]
    }

    /// true = 쌍피, false = 열끗
    func selectGukjin(gameData: GameData, playerIndex: Int) -> Bool {
        let player = gameData.players[playerIndex]

        // 고도리 2장 → 열끗
        if player.godoriCount == 2 {
            return false
        }

        // 열 4장 → 열끗으로 점수
        if player.yeolCount == 4 {
            return false
        }

        // 피 8장 이하 → 쌍피(2피)가 유리
        if player.piCount <= 7 {
            return true
        }

        // 피 9장 → 쌍피로 10피 완성
        if player.piCount == 9 {
            return true
        }

        // 피가 충분하고 열/고도리 쪽이 더 필요하면 열끗
        let yeolValue = marginalYeolValue(for: player)
        let piValue = marginalPiValue(for: player, asDouble: true)
        return piValue >= yeolValue
    }

    /// true = 흔들기
    func selectWave(gameData: GameData, playerIndex: Int, cards: [Card]) -> Bool {
        let player = gameData.players[playerIndex]
        guard cards.count == 3 else { return false }

        // 2점 미만이면 흔들기 배수 효과가 너무 작음
        if player.baseScore < 2 {
            return false
        }

        // 4점 이상이면 흔들기로 배수 적극 활용
        if player.baseScore >= 4 {
            return true
        }

        // 2~3점: 같은 월 추가 기대(총통·폭탄) 또는 상대 실질 점수가 높을 때
        let month = cards[0].month
        let sameMonthInHand = player.handCards.filter { $0.month == month }.count
        let sameMonthInDeck = gameData.deckCards.filter { $0.month == month }.count
        let opponents = opponentPlayers(gameData: gameData, excluding: playerIndex)
        let maxOpponentSubtotal = opponents.map(\.subtotalScore).max() ?? 0

        if sameMonthInHand + sameMonthInDeck >= 1 {
            return true
        }
        return player.subtotalScore <= maxOpponentSubtotal
    }

    /// AI가 낼 손패 카드 선택
    func selectHandCard(gameData: GameData, playerIndex: Int) -> Card {
        let player = gameData.players[playerIndex]
        let handCards = player.handCards
        guard !handCards.isEmpty else {
            return Card(month: 0, type: .pi)
        }

        let tableByMonth = tableCardsByMonth(gameData.allTableCards)
        let nextDeckMonth = nextNonBonusDeckMonth(gameData: gameData)

        return handCards.max { lhs, rhs in
            handCardPlayValue(
                gameData: gameData,
                card: lhs,
                player: player,
                tableByMonth: tableByMonth,
                nextDeckMonth: nextDeckMonth
            ) < handCardPlayValue(
                gameData: gameData,
                card: rhs,
                player: player,
                tableByMonth: tableByMonth,
                nextDeckMonth: nextDeckMonth
            )
        } ?? handCards[0]
    }

    // MARK: - Hand card evaluation

    private func handCardPlayValue(
        gameData: GameData,
        card: Card,
        player: Player,
        tableByMonth: [Int: [Card]],
        nextDeckMonth: Int?
    ) -> Double {
        if card.month == 0 {
            return projectedCaptureValue(gameData: gameData, cards: [card], for: player) + 5
        }

        let sameInHand = player.handCards.filter { $0.month == card.month }.count
        let tableMatches = tableByMonth[card.month] ?? []
        var value = 0.0

        switch tableMatches.count {
        case 0:
            // 흔들기·쌓기
            if sameInHand == 3 {
                value += selectWave(gameData: gameData, playerIndex: player.index, cards: player.handCards.filter { $0.month == card.month })
                    ? 18 : 6
            } else {
                value -= 2
            }
            if let nextDeckMonth, nextDeckMonth == card.month, sameInHand < 3, player.handCards.count > 1 {
                value -= 12
            }
        case 1:
            if sameInHand == 3 {
                value += 35
            } else {
                let captured = tableMatches + [card]
                value += captured.reduce(0.0) { $0 + cardIntrinsicValue($1, for: player) }
                value += setCompletionBonus(gameData: gameData, adding: captured, to: player)
            }
            if let nextDeckMonth, nextDeckMonth == card.month, sameInHand < 3, player.handCards.count > 1 {
                value -= 8
            }
        case 2:
            let bestTable = selectCard(gameData: gameData,
                playerIndex: player.index,
                deckOrHandCard: card,
                tableCards: tableMatches
            )
            value += capturePairValue(gameData: gameData, handOrDeck: card, table: bestTable, player: player)
        default:
            value += 25
            if player.fuckCardMonths.contains(card.month) {
                value += 10
            }
        }

        return value
    }

    // MARK: - Scoring helpers

    private func capturePairValue(gameData: GameData, handOrDeck: Card, table: Card, player: Player) -> Double {
        let cards = [handOrDeck, table]
        var value = cards.reduce(0.0) { $0 + cardIntrinsicValue($1, for: player) }
        value += setCompletionBonus(gameData: gameData, adding: cards, to: player)

        if isGukjin(table) {
            value += max(marginalPiValue(for: player, asDouble: true), marginalYeolValue(for: player))
        }
        if isGukjin(handOrDeck) {
            value += max(marginalPiValue(for: player, asDouble: true), marginalYeolValue(for: player))
        }

        return value
    }

    private func cardIntrinsicValue(_ card: Card, for player: Player) -> Double {
        switch card.type {
        case .gwang:
            var value = 12.0
            if player.gwangCount == 2 { value += 18 }
            if player.gwangCount >= 3 { value += 8 }
            if player.gwangCount == 4 { value += 25 }
            return value
        case .yeol:
            var value = 4.0
            if card.isGodori {
                value += 6
                if player.godoriCount == 2 { value += 20 }
            }
            if player.yeolCount == 4 { value += 5 }
            return value
        case .tti:
            var value = 3.0
            if card.isChoDan {
                value += danProgressBonus(current: player.chodanCount)
            }
            if card.isHongDan {
                value += danProgressBonus(current: player.hongdanCount)
            }
            if card.isChungDan {
                value += danProgressBonus(current: player.chungdanCount)
            }
            if player.ttiCount == 4 { value += 4 }
            return value
        case .pi:
            var value = 1.0
            if card.isDoublePi { value = 2.5 }
            if player.piCount == 9 { value += 15 }
            if player.piCount >= 7 { value += 3 }
            return value
        }
    }

    private func danProgressBonus(current count: Int) -> Double {
        switch count {
        case 0: return 2
        case 1: return 8
        case 2: return 18
        default: return 0
        }
    }

    private func setCompletionBonus(gameData: GameData, adding cards: [Card], to player: Player) -> Double {
        Double(projectedSubtotalScore(gameData: gameData, for: player, adding: cards) - player.subtotalScore)
    }

    private func projectedCaptureValue(gameData: GameData, cards: [Card], for player: Player) -> Double {
        Double(projectedSubtotalScore(gameData: gameData, for: player, adding: cards))
    }

    private func projectedSubtotalScore(gameData: GameData, for player: Player, adding cards: [Card]) -> Int {
        projectedPlayer(from: player, adding: cards, gameData: gameData).subtotalScore
    }

    private func projectedPlayer(from player: Player, adding cards: [Card], gameData: GameData) -> Player {
        var projected = player
        for card in cards {
            if isGukjin(card) {
                if selectGukjin(gameData: gameData, playerIndex: player.index) {
                    projected.capturedCardTypeGroups[CardType.pi.rawValue].append(
                        Card(month: card.month, type: .pi, isDoublePi: true)
                    )
                } else {
                    projected.capturedCardTypeGroups[CardType.yeol.rawValue].append(card)
                }
            } else {
                projected.capturedCardTypeGroups[card.type.rawValue].append(card)
            }
        }
        return projected
    }

    private func marginalPiValue(for player: Player, asDouble: Bool) -> Double {
        let added = asDouble ? 2 : 1
        let newCount = player.piCount + added
        if player.piCount <= 9 && newCount > 9 {
            return 20
        }
        if player.piCount == 8 && newCount >= 9 {
            return 12
        }
        return Double(added)
    }

    private func marginalYeolValue(for player: Player) -> Double {
        if player.godoriCount == 2 { return 22 }
        if player.yeolCount == 4 { return 8 }
        return 4
    }

    private func handUpside(gameData: GameData, for player: Player, tableCards: [Card]) -> Double {
        let tableByMonth = tableCardsByMonth(tableCards)
        let nextDeckMonth = nextNonBonusDeckMonth(gameData: gameData)
        return player.handCards.reduce(0.0) { partial, card in
            partial + handCardPlayValue(gameData: gameData,
                card: card,
                player: player,
                tableByMonth: tableByMonth,
                nextDeckMonth: nextDeckMonth
            )
        }
    }

    private func shouldGoAggressively(
        player: Player,
        scoreGain: Int,
        deckRemaining: Int,
        upside: Double
    ) -> Bool {
        if scoreGain >= 1 && upside >= 4 { return true }
        if scoreGain >= 2 { return true }
        if deckRemaining <= 6 && player.baseScore >= 3 { return true }
        return player.baseScore >= 2 && player.handCards.count >= 2 && upside >= 6
    }

    // MARK: - Utilities

    private func opponentPlayers(gameData: GameData, excluding index: Int) -> [Player] {
        gameData.players.enumerated()
            .filter { $0.offset != index }
            .map(\.element)
    }

    private func tableCardsByMonth(_ tableCards: [Card]) -> [Int: [Card]] {
        Dictionary(grouping: tableCards.filter { $0.month != 100 }, by: \.month)
    }

    private func nextNonBonusDeckMonth(gameData: GameData) -> Int? {
        for card in gameData.deckCards.reversed() where card.month != 0 {
            return card.month
        }
        return nil
    }

    private func isGukjin(_ card: Card) -> Bool {
        card.month == 9 && card.type == .yeol
    }
}
