//
//  SoundManager.swift
//  AiTest
//
//  Created by Joey's Mac mini on 7/8/26.
//

import AVKit

enum SoundType {
    case chongtongWin       // 총통 승리
    case winner             // 승리
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
    case emptyTable         // 쓸
    case deckBonus          // 보너스 득
    case handBonus          // 손에 있는 보너스 카드
    case fuck               // 기본 뻑
    case firstFuck          // 첫 뻑
    case secondFuck         // 두번째 뻑 (첫뻑후)
    case thirdFuckWin       // 세번 뻑승
}
class SoundManager {
    static var shared = PopupManager()
    
    func playSound(type: SoundType) {
        var soundResource = ""
        
        switch type {
        case .kiss:
            soundResource = "kiss"
        default:
            return
        }
        
        guard let url = Bundle.main.url(forResource: soundResource, withExtension: "mp3") else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.play()
        } catch let error {
             print("sound 재생에 오류가 발생했습니다. \(error.localizedDescription)")
        }
    }
    
}
