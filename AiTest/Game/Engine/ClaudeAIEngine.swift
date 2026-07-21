//
//  ClaudeAIEngine.swift
//  AiTest
//
//  Created by Joey's Mac mini on 6/25/26.
//
//  ── Claude AI Engine ──────────────────────────────────────────────────────────
//  전략 개요:
//  1. selectHandCard  : 기대 점수(Expected Value) 기반 + 상대방 저지 전략 카드 우선 선택
//  2. selectGoOrStop  : 현재 점수, 남은 패 수, 상대방 점수, 고 배율 리스크를 종합 판단
//  3. selectCard      : 테이블의 2장 중 자신에게 더 가치 있는 카드 선택
//  4. selectGukjin    : 국진(9월 열끗) - 현재 열끗 점수 상황에 따라 쌍피/열끗 선택
//  5. selectWave      : 흔들기 - 손패와 게임 상황을 보고 흔들기 여부 결정
//  ─────────────────────────────────────────────────────────────────────────────

import Foundation

final class ClaudeAIEngine: AIEngine {
    // MARK: - 1. 손패 카드 선택 (핵심 전략)
    /// AI가 낼 손패 카드를 선택한다.
    /// 우선순위: ① 폭발 가능(3장 같은 달) ② 매칭 있는 카드 중 EV 최대 ③ 매칭 없는 카드 중 버리기 최적
    func selectHandCard(gameData: GameData, playerIndex: Int) -> Card {
        let player = gameData.players[playerIndex]
        let hand = player.handCards.filter { $0.month != 100 } // 빈 카드 제외
        guard !hand.isEmpty else { return player.handCards[0] }

        let tableGroups = groupByMonth(gameData.allTableCards)
        let opponents = opponents(gameData: gameData, of: playerIndex)

        // ① 폭탄 가능 여부 체크 (손에 3장 + 테이블 1장)
        for card in hand {
            let sameInHand = hand.filter { $0.month == card.month }
            let sameOnTable = tableGroups[card.month] ?? []
            if sameInHand.count >= 3 && sameOnTable.count == 1 {
                return card // 폭탄 → 바로 선택
            }
        }

        // ② 매칭 있는 카드 평가
        let matchingCandidates = hand.filter { card in
            let onTable = tableGroups[card.month] ?? []
            return !onTable.isEmpty
        }

        if !matchingCandidates.isEmpty {
            // 각 카드의 포획 가치 = 내가 가져올 카드 가치 - 상대방 차단 가치
            let best = matchingCandidates.max { a, b in
                captureValue(handCard: a, tableGroups: tableGroups, player: player, opponents: opponents)
                < captureValue(handCard: b, tableGroups: tableGroups, player: player, opponents: opponents)
            }!
            return best
        }

        // ③ 매칭 없는 카드: 상대에게 유리한 달을 피하고, 가치 낮은 카드 버리기
        let discardBest = hand.min { a, b in
            discardCost(card: a, player: player, opponents: opponents, tableGroups: tableGroups)
            < discardCost(card: b, player: player, opponents: opponents, tableGroups: tableGroups)
        }!
        return discardBest
    }

