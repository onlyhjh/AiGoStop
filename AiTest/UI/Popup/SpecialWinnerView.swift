//
//  SpecialWinnerView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct SpecialWinnerView: View {

    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    var closeAction: () -> Void = { }
    
    // 😎 😭 🥶😱🤯😭😘🤩💀
    init(title: String?, message: String?, players: [Player], cards: [Card], closeAction: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
        self.closeAction = closeAction
    }
    
    public var body: some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                VStack {
                    Spacer().frame(height: 35)
                    HStack{
                        Spacer().frame(width: 35)
                        VStack(spacing: 10) {
                            if let title {
                                Text(title)
                                    .font(.system(size: 20,weight: .bold))
                            }
                            if let message {
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
                                Button("확인") {
                                    closeAction()
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
        .presentationBackground(.black.opacity(0.4))
    }
}

#Preview {
    let players = PlayerFactory().getRandomPlayers()
    let cards = Array(DeckFactory().generateFullDeck().prefix(4))
    
    ZStack {
        Color.tableBG
            .edgesIgnoringSafeArea(.all)
        SpecialWinnerView(title:  "총통 승!!!", message: "10만냥씩 주세요~ 🥳", players: players, cards: cards, closeAction: {})
    }
}
