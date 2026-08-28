//
//  InternalWebView.swift
//  AiGoStop
//
//  Created by Joey's Mac mini on 8/7/26.
//

import WebKit
import SwiftUI

public struct InternalWebView: View {
    let closeAction: () -> Void
    let url: URL
    
    init(url: URL, closeAction: @escaping () -> Void) {
        self.url = url
        self.closeAction = closeAction
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    Button("닫기") {
                        SoundManager.shared.playSoundIfPossible(type: .click)
                        self.closeAction()
                    }
                    .foregroundStyle(.green)
                }
                .backgroundStyle(.gray)
                WebViewRepresentable(url: self.url)
                    .frame(height: 300)
            }
            .padding(20)
            .background(.white.opacity(0.9))
            .cornerRadius(20)
        }
        .presentationBackground(.black.opacity(0.4))
    }
}



struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}


#Preview {
    ZStack {
        Color.tableBG
            .edgesIgnoringSafeArea(.all)
        MessageView(title:  "뻑 3번!!!", message: "웃프게 이겼네.. 3만냥 주삼~ 😂", buttonText: "확인", buttonAction: {})
    }
}
