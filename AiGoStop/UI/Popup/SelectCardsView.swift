//
//  SelectCardsView.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct SelectCardsView: View {
    
    @State var isHidden: Bool = false
    
    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    var buttonActions: [() -> Void]
    var closeAction: (() -> Void)
    
    init(title: String?, message: String?, players: [Player], cards: [Card], buttonActions: [() -> Void], closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
        self.buttonActions = buttonActions
        self.closeAction = closeAction
    }
    
    public var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        SoundManager.shared.playSoundIfPossible(type: .click)
                        isHidden.toggle()
                    }, label: {
                        VStack {
                            Image(systemName: isHidden ? "square.and.arrow.up.fill" : "square.and.arrow.down.fill")
                            Text(isHidden ? "열기" : "닫기")
                                .font(.system(size: 18,weight: .regular))
                        }
                        .padding(20)
                        .foregroundStyle(.white)
                        .background(.black)
                        .clipShape(Circle())
                    })
                    .padding(20)
                }
                Spacer()
            }
            
            if !isHidden {
                ZStack(alignment: .topLeading) {
                    VStack {
                        Spacer().frame(height: 35)
                        HStack{
                            Spacer().frame(width: 35)
                            VStack(spacing: 10) {
                                HStack(spacing: 10) {
                                    Image(cards[0].imageName ?? Card.backImageName)
                                        .resizable()
                                        .frame(width: 50, height: 75)
                                    VStack {
                                        if let title {
                                            Text(title)
                                                .font(.system(size: 20,weight: .bold))
                                        }
                                        if let message {
                                            Text(message)
                                                .font(.system(size: 18,weight: .regular))
                                        }
                                    }
                                    
                                }
                                
                                HStack(spacing: 20) {
                                    ForEach(1..<cards.count) { index in
                                        Button {
                                            SoundManager.shared.playSoundIfPossible(type: .click)
                                            buttonActions[index]()
                                        } label: {
                                            Image(cards[index].imageName ?? Card.backImageName)
                                                .resizable()
                                                .frame(width: 50, height: 75)
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(.white.opacity(0.9))
                            .cornerRadius(20)
                        }
                    }
                    Image(players[0].imageName)
                        .resizable()
                        .frame(width: 70, height: 70)
                        .cornerRadius(35)
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: 2)
                        )
                }
            }
        }
        .presentationBackground(.black.opacity(0.4))
    }
}

#Preview {
    let players = PlayerFactory().getRandomPlayers()
    let cards = Array(DeckFactory().generateFullDeck().prefix(3))
    
    ZStack {
        Color.tableBG
            .edgesIgnoringSafeArea(.all)
        SelectCardsView(title: "카드 선택!!!", message: "이 카드로 가져올 카드를 선택하세요~ 🥸", players: players, cards: cards, buttonActions: [{}, {}, {}], closeAction: {})
    }
}
