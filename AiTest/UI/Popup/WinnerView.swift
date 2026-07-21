//
//  WinnerView.swift
//  AiTest
//
//  Created by Joey's Mac mini on 5/27/26.
//


import SwiftUI

public struct WinnerView: View {
    
    @State var isHidden: Bool = false
    
    var players: [Player]
    var isTest: Bool = false
    var closeAction: (() -> Void)
    var bestRecords: [Int]?

    init(players: [Player], isTest: Bool = false, closeAction: @escaping () -> Void) {
        self.players = players
        self.isTest = isTest
        self.closeAction = closeAction
        
        if isTest {
            self.bestRecords = [1000,200,0, 121]
        }
        else {
            self.bestRecords = UserDefaults.standard.bestRecords
        }
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
                VStack(spacing: 0) {
                    HStack {
                        VStack(spacing: 10) {
                            // Winner
                            VStack(spacing: 5) {
                                HStack {
                                    Image(players[0].imageName)
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .cornerRadius(35)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(.blue, lineWidth: 2)
                                        )
                                    
                                    VStack(spacing: 5) {
                                        HStack(spacing: 10) {
                                            Text(players[0].name)
                                                .font(.system(size: 20,weight: .bold))
                                                .bold()
                                            Text("승")
                                                .font(.system(size: 20,weight: .bold))
                                                .bold()
                                                .foregroundStyle(.white)
                                                .background(.pink)
                                                .clipShape(Circle())
                                        }
                                        HStack(spacing: 10) {
                                            Text("+\(players[0].finalScore)만냥")
                                                .font(.title3)
                                                .bold()
                                                .padding(7)
                                                .foregroundStyle(.white)
                                                .background(.blue)
                                                .clipShape(Capsule())
                                            Text("🥳")
                                                .font(.system(size: 30,weight: .bold))
                                        }
                                    }
                                }
                                HStack(spacing: 10) {
                                    Text(players[0].goCount > 2 ? "\(players[0].goCount)고x\(Int(pow(2.0, Double(players[0].goCount - 2))))" : "3고x2")
                                        .font(.system(size: 18,weight: .regular))
                                        .bold()
                                        .padding(5)
                                        .foregroundStyle(players[0].goCount > 2 ? .red : .white.opacity(0.5))
                                        .background(players[0].goCount > 2 ? .yellow: .gray.opacity(0.5))
                                    Text(players[0].waveCount > 0 ? "흔들기x\(Int(pow(2.0, Double(players[0].waveCount))))" : "흔들기x2")
                                        .font(.system(size: 18,weight: .regular))
                                        .bold()
                                        .padding(5)
                                        .foregroundStyle(players[0].waveCount > 0 ? .red : .white.opacity(0.5))
                                        .background(players[0].waveCount > 0 ? .yellow: .gray.opacity(0.5))
                                    Text("나가리x2")
                                        .font(.system(size: 18,weight: .regular))
                                        .bold()
                                        .padding(5)
                                        .foregroundStyle(players[0].wasNagari ? .red : .white.opacity(0.5))
                                        .background(players[0].wasNagari ? .yellow: .gray.opacity(0.5))
                                    Text("멍텅구리x2")
                                        .font(.system(size: 18,weight: .regular))
                                        .bold()
                                        .padding(5)
                                        .foregroundStyle(players[0].isMungtungguri ? .red : .white.opacity(0.5))
                                        .background(players[0].isMungtungguri ? .yellow: .gray.opacity(0.5))
                                }
                                PlayerTypeStatisticsView(isWinner: true, player: players[0])
                            }
                            // player1
                            Divider()
                            HStack(spacing: 10) {
                                HStack(spacing: 30) {
                                    // Player1
                                    VStack(spacing: 5) {
                                        HStack(spacing: 5) {
                                            Image(players[1].imageName)
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(25)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(.red, lineWidth: 2)
                                                )
                                            VStack(spacing: 0) {
                                                HStack(spacing: 5) {
                                                    Text(players[1].name)
                                                        .font(.title3)
                                                        .bold()
                                                    Text("패")
                                                        .font(.title3)
                                                        .bold()
                                                        .foregroundStyle(.white)
                                                        .background(.red)
                                                        .clipShape(Circle())
                                                    Spacer()
                                                }
                                                HStack(spacing: 5) {
                                                    if players[1].finalScore != 0 {
                                                        Text("\(-players[1].finalScore)만냥")
                                                            .font(.title3)
                                                            .bold()
                                                            .padding(5)
                                                            .foregroundStyle(.white)
                                                            .background(.red)
                                                            .clipShape(Capsule())
                                                        Text("😭")
                                                            .font(.system(size: 30,weight: .bold))
                                                    }
                                                    else {
                                                        Text("🤭")
                                                            .font(.system(size: 30,weight: .bold))
                                                    }
                                                    Spacer()
                                                }
                                            }
                                        }
                                        HStack(spacing: 10) {
                                            Text("광박x2")
                                                .font(.system(size: 18,weight: .regular))
                                                .bold()
                                                .padding(5)
                                                .foregroundStyle(players[1].isGwangBak ? .red : .white.opacity(0.5))
                                                .background(players[1].isGwangBak ? .yellow: .gray.opacity(0.5))
                                            Text("피박x2")
                                                .font(.system(size: 18,weight: .regular))
                                                .bold()
                                                .padding(5)
                                                .foregroundStyle(players[1].isPiBak ? .red : .white.opacity(0.5))
                                                .background(players[1].isPiBak ? .yellow: .gray.opacity(0.5))
                                            Text("독박")
                                                .font(.system(size: 18,weight: .regular))
                                                .bold()
                                                .padding(5)
                                                .foregroundStyle(players[1].isGoBak ? .red : .white.opacity(0.5))
                                                .background(players[1].isGoBak ? .yellow: .gray.opacity(0.5))
                                        }
                                        PlayerTypeStatisticsView(isWinner: false, player: players[1])
                                    }
                                    .frame(width: 200)
                                    
                                    // Player1
                                    VStack(spacing: 5) {
                                        HStack(spacing: 5) {
                                            Image(players[2].imageName)
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .cornerRadius(25)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(.red, lineWidth: 2)
                                                )
                                            VStack(spacing: 0) {
                                                HStack(spacing: 5) {
                                                    Text(players[2].name)
                                                        .font(.title3)
                                                        .bold()
                                                    Text("패")
                                                        .font(.title3)
                                                        .bold()
                                                        .foregroundStyle(.white)
                                                        .background(.red)
                                                        .clipShape(Circle())
                                                    Spacer()
                                                }
                                                HStack(spacing: 5) {
                                                    if players[2].finalScore != 0 {
                                                        Text("\(-players[2].finalScore)만냥")
                                                            .font(.title3)
                                                            .bold()
                                                            .padding(5)
                                                            .foregroundStyle(.white)
                                                            .background(.red)
                                                            .clipShape(Capsule())
                                                        Text("😭")
                                                            .font(.system(size: 30,weight: .bold))
                                                    }
                                                    else {
                                                        Text("🤭")
                                                            .font(.system(size: 30,weight: .bold))
                                                    }
                                                    Spacer()
                                                }
                                            }
                                        }
                                        
                                        HStack(spacing: 10) {
                                            Text("광박x2")
                                                .font(.system(size: 18,weight: .regular))
                                                .bold()
                                                .padding(5)
                                                .foregroundStyle(players[2].isGwangBak ? .red : .white.opacity(0.5))
                                                .background(players[2].isGwangBak ? .yellow: .gray.opacity(0.5))
                                            Text("피박x2")
                                                .font(.system(size: 18,weight: .regular))
                                                .bold()
                                                .padding(5)
                                                .foregroundStyle(players[2].isPiBak ? .red : .white.opacity(0.5))
                                                .background(players[2].isPiBak ? .yellow: .gray.opacity(0.5))
                                            Text("독박")
                                                .font(.system(size: 18,weight: .regular))
                                                .bold()
                                                .padding(5)
                                                .foregroundStyle(players[2].isGoBak ? .red : .white.opacity(0.5))
                                                .background(players[2].isGoBak ? .yellow: .gray.opacity(0.5))
                                        }
                                        PlayerTypeStatisticsView(isWinner: false, player: players[2])
                                    }
                                    .frame(width: 200)
                                }
                            }
                        }
                        VStack(spacing: 10) {
                            Spacer().frame(height: 20)
                            // Best Record
                            if let bestRecords, players[0].index == 0 {
                                VStack(spacing: 5) {
                                    Spacer().frame(height: 0)
                                    Text("최고 기록")
                                        .font(.headline)
                                        .bold()
                                        .foregroundColor(.white)
                                    ScrollViewReader { proxy in
                                        ScrollView{
                                            VStack(spacing: 3) {
                                                Spacer().frame(height: 0)
                                                ForEach(bestRecords.indices, id: \.self) { i in
                                                    HStack() {
                                                        Text((players[0].finalScore == bestRecords[i] ? "👉🏻" : "") + "\(i + 1)위")
                                                            .font(.system(size: 16,weight: .regular))
                                                            .bold()
                                                            .foregroundColor(.white)
                                                            .frame(width: 55)
                                                        Spacer()
                                                        Text("\(bestRecords[i])만냥")
                                                            .font(.system(size: 16,weight: .regular))
                                                            .bold()
                                                            .foregroundColor(.white)
                                                    }
                                                    .padding(.horizontal, 10)
                                                    Divider().padding(.horizontal, 10)
                                                }
                                                Spacer().frame(height: 0)
                                            }
                                        }
                                        .frame(width: 145 , height: 80)
                                        .background(.white.opacity(0.5))
                                        .onAppear {
                                            for (i, bestRecord) in bestRecords.enumerated() {
                                                if bestRecord == players[0].finalScore {
                                                    proxy.scrollTo(i, anchor: .center)
                                                }
                                            }
                                        }
                                    }
                                }
                                .background(.pink.opacity(0.8))
                                .cornerRadius(20)
                                .scrollIndicators(.hidden)
                            }
                            
                            // Score
                            VStack(spacing: 5) {
                                Spacer().frame(height: 0)
                                Text("총\(players[0].baseScore)점")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.white)
                                ScrollView {
                                    VStack(spacing: 3) {
                                        Spacer().frame(height: 0)
                                        if self.isTest || players[0].gwangScore > 0 {
                                            HStack() {
                                                Text("광")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].gwangScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].yeolScore > 0 {
                                            HStack() {
                                                Text("열")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].yeolScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].ttiScore > 0 {
                                            HStack() {
                                                Text("띠")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].ttiScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].piScore > 0 {
                                            HStack() {
                                                Text("피")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].piScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].chungdanScore > 0 {
                                            HStack() {
                                                Text("청단")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].chungdanScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].hongdanScore > 0 {
                                            HStack() {
                                                Text("홍단")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].hongdanScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].chodanScore > 0 {
                                            HStack() {
                                                Text("초단")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].chodanScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].godoriScore > 0 {
                                            HStack() {
                                                Text("고도리")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].godoriScore)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        if self.isTest || players[0].goCount > 0 {
                                            HStack() {
                                                Text("\(players[0].goCount)고")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                                    .frame(width: 55)
                                                Spacer()
                                                Text("\(players[0].goCount)점")
                                                    .font(.system(size: 16,weight: .regular))
                                                    .bold()
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            Divider().padding(.horizontal, 10)
                                        }
                                        Spacer().frame(height: 0)
                                    }
                                }
                                .frame(width: 145)
                                .background(.white.opacity(0.3))
                            }
                            .background(.green.opacity(0.9))
                            .cornerRadius(20)
                            .scrollIndicators(.hidden)
                            Spacer()
                        }
                    }
                    Button("확인") {
                        SoundManager.shared.playSoundIfPossible(type: .click)
                        closeAction()
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green)
                    .clipShape(Capsule())
                    Spacer().frame(height:10)
                } // inner frame
                .frame(width: 600, height: 380)
                .padding(.horizontal,  40)
                .background(.white.opacity(0.9))
                .cornerRadius(20)
            }
        }
        .ignoresSafeArea()
        .presentationBackground(.black.opacity(0.4))
    }
}

