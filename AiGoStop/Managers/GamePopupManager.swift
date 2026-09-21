//
//  GamePopupManager.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 5/29/26.
//

import SwiftUI

enum EventType {
    case chongtongWin       // 총통 승리
    case winner             // 승리
    case bustedPlayer       // 오링(돈없음)
    case newPlayerJoins     // 새로운 플레이어 참가
    case nagari             // 나가리
    case fourTableCards     // 바닥패 4장
    case tadak             // 따닥
    case firstTadak         // 첫따닥
    case selectCard         // 카드 선택
    case selectWave         // 흔들기 선택
    case selectGoOrStop     // 고, 스톱 선택
    case selectGukjin       // 국진 선택
    case threeTableCards    // 한번에 3장 가져오기
    case threeTableCardsWithPlayerFuck // 자뻑 (한번에 3장 가져오기)
    case go                 // 고
    case stop               // 스톱
    case wave               // 흔들기
    case bomb               // 폭탄
    case kiss               // 쪽
    case ssl                // 쓸
    case deckBonus          // 보너스 득
    case handBonus          // 손에 있는 보너스 카드
    case fuck               // 기본 뻑
    case firstFuck          // 첫 뻑
    case secondFuck         // 두번째 뻑 (첫뻑후)
    case thirdFuckWin       // 세번 뻑승
}
class GamePopupManager {
    static var shared = GamePopupManager()
    
    func showPopup(popupData: GamePopupData, type: EventType, cards: [Card], players: [Player], message: String? = nil, completion: @escaping (Int) -> Void) {
        
        popupData.cards = cards
        popupData.players = players
        popupData.completion = completion
        popupData.type = .none // 이미 팝업이 떠 있는 경우 닫아야함

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            print("\(#function) event type: \(type)")
            switch type {
            case .chongtongWin:
                popupData.title = String(localized: "POPUP_CHONGTONG_WIN_TITLE")
                popupData.message = String(localized: "POPUP_CHONGTONG_WIN_MESSAGE")
                popupData.type = .specialWinner
            case .winner:
                popupData.title = String(localized: "POPUP_WINNER_TITLE")
                popupData.message = message ?? String(localized: "POPUP_WINNER_MESSAGE_DEFAULT")
                popupData.type = .winner
            case .bustedPlayer:
                popupData.title = String(localized: "POPUP_BUSTED_TITLE")
                popupData.message = message ?? String(localized: "POPUP_BUSTED_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .angry
            case .newPlayerJoins:
                popupData.title = String(localized: "POPUP_NEW_PLAYER_TITLE")
                popupData.message = message ?? String(localized: "POPUP_NEW_PLAYER_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .nagari:
                popupData.title = String(localized: "POPUP_NAGARI_TITLE")
                popupData.message = message ?? String(localized: "POPUP_NAGARI_MESSAGE")
                popupData.button1Text = String(localized: "CONFIRM_BUTTON")
                popupData.type = .message
            case .fourTableCards:
                popupData.title = String(localized: "POPUP_FOUR_TABLE_CARDS_TITLE")
                popupData.message = message ?? String(localized: "POPUP_FOUR_TABLE_CARDS_MESSAGE")
                popupData.button1Text = String(localized: "CONFIRM_BUTTON")
                popupData.type = .message
            case .thirdFuckWin:
                popupData.title = String(localized: "POPUP_THIRD_FUCK_WIN_TITLE")
                popupData.message = String(localized: "POPUP_THIRD_FUCK_WIN_MESSAGE")
                popupData.type = .specialWinner
            case .selectCard:
                popupData.title = String(localized: "POPUP_SELECT_CARD_TITLE")
                popupData.message = String(localized: "POPUP_SELECT_CARD_MESSAGE")
                popupData.type = .selectCard
            case .kiss:
                popupData.title = String(localized: "POPUP_KISS_TITLE")
                popupData.message = String(localized: "POPUP_KISS_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .ssl:
                popupData.title = String(localized: "POPUP_SSL_TITLE")
                popupData.message = String(localized: "POPUP_SSL_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .bomb:
                popupData.title = String(localized: "POPUP_BOMB_TITLE")
                popupData.message = String(localized: "POPUP_BOMB_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .selectWave:
                popupData.title = String(localized: "POPUP_WAVE_SELECT_TITLE")
                popupData.message = String(localized: "POPUP_WAVE_SELECT_MESSAGE")
                popupData.type = .selectButton
                popupData.button1Text = String(localized: "POPUP_WAVE_BUTTON")
                popupData.button2Text = String(localized: "POPUP_JUST_PLAY")
            case .selectGoOrStop:
                popupData.title = String(localized: "POPUP_GO_OR_STOP_TITLE")
                popupData.message = String(localized: "POPUP_GO_OR_STOP_MESSAGE")
                popupData.type = .selectButton
                popupData.button1Text = String(localized: "POPUP_GO_BUTTON")
                popupData.button2Text = String(localized: "POPUP_GO_STOP_BUTTON")
            case .selectGukjin:
                popupData.title = String(localized: "POPUP_GUKJIN_TITLE")
                popupData.message = String(localized: "POPUP_GUKJIN_MESSAGE")
                popupData.type = .selectButton
                popupData.button1Text = String(localized: "POPUP_GUKJIN_DOUBLE_JUNK")
                popupData.button2Text = String(localized: "POPUP_GUKJIN_YEOLKKEUT")
            case .wave:
                popupData.title = String(localized: "POPUP_WAVE_TITLE")
                popupData.message = String(localized: "POPUP_WAVE_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .fuck:
                popupData.title = String(localized: "POPUP_FUCK_TITLE")
                popupData.message = String(localized: "POPUP_FUCK_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .angry
            case .deckBonus:
                popupData.title = String(localized: "POPUP_DECK_BONUS_TITLE")
                popupData.message = String(localized: "POPUP_DECK_BONUS_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .handBonus:
                popupData.title = String(localized: "POPUP_HAND_BONUS_TITLE")
                popupData.message = String(localized: "POPUP_HAND_BONUS_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .firstFuck:
                popupData.title = String(localized: "POPUP_FIRST_FUCK_TITLE")
                popupData.message = String(localized: "POPUP_FIRST_FUCK_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .secondFuck:
                popupData.title = String(localized: "POPUP_SECOND_FUCK_TITLE")
                popupData.message = String(localized: "POPUP_SECOND_FUCK_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .tadak:
                popupData.title = String(localized: "POPUP_TADAK_TITLE")
                popupData.message = String(localized: "POPUP_TADAK_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .firstTadak:
                popupData.title = String(localized: "POPUP_FIRST_TADAK_TITLE")
                popupData.message = String(localized: "POPUP_FIRST_TADAK_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .threeTableCards:
                popupData.title = String(localized: "POPUP_SANGQ_TITLE")
                popupData.message = String(localized: "POPUP_SANGQ_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .threeTableCardsWithPlayerFuck:
                popupData.title = String(localized: "POPUP_JAPPOK_TITLE")
                popupData.message = String(localized: "POPUP_JAPPOK_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .go:
                popupData.title = message
                popupData.message = String(localized: "POPUP_GO_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            case .stop:
                popupData.title = String(localized: "POPUP_STOP_TITLE")
                popupData.message = String(localized: "POPUP_STOP_MESSAGE")
                popupData.type = .autoCloseMessage
                popupData.playerEmotion = .happy
            }
        }
    }
}
