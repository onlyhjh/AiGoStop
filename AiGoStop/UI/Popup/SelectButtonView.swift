//
//  SelectButtonView.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct SelectButtonView: View {
    
    @State var isHidden: Bool = false
    
    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    var button1Text: String
    var button2Text: String
    var button1Action: (() -> Void)
    var button2Action: (() -> Void)
    
    init(title: String?, message: String?, players: [Player], cards: [Card], button1Text: String, button2Text: String, button1Action: @escaping () -> Void, button2Action: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
        self.button1Text = button1Text
        self.button2Text = button2Text
        self.button1Action = button1Action
        self.button2Action = button2Action
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
                                if let title = title {
                                    Text(title)
                                        .font(.system(size: 20,weight: .bold))
                                }
                                if let message = message {
                                    Text(message)
                                        .font(.system(size: 18,weight: .regular))
                                }
                                HStack(spacing: 0) {
                                    ForEach(0..<cards.count) { index in
                                        Image(cards[index].imageName ?? Card.backImageName)
                                            .resizable()
                                            .frame(width: 50, height: 75)
                                            .rotationEffect(.degrees(15 * Double(index % 2 == 0 ? 1 : -1)))
                                    }
                                }
                                HStack(spacing: 20) {
                                    Button(button1Text) {
                                        SoundManager.shared.playSoundIfPossible(type: .click)
                                        button1Action()
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(width: 150)
                                    .background(.red)
                                    .clipShape(Capsule())
                                    
                                    Button(button2Text) {
                                        SoundManager.shared.playSoundIfPossible(type: .click)
                                        button2Action()
                                    }
                                    .foregroundStyle(.white)
                                    .padding()
                                    .frame(width: 150)
                                    .background(.green)
                                    .clipShape(Capsule())
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
    let cards = Array(DeckFactory().generateFullDeck().prefix(4))
    
    ZStack {
        Color.tableBG
            .edgesIgnoringSafeArea(.all)
        SelectButtonView(title: "뻑 3번!!!", message: "웃프게 이겼네.. 3만냥 주삼~ 😂", players: players, cards: cards, button1Text: "확인", button2Text: "취소",  button1Action: {}, button2Action: {})
    }
}
