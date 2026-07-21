//
//  SoundManager.swift
//  AiTest
//
//  Created by Joey's Mac mini on 7/8/26.
//

import AVKit

enum SoundType: String{
    case coinClink = "coin_clink"   // 코인 부딪히는 소리
    case kiss = "kiss"              // 쪽
    case matching = "matching"      // 카드 매칭
    case ssl = "ssl"                // 쓸
    case fuck = "fuck"              // 기본 뻑
    case click = "click"            // 클릭
    case noMatching = "no_matching" // 매칭 카드 없음
    case bomb = "bomb"              // 폭탄
    case tadak = "tadak"            // 따닥
    case wave = "wave"              // 흔들기
    case deckBonus = "deck_bonus"   // 보너스 득
    case handBonus = "hand_bonus"   // 손에 있는 보너스 카드
    case nagari = "nagari"          // 나가리
    case threeTableCards = "three_table_cards"  // 한번에 3장 가져오기
    case bustedPlayer = "busted_player"         // 오링
    case newPlayerJoins = "new_player_joins"    //
    case go = "go"                  // 고
    case win = "win"                // 승리
    case stop = "stop"              // 스톱
    case wait = "wait"              // 대기 사운드
    case background = "background"  // 배경음악
}

struct SoundResult {
    var fileName: String
    var fileExtension: String
    var numberOfLoops: Int
}

class SoundManager: NSObject, AVAudioPlayerDelegate  {
    static var shared = SoundManager()

    private var audioPlayers: [AVAudioPlayer] = []
    
    private override init() {}
    
    func playSound(type: SoundType) {
        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "mp3") else {
            print("\(#function) sound url error:\(type.rawValue)")
            return
        }
        
        // 백그라운드 음악은 한번만 재생함
        if type == .background {
            if let player = self.audioPlayers.first{ $0.url == url } {
                return
            }
        }
        
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return  }
        player.numberOfLoops = type == .background ?  -1 : 0
        player.prepareToPlay()
        player.play()
        self.audioPlayers.append(player)
    }
    
    func playSoundIfPossible(type: SoundType, isForced: Bool = false) {
        if isForced {
            self.playSound(type: type)
        }
        else {
            if type == .background {
                if UserDefaults.standard.backgroundSound {
                    self.playSound(type: type)
                }
                else {
                    self.stopSound(type: type)
                }
            }
            else {
                if UserDefaults.standard.effectSound {
                    self.playSound(type: type)
                }
                else {
                    self.stopSound(type: type)
                }
            }
        }
    }

    func stopSound(type: SoundType) {
        guard let url = Bundle.main.url(forResource: type.rawValue, withExtension: "mp3") else {
            print("\(#function) sound url error:\(type.rawValue)")
            return
        }
        
        self.audioPlayers.removeAll { $0.url == url }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.audioPlayers.removeAll { $0 == player }
    }
}