    // MARK: - 2. 고/스톱 결정
    /// 고를 할지 스톱을 할지 결정한다.
    /// subtotalScore(실제 배율까지 반영된 최종 점수)를 기준으로 나와 상대의 "진짜 위협도"를 비교해
    /// 압도적으로 유리할 때는 배율 급증 구간까지도 공격적으로 돌파한다.
    func selectGoOrStop(gameData: GameData, playerIndex: Int) -> Bool {
        let player = gameData.players[playerIndex]
        let opponents = opponents(gameData: gameData, of: playerIndex)
        let remainingCards = player.handCards.count

        // 막장: 낼 패가 없으면 무조건 스톱
        if remainingCards == 0 { return false }

        let currentSubtotal = player.subtotalScore
        let maxOpponentSubtotal = opponents.map { $0.subtotalScore }.max() ?? 0

        // 3고부터는 고를 할 때마다 배율이 즉시 2배로 뛴다 (goCount>2 → 2^(goCount-2))
        // 이번 고로 그 "배율 급증 구간"에 새로 진입하는지 확인
        let nextGoCount = player.goCount + 1
        let currentMultiplier = player.goCount > 2 ? Int(pow(2, Double(player.goCount - 2))) : 1
        let projectedMultiplier = nextGoCount > 2 ? Int(pow(2, Double(nextGoCount - 2))) : 1
        let entersHighRiskZone = projectedMultiplier > currentMultiplier

        // 압도적 우위: 내가 상대 최고 위협 대비 3배 이상 & 최소 5점 이상 확보 중이면
        // 배율 급증 구간도 공격적으로 돌파한다 (독박 당해도 손해가 상대적으로 작음)
        let hugeLead = currentSubtotal >= maxOpponentSubtotal * 3 && currentSubtotal >= 5

        // 이미 점수가 매우 크면(12점=피박/광박 없이도 사실상 승부 끝) 압도적 우위가 아닌 이상 확정 짓는다
        if currentSubtotal >= 12 && !hugeLead { return false }

        // 배율 급증 구간 진입은 확실한 우위가 아니면 피한다 (공격적이되 무모하지 않게)
        if entersHighRiskZone && !hugeLead { return false }

        // 패가 얼마 안 남았는데 상대가 이미 나보다 위협적이면 더 끌 이유가 없다
        if remainingCards <= 2 && maxOpponentSubtotal >= currentSubtotal { return false }

        // ── 여기부터는 공격적으로 고를 유도하는 조건들 ──

        // 상대 전원이 사실상 무방비(subtotal 1 이하) 상태라면 최대한 점수를 불린다
        if maxOpponentSubtotal <= 1 && remainingCards >= 2 {
            return true
        }

        // 내가 이미 앞서 있고 패가 3장 이상 남았다면 격차를 더 벌린다
        if currentSubtotal > maxOpponentSubtotal && remainingCards >= 3 {
            return true
        }

        // 고도리/단/광 완성이 1장 남은 경우, 확장 여지가 있으면 계속 노린다
        if isOneAwayFromBonus(player: player, tableCards: gameData.allTableCards) && remainingCards >= 2 {
            return true
        }

        // 열끗 6장 보유 중이라면 몽땅구리(7장, 최종 점수 x2) 완성을 노리고 공격적으로 고
        if player.yeolCount == 6 && remainingCards >= 2 {
            return true
        }

        // 근소하게 뒤지거나 동률이어도 패가 충분히 남았다면 역전을 시도한다
        if remainingCards >= 4 && currentSubtotal >= maxOpponentSubtotal - 2 {
            return true
        }

        return false
    }

    // MARK: - 3. 테이블 카드 2장 중 선택
    /// 매칭 카드가 2장일 때 가져갈 카드를 선택한다.
    func selectCard(gameData: GameData, playerIndex: Int, deckOrHandCard: Card, tableCards: [Card]) -> Card {
        guard tableCards.count >= 2 else { return tableCards.last! }

        let player = gameData.players[playerIndex]
        let opponents = opponents(gameData: gameData, of: playerIndex)

        let scores = tableCards.map { card in
            (card: card, value: singleCardValue(card: card, player: player, opponents: opponents))
        }
        return scores.max { $0.value < $1.value }!.card
    }

    // MARK: - 4. 국진 선택 (쌍피 vs 열끗)
    /// 9월 열끗(국진)을 쌍피로 가져갈지, 열끗으로 가져갈지 결정한다.
    /// true = 쌍피, false = 열끗
    func selectGukjin(gameData: GameData, playerIndex: Int) -> Bool {
        let player = gameData.players[playerIndex]

        // 열끗 6장째라면 국진을 반드시 열끗으로 가져가 몽땅구리(7장, subtotalScore x2) 완성
        if player.yeolCount == 6 {
            return false // 열끗 선택
        }

        // 열끗이 4개 이상이면 열끗으로 가져가는 게 더 유리 (5개부터 1점, 몽땅구리로 가는 발판)
        if player.yeolCount >= 4 {
            return false // 열끗 선택
        }

        // 피가 8개 이상이면 쌍피 선택 (10개부터 점수)
        if player.piCount >= 8 {
            return true // 쌍피 선택
        }

        // 열끗 점수가 이미 나고 있으면 열끗 유지
        if player.yeolScore > 0 {
            return false
        }

        // 고도리 완성이 가능하면 열끗 선택 (국진은 고도리 카드가 아니지만 열끗 수 증가)
        if player.godoriCount >= 2 && player.yeolCount < 5 {
            return false
        }

        // 기본은 쌍피 (피는 안정적인 점수원)
        return true
    }

