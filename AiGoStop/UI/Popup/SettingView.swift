//
//  SettingView.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 6/11/26.
//

import SwiftUI
import SwiftData

struct SettingView: View {
    @Binding var isPresented: Bool
    @State private var sliderValue: Double = UserDefaults.standard.gameSpeed ?? 0
    @State private var isOnBackgroundSound: Bool = UserDefaults.standard.backgroundSound
    @State private var isOnEffectSound: Bool = UserDefaults.standard.effectSound
    @StateObject private var purchaseManager = PurchaseManager.shared
    
    var body: some View {
        ZStack {
//            Image(.splash)
//                .resizable()
//                .ignoresSafeArea()
//            
//            Color.black.opacity(0.5)
//                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("SETTING_TITLE")
                HStack(spacing: 10) {
                    Text("GAME_SPEED")
                        .font(.system(size: 18,weight: .regular))
                        .frame(width: 100)
                    Slider(value: $sliderValue, in: -1...1)
                }
                .frame(width: 300)
                HStack(spacing: 10) {
                    Text("BACKGROUND_MUSIC")
                        .font(.system(size: 18,weight: .regular))
                        .frame(width: 100)
                    Toggle("", isOn: $isOnBackgroundSound)
                        .onChange(of: isOnBackgroundSound) { value in
                            if value {
                                SoundManager.shared.playSoundIfPossible(type: .background, isForced: true)
                            }
                            else {
                                SoundManager.shared.stopSound(type: .background)
                            }
                            if isOnEffectSound {
                                SoundManager.shared.playSoundIfPossible(type: .click, isForced: true)
                            }
                        }
                    Spacer()
                }
                .frame(width: 300)
                HStack(spacing: 10) {
                    Text("EFFECT_SOUND")
                        .font(.system(size: 18,weight: .regular))
                        .frame(width: 100)
                    Toggle("", isOn: $isOnEffectSound)
                        .onChange(of: isOnEffectSound) { value in
                            if value {
                                SoundManager.shared.playSoundIfPossible(type: .click, isForced: true)
                            }
                        }
                    Spacer()
                }
                .frame(width: 300)
                
                HStack(spacing: 10) {
                    Text("REMOVE_ADS")
                        .font(.system(size: 18,weight: .regular))
                        .frame(width: 100)
                    if purchaseManager.isAdRemoved {
                        Text("PURCHASE_THANK_YOU")
                            .font(.system(size: 18,weight: .regular))
                            .foregroundStyle(.blue)
                    }
                    else {
                        Button("PURCHASE_PERMANENT") {
                            Task {
                                await PurchaseManager.shared.purchaseRemoveAds()
                            }
                        }
                        Text ("|")
                            .foregroundStyle(.gray)
                        Button("RESTORE_PURCHASE") {
                            Task {
                                await PurchaseManager.shared.restorePurchases()
                            }
                        }
                    }
                }
                
                HStack(spacing: 20){
                    Button("CONFIRM_BUTTON") {
                        isPresented = false
                        UserDefaults.standard.gameSpeed = sliderValue
                        UserDefaults.standard.backgroundSound = isOnBackgroundSound
                        UserDefaults.standard.effectSound = isOnEffectSound
                        SoundManager.shared.playSoundIfPossible(type: .background)
                        SoundManager.shared.playSoundIfPossible(type: .click)
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.green)
                    .clipShape(Capsule())
                    
                    Button("CANCEL_BUTTON") {
                        SoundManager.shared.playSoundIfPossible(type: .background)
                        SoundManager.shared.playSoundIfPossible(type: .click)
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(width: 150)
                    .background(.red)
                    .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(.white.opacity(0.9))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.4))
        .onAppear {
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isPresented = true
    ZStack {
        Color.tableBG
            .edgesIgnoringSafeArea(.all)
        SettingView(isPresented: $isPresented)
    }
}