private struct PlayerTypeStatisticsView: View {
    var isWinner: Bool
    var player: Player
    
    var body: some View {
        HStack(spacing: 5) {
            switch player.index {
            case 1:
                Image(.cursorAI)
                    .frame(width: 20, height: 20)
                Text("cursor")
                    .font(.system(size: 14,weight: .regular))
                    .foregroundStyle(.gray)
            case 2:
                Image(.claudeAI)
                    .frame(width: 20, height: 20)
                Text("claude")
                    .font(.system(size: 14,weight: .regular))
                    .foregroundStyle(.gray)
            default:
                Text("😎 human")
                    .font(.system(size: 14,weight: .regular))
                    .foregroundStyle(.gray)
            }
            if isWinner {
                Text("승률:\(Int(player.winRate * 100))%")
                    .font(.system(size: 14,weight: .regular))
                    .foregroundStyle(.gray)
                Text("(기대수익:\(String(format: "%.2f", player.expectedProfit))만냥)")
                    .font(.system(size: 14,weight: .regular))
                    .foregroundStyle(.gray)
            }
            else {
                Text("\(Int(player.winRate * 100))%")
                    .font(.system(size: 14,weight: .regular))
                    .foregroundStyle(.gray)
                Text("(\(String(format: "%.2f", player.expectedProfit))만냥)")
                    .font(.system(size: 14,weight: .regular))
                    .foregroundStyle(.gray)
            }
        }
    }
}

#Preview {
    let players = PlayerFactory().getRandomPlayers()
    
    ZStack {
        Color.tableBG
            .edgesIgnoringSafeArea(.all)
        WinnerView(players: players, isTest: true, closeAction: {
        })
    }
}
