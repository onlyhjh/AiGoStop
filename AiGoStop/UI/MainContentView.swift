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
import GoogleMobileAds

struct MainContentView: View {
    
    @StateObject var gameData = GameData()
    @StateObject var gamePopupData = GamePopupData()
    
    @State var appData: AppInfo?
    @State var isPresentedAppPopup = false
    @State var appPopupType: AppPopupType = .none
    
    @State var isPresentedGamePopup = false
    @State var gamePopupType: GamePopupType = .none
    
    @State var isPresentedAlert: Bool = false
    @State var alertMessage: String? = nil
    
    @State var isPresentedCharacterSettingPopup = false
    @State var isPresentedSettingPopup = false
    
    @State var scene: GameScene? // 다시 그리기 방지
    @State var isPresentedGameScene = false
    @State var isStartedGame = false
    @State var isLoadedData = false
    @State var completionIndex = 0
    
    var body: some View {
        ZStack {
            Image(.splash)
                .resizable()
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                Group {
                    if let scene, isPresentedGameScene {
                        SpriteView(scene: scene, debugOptions: [.showsFPS, .showsNodeCount, .showsPhysics])
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if scene == nil {
                            let newScene = GameScene(size: geometry.size, gameData: self.gameData, popupData: self.gamePopupData, isPresentedCharacterSettingPopup: $isPresentedCharacterSettingPopup)
                            newScene.scaleMode = .aspectFit
                            scene = newScene
                        }
                        isPresentedGameScene = true
                    }
                }
            }
            .edgesIgnoringSafeArea(.vertical)
            
            if !isStartedGame && !isLoadedData {
                Button("게임 시작!") {
                    SoundManager.shared.playSoundIfPossible(type: .click)
                    self.gameData.gameStatus = .start
                    self.isStartedGame = true
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
            /*
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
            */
        }
        .onAppear {
            SoundManager.shared.playSound(type: .win)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                SoundManager.shared.playSoundIfPossible(type: .background)
            }
            
            Task {
                // check app status
                appData = await CloudKitManager.shared.loadCloudAppData()
                self.showNextAppPopupIfNeedded(completion: { loadData() })
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
            self.gamePopupData.setAutoCloseDuration(gameSpeed: gameSpeed)
        }, content: {
            SettingView(isPresented: $isPresentedSettingPopup)
        })
        .fullScreenCover(isPresented: $isPresentedGamePopup, onDismiss: {
            self.gamePopupData.type = .none
            self.gamePopupData.completion(self.completionIndex)
        }, content: {
            switch self.gamePopupData.type  {
            case .selectCard:
                SelectCardsView(title: self.gamePopupData.title, message: self.gamePopupData.message, players: self.gamePopupData.players, cards: self.gamePopupData.cards, buttonActions: [
                    {}, // 첫번째 카드는 이벤트 없음
                    {
                        isPresentedGamePopup = false
                        self.gamePopupData.cards = [self.gamePopupData.cards[0], self.gamePopupData.cards[1]]
                        self.completionIndex = 0
                    }, {
                        isPresentedGamePopup = false
                        self.gamePopupData.cards = [self.gamePopupData.cards[0], self.gamePopupData.cards[2]]
                        self.completionIndex = 1
                    }
                ], closeAction: {
                    isPresentedGamePopup = false
                })
            case .selectButton:
                SelectButtonView(title: self.gamePopupData.title, message: self.gamePopupData.message, players: self.gamePopupData.players, cards: self.gamePopupData.cards, button1Text: self.gamePopupData.button1Text, button2Text: self.gamePopupData.button2Text, button1Action: {
                    isPresentedGamePopup = false
                    self.completionIndex = 0
                }, button2Action : {
                    isPresentedGamePopup = false
                    self.completionIndex = 1
                })
            case .autoCloseMessage:
                AutoCloseMessageView(title: self.gamePopupData.title, message: self.gamePopupData.message, players: self.gamePopupData.players,cards: self.gamePopupData.cards)
                    .onAppear{
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.gamePopupData.autoCloseDuration) {
                            isPresentedGamePopup = false
                            self.completionIndex = 0
                        }
                    }
            case .message:
                MessageView(title: self.gamePopupData.title, message: self.gamePopupData.message, buttonText: self.gamePopupData.button1Text, buttonAction: {
                    isPresentedGamePopup = false
                    self.completionIndex = 0
                })
            case .winner:
                WinnerView(players: self.gamePopupData.players, closeAction: {
                    isPresentedGamePopup = false
                    self.completionIndex = 0
                })
            case .specialWinner:
                SpecialWinnerView(title: self.gamePopupData.title, message: self.gamePopupData.message, players: self.gamePopupData.players, cards: self.gamePopupData.cards, closeAction: {
                    isPresentedGamePopup = false
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
        .fullScreenCover(isPresented: $isPresentedAppPopup, onDismiss: {
            self.appPopupType = .none
        }, content: {
            switch self.appPopupType  {
            case .maintanance:
                MessageView(title: "안내", message: appData?.maintananceText ?? "앱이 공사중입니다.\n잠시만 기다려 주세요.", buttonText: "재시도", buttonAction: {
                    self.isPresentedAppPopup = false
                    Task{
                        self.appData = await CloudKitManager.shared.loadCloudAppData()
                        self.showNextAppPopupIfNeedded(completion: { loadData() })
                    }
                })
            case .forcedUpdate:
                let url = URL(string: appData?.appstoreUrl ?? "itms-apps://itunes.apple.com")
                MessageView(title: "업데이트 안내", message: "앱이 업데이트되었습니다.\n신규 앱으로 업데이트 해 주세요.", buttonText: "스토어로 이동", buttonAction: {
                    //self.isPresentedAppPopup = false
                    if let url { UIApplication.shared.open(url) }
                })
            case .optionalUpdate:
                let url = URL(string: appData?.appstoreUrl ?? "itms-apps://itunes.apple.com")
                SelectButtonView(title: "업데이트 안내", message: "새로 업데이트 된 앱이 있습니다.\n신규 앱으로 플레이 해 볼래요?", players: [], cards: [], button1Text: "스토어로 이동", button2Text: "그냥 플레이", button1Action: {
                    //self.isPresentedAppPopup = false
                    if let url { UIApplication.shared.open(url) }
                }, button2Action: {
                    self.isPresentedAppPopup = false
                    self.showNextAppPopupIfNeedded(currentAppPopupType: .optionalUpdate, completion: { loadData() })
                })
            case .noticeWebView:
                if let noticeUrl = appData?.noticeUrl, let url = URL(string: noticeUrl) {
                    InternalWebView(url: url, closeAction: {
                        self.isPresentedAppPopup = false
                        self.showNextAppPopupIfNeedded(currentAppPopupType: .noticeWebView, completion: { loadData() })
                    })
                }
            default:
                Color.pink
            }
        })
        .onChange(of: appPopupType) { newValue in
            print("\(#function) change App Popup Type: \(newValue)")
            self.isPresentedAppPopup = newValue != .none
        }
        .onChange(of: gamePopupData.type) { newValue in
            print("\(#function) change Game Popup Type: \(newValue)")
            if gamePopupType == newValue { return }
            self.gamePopupType = newValue
            
            switch newValue {
            case .none:
                self.isPresentedGamePopup = false
            case .alert:
                self.alertMessage = self.gamePopupData.message
                self.isPresentedAlert = true
            default:
                self.isPresentedGamePopup = true
            }
        }
    }
    
    func showNextAppPopupIfNeedded(currentAppPopupType: AppPopupType? = nil, completion: () -> Void) {
        let currentPopupStep = currentAppPopupType?.rawValue ?? 0
        // 팝업 순서대로 보이도록함
        if let appData {
            if let _ = appData.maintananceText {
                self.appPopupType = .maintanance
            }
            else if appData.isForcedUpdate {
                self.appPopupType = .forcedUpdate
            }
            else if appData.isOptionalUpdate, currentPopupStep < AppPopupType.optionalUpdate.rawValue {
                self.appPopupType = .optionalUpdate
            }
            else if let _ = appData.noticeUrl, currentPopupStep < AppPopupType.noticeWebView.rawValue {
                self.appPopupType = .noticeWebView
            }
            else {
                self.appPopupType = .none
            }
        }
        else {
            self.appPopupType = .none
        }
    }
    
    func loadData() {
        // set player
        let playerFactory = PlayerFactory()
        if let user = playerFactory.loadLocalPlayerData(playerIndex: 0) {
            self.gameData.players[0] = user
            print("??? user moeny: \(user.coin)")
            self.gameData.players[1] = playerFactory.loadLocalPlayerData(playerIndex: 1) ?? playerFactory.getRandomPlayer(playerIndex: 1, without: [user.characterIndex])
            self.gameData.players[2] = playerFactory.loadLocalPlayerData(playerIndex: 2) ?? playerFactory.getRandomPlayer(playerIndex: 2, without: [user.characterIndex, self.gameData.players[1].characterIndex])
        }
        else {
            self.gameData.players = playerFactory.getRandomPlayers()
            self.isPresentedCharacterSettingPopup = true
        }
        
        isLoadedData = true
    }
}

#Preview {
    MainContentView()
}