    // MARK: - 5. 흔들기 선택
    /// 손에 같은 달 3장이 있을 때 흔들기를 할지 결정한다.
    /// true = 흔들기
    func selectWave(gameData: GameData, playerIndex: Int, cards: [Card]) -> Bool {
        let player = gameData.players[playerIndex]
        let opponents = opponents(gameData: gameData, of: playerIndex)

        // 이미 흔들기를 한 적 있으면 다시 하면 배율 x4(2^waveCount) → 과도한 리스크
        if player.waveCount >= 1 { return false }

        // 흔들기는 "내가 승자가 됐을 때" 내 subtotalScore에만 배율로 붙는 옵션이므로
        // 패배 시 추가 손해가 없다 → 상대가 압도적으로 강할 때가 아니면 공격적으로 흔든다
        let maxOpponentSubtotal = opponents.map { $0.subtotalScore }.max() ?? 0

        // 상대가 이미 크게 앞서 있어 흔들기로 정보(같은 달 3장 보유)를 노출하는 게
        // 손패 운영상 손해가 클 만한 상황에서만 예외적으로 자제한다
        if maxOpponentSubtotal >= 7 { return false }

        return true
    }
}

// MARK: - Private Helpers
private extension ClaudeAIEngine {

    // 상대방 플레이어 배열
    func opponents(gameData: GameData, of playerIndex: Int) -> [Player] {
        gameData.players.filter { $0.index != playerIndex }
    }

    // 카드 배열을 월별로 그룹핑
    func groupByMonth(_ cards: [Card]) -> [Int: [Card]] {
        Dictionary(grouping: cards, by: { $0.month })
    }

    // MARK: 카드 개별 가치 점수
    /// 카드 한 장의 절대 가치를 반환한다.
    /// 광 > 고도리/단 완성 기여 > 열끗 > 띠 > 쌍피 > 피
    func singleCardValue(card: Card, player: Player, opponents: [Player]) -> Double {
        var value: Double = 0

        switch card.type {
        case .gwang:
            value = 100
            // 이미 광이 2개 있으면 3광 완성 가치 폭발
            if player.gwangCount == 2 { value = 200 }
            if player.gwangCount >= 3 { value = 50 } // 이미 3광이면 추가 가치 낮음

        case .yeol:
            value = 30
            // 고도리 완성 기여
            if card.isGodori {
                value += Double(player.godoriCount) * 40  // 고도리 2개째가 되면 매우 중요
            }
            // 열끗 수에 따라 가치 증가
            value += Double(player.yeolCount) * 5
            // 몽땅구리(열끗 7장, subtotalScore 전체 x2) 완성 직전이면 가치 폭증
            if player.yeolCount == 6 {
                value += 200
            }

        case .tti:
            value = 20
            // 청단 완성 기여
            if card.isChungDan {
                value += Double(player.chungdanCount) * 30
            }
            // 홍단 완성 기여
            if card.isHongDan {
                value += Double(player.hongdanCount) * 30
            }
            // 초단 완성 기여
            if card.isChoDan {
                value += Double(player.chodanCount) * 30
            }

        case .pi:
            value = card.isDoublePi ? 14 : 7
            // 피가 9개 이상이면 추가 피의 가치 급상승 (10개부터 1점)
            if player.piCount >= 9 { value += 20 }
        }

        // 상대방이 가져가면 안 되는 카드에 추가 가중치 (차단 가치)
        value += blockingValue(card: card, opponents: opponents)

        return value
    }

    // MARK: 포획 가치 (손패 → 테이블 카드 가져오기)
    /// 손패 카드를 낼 때 테이블에서 가져올 카드들의 총 가치
    func captureValue(handCard: Card, tableGroups: [Int: [Card]], player: Player, opponents: [Player]) -> Double {
        let matchingTableCards = tableGroups[handCard.month] ?? []
        guard !matchingTableCards.isEmpty else { return -999 }

        // 가져올 카드들의 가치 합산
        let tableGain = matchingTableCards.map {
            singleCardValue(card: $0, player: player, opponents: opponents)
        }.max() ?? 0  // 2장 매칭이면 더 좋은 것만 가져옴

        // 손패 카드 자체의 가치 (광/고도리 카드면 더 가치 있음)
        let handCardValue = singleCardValue(card: handCard, player: player, opponents: opponents)

        // 쪽 가능성 보너스: 다음 덱 카드가 같은 달이면 쪽이 될 수 있음
        // (덱 정보는 없으므로 테이블에 같은 달이 있으면 약간의 보너스)
        let kissBonus: Double = matchingTableCards.count == 1 ? 5 : 0

        return tableGain + handCardValue * 0.3 + kissBonus
    }

