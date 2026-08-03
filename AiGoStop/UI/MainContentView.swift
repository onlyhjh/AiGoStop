//
//  MainContentView.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 5/20/26.
//

import SwiftUI
import SwiftData
import SpriteKit
import GameplayKit

struct MainContentView: View {
    @StateObject private var gameData = GameData()
    @StateObject private var popupData = PopupData()
    @State var isPresentedAlert: Bool = false
    @State var isPresentedPopup = false
    @State var isPresentedCharacterSettingPopup = false
    @State var isPresentedSettingPopup = false
    @State var alertMessage: String? = nil
    @State var popupType: String? = nil
    @State var popupStatus: PopupStatus = .closePopup
    @State var scene: GameScene? // 다시 그리기 방지
    @State var showSpriteView = false
    @State var isStarted = false
    @State var completionIndex = 0
    
    var body: some View {
        ZStack {
            Color.tableBG
                .ignoresSafeArea(.all)
            GeometryReader { geometry in
                Group {
                    if let scene, showSpriteView {
                        SpriteView(scene: scene, debugOptions: [.showsFPS, .showsNodeCount, .showsPhysics])
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    else {
                        Color.pink
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if scene == nil {
                            let newScene = GameScene(size: geometry.size, gameData: self.gameData, popupData: self.popupData, isPresentedCharacterSettingPopup: $isPresentedCharacterSettingPopup)
                            newScene.scaleMode = .aspectFit
                            scene = newScene
                        }
                        showSpriteView = true
                    }
                }
            }
            .edgesIgnoringSafeArea(.vertical)
            
            if !isStarted {
                Image(.splash)
                    .resizable()
                    .ignoresSafeArea()
                
                Button("게임 시작!") {
                    SoundManager.shared.playSoundIfPossible(type: .click)
                    self.gameData.gameStatus = .start
                    self.isStarted = true
                }
                .foregroundStyle(.white)
                .padding()
                .background(.red)
                .clipShape(Capsule())
            }
            
            HStack {
                Spacer()
                VStack(alignment: .center, spacing: 20, content: {
                    Button("⚙︎") {
                        SoundManager.shared.playSoundIfPossible(type: .click)
                        isPresentedSettingPopup = true
                    }
                    .foregroundStyle(.white)
                    .font(.largeTitle)
                    .padding()
                    Spacer()
                })
            }
            .ignoresSafeArea(.all)
            
            // Debug Test
            HStack {
                Spacer()
                VStack(alignment: .center, spacing: 20, content: {
                    Spacer()
                    Button("save") {
                        SoundManager.shared.playSoundIfPossible(type: .click)
                        if !self.gameData.origianalDeckCards.isEmpty, let encoded = try? JSONEncoder().encode(self.gameData.origianalDeckCards) {
                            UserDefaults.standard.savedGameDeckCards = encoded
                            UserDefaults.standard.savedGameWinnerIndex = self.gameData.winnerIndex
                            self.alertMessage = "save success"
                            self.isPresentedAlert = true
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.pink)
                    .clipShape(Capsule())

                    Button("load") {
                        SoundManager.shared.playSoundIfPossible(type: .click)
                        if let data = UserDefaults.standard.savedGameDeckCards, let deckCards = try? JSONDecoder().decode([Card].self, from: data) {
                            self.gameData.origianalDeckCards = deckCards
                            self.gameData.winnerIndex = UserDefaults.standard.savedGameWinnerIndex ?? 0
                            self.gameData.gameStatus = .restart
                            self.isStarted = true
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(Capsule())
                })
                .padding(.all, 10)
            }
            .ignoresSafeArea(.all)
            //.hidden()
        }
        .onAppear {
            SoundManager.shared.playSound(type: .win)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                SoundManager.shared.playSoundIfPossible(type: .background)
            }
            
            let playerFactory = PlayerFactory()
            if let user = playerFactory.loadPlayer(playerIndex: 0) {
                self.gameData.players[0] = user
                print("??? user moeny: \(user.money)")
                self.gameData.players[1] = playerFactory.loadPlayer(playerIndex: 1) ?? playerFactory.getRandomPlayer(playerIndex: 1, without: [user.characterIndex])
                self.gameData.players[2] = playerFactory.loadPlayer(playerIndex: 2) ?? playerFactory.getRandomPlayer(playerIndex: 2, without: [user.characterIndex, self.gameData.players[1].characterIndex])
            }
            else {
                self.gameData.players = playerFactory.getRandomPlayers()
                self.isPresentedCharacterSettingPopup = true
            }
        }
        .fullScreenCover(isPresented: $isPresentedCharacterSettingPopup, onDismiss: {
            if let encodedData = try? JSONEncoder().encode(self.gameData.players[0]) {
                UserDefaults.standard.user = encodedData
                self.gameData.gameStatus = .updatePlayers
            }
        }, content: {
            CharacterSettingView(isPresented: $isPresentedCharacterSettingPopup, gameData: gameData, isFirstLaunch: UserDefaults.standard.user == nil)
        })
        .fullScreenCover(isPresented: $isPresentedSettingPopup, onDismiss: {
            let gameSpeed = UserDefaults.standard.gameSpeed ?? 0.0
            self.gameData.setCardDuration(gameSpeed: gameSpeed)
            self.popupData.setAutoCloseDuration(gameSpeed: gameSpeed)
        }, content: {
            SettingView(isPresented: $isPresentedSettingPopup)
        })
        .fullScreenCover(isPresented: $isPresentedPopup, onDismiss: {
            self.popupData.status = .closePopup
            self.popupData.completion(self.completionIndex)
        }, content: {
            switch self.popupData.status  {
            case .showSelectCardPopup:
                SelectCardsView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, buttonActions: [
                    {}, // 첫번째 카드는 이벤트 없음
                    {
                        isPresentedPopup = false
                        self.popupData.cards = [self.popupData.cards[0], self.popupData.cards[1]]
                        self.completionIndex = 0
                    }, {
                        isPresentedPopup = false
                        self.popupData.cards = [self.popupData.cards[0], self.popupData.cards[2]]
                        self.completionIndex = 1
                    }
                ], closeAction: {
                    isPresentedPopup = false
                })
            case .showSelectButtonPopup:
                SelectButtonView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, button1Text: self.popupData.button1Text, button2Text: self.popupData.button2Text, button1Action: {
                    isPresentedPopup = false
                    self.completionIndex = 0
                }, button2Action : {
                    isPresentedPopup = false
                    self.completionIndex = 1
                })
            case .showAutoCloseMessagePopup:
                AutoCloseMessageView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players,cards: self.popupData.cards)
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.popupData.autoCloseDuration) {
                            isPresentedPopup = false
                            self.completionIndex = 0
                        }
                    }
            case .showMessagePopup:
                MessageView(title: self.popupData.title, message: self.popupData.message, buttonText: self.popupData.button1Text, buttonAction: {
                    isPresentedPopup = false
                    self.completionIndex = 0
                })
            case .showWinnerPopup:
                WinnerView(players: self.popupData.players, closeAction: {
                    isPresentedPopup = false
                    self.completionIndex = 0
                })
            case .showSpecialWinnerPopup:
                SpecialWinnerView(title: self.popupData.title, message: self.popupData.message, players: self.popupData.players, cards: self.popupData.cards, closeAction: {
                    isPresentedPopup = false
                    self.completionIndex = 0
                })
            default:
                EmptyView()
            }
        })
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .alert(self.alertMessage ?? "", isPresented: self.$isPresentedAlert) {
            Button("OK") { self.isPresentedAlert = false }
        }
        .onChange(of: popupData.status) { newValue in
            print("\(#function) change popupStatus: \(newValue)")
            if self.popupStatus == newValue { return }
            self.popupStatus = newValue
            
            switch newValue {
            case .closePopup:
                self.isPresentedPopup = false
            case .showAlert:
                self.alertMessage = self.popupData.message
                self.isPresentedAlert = true
            default:
                self.isPresentedPopup = true
            }
        }
    }
}

#Preview {
    MainContentView()
}
