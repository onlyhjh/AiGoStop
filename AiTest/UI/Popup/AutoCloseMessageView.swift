//
//  AutoCloseMessageView.swift.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/26/26.
//

import SwiftUI

public struct AutoCloseMessageView: View {

    var title: String?
    var message: String?
    var players: [Player]
    var cards: [Card]
    
    // 😎 😭 🥶😱🤯😭😘🤩💀
    init(title: String?, message: String?, players: [Player], cards: [Card]) {
        self.title = title
        self.message = message
        self.players = players
        self.cards = cards
    }
    
    public var body: some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                VStack {
                    Spacer().frame(height: 35)
                    HStack{
                        Spacer().frame(width: 35)
                        VStack(spacing: 10) {
                            
                            HStack(spacing: 10) {
                                
                                if let title {
                                    Text(title)
                                        .font(.system(size: 20,weight: .bold))
                                }
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
        AutoCloseMessageView(title: "뻑!!!", message: "오메 이런일이... 🤯", players: players, cards: cards)
    }
}