    // MARK: 버리기 비용 (매칭 없을 때)
    /// 매칭 없이 버릴 카드를 고를 때 비용이 낮은(= 손해가 적은) 카드를 선택
    func discardCost(card: Card, player: Player, opponents: [Player], tableGroups: [Int: [Card]]) -> Double {
        var cost: Double = 0

        // 광/고도리는 절대 버리지 않기
        if card.type == .gwang { cost += 1000 }
        if card.isGodori && player.godoriCount >= 1 { cost += 500 }

        // 완성 1장 남은 단/고도리는 버리지 않기
        if (card.isChungDan && player.chungdanCount == 2) ||
           (card.isHongDan && player.hongdanCount == 2) ||
           (card.isChoDan && player.chodanCount == 2) {
            cost += 300
        }

        // 열끗은 점수에 기여하므로 웬만하면 버리지 않기
        if card.type == .yeol { cost += 50 }
        // 열끗 6장째(몽땅구리 1장 전)라면 어떤 열끗도 사실상 버리면 안 됨
        if card.type == .yeol && player.yeolCount == 6 { cost += 400 }

        // 상대방이 갖고 있는 달의 카드는 버리면 위험 (상대에게 유리)
        cost += blockingValue(card: card, opponents: opponents) * 2

        // 띠는 중간 비용
        if card.type == .tti { cost += 20 }

        // 피는 낮은 비용 (버려도 됨)
        if card.type == .pi { cost += card.isDoublePi ? 10 : 5 }

        return cost
    }

    // MARK: 차단 가치 (상대방이 가져가면 손해인 정도)
    /// 이 카드를 상대방이 가져갔을 때의 위협 수준
    func blockingValue(card: Card, opponents: [Player]) -> Double {
        var value: Double = 0

        for opp in opponents {
            // 상대가 이미 쌓아둔 subtotalScore(고/흔들기 배율까지 반영된 실제 위협도)가 클수록
            // 그 상대를 막는 행위의 가치도 함께 커진다 → 앞서가는 상대를 공격적으로 더 세게 견제
            let threatMultiplier = 1.0 + Double(opp.subtotalScore) * 0.15

            switch card.type {
            case .gwang:
                // 상대방이 광 2개 이상 가지면 위협
                if opp.gwangCount >= 2 { value += 80 * threatMultiplier }

            case .yeol:
                // 상대방 고도리 완성 차단
                if card.isGodori && opp.godoriCount >= 2 { value += 150 * threatMultiplier }
                if opp.yeolCount >= 4 { value += 30 * threatMultiplier }
                // 상대가 열끗 6장째(몽땅구리 1장 전)라면 반드시 차단
                if opp.yeolCount == 6 { value += 250 * threatMultiplier }

            case .tti:
                // 상대방 단 완성 차단
                if card.isChungDan && opp.chungdanCount >= 2 { value += 100 * threatMultiplier }
                if card.isHongDan && opp.hongdanCount >= 2 { value += 100 * threatMultiplier }
                if card.isChoDan && opp.chodanCount >= 2 { value += 100 * threatMultiplier }

            case .pi:
                // 피는 상대방 차단 가치 낮음
                if opp.piCount >= 9 { value += 15 * threatMultiplier }
            }
        }
        return value
    }

    // MARK: 보너스 1장 남은 체크
    /// 고도리/청단/홍단/초단 중 1장만 더 있으면 완성되는 상황인지 확인
    func isOneAwayFromBonus(player: Player, tableCards: [Card]) -> Bool {
        // 고도리: 2개 보유 중
        if player.godoriCount == 2 { return true }
        // 청단: 2개 보유 중
        if player.chungdanCount == 2 { return true }
        // 홍단: 2개 보유 중
        if player.hongdanCount == 2 { return true }
        // 초단: 2개 보유 중
        if player.chodanCount == 2 { return true }
        // 3광: 2개 보유 중
        if player.gwangCount == 2 { return true }
        return false
    }
}
