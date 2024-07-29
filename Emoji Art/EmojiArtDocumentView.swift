//
//  EmojiArtDocumentView.swift
//  Emoji Art
//
//  Created by Nicholas Vanhaute on 7/29/24.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    typealias Emoji = EmojiArt.Emoji
    @ObservedObject var document: EmojiArtDocument
    
    private let emojis = "😀😃😄😁😆😅😂🤣🩴🩱🩲🩳👙👚👛👜🐶🐱🐭🐹🐰🦊🪴🎋🍃🍂🍁🍄🍄‍🟫🐚🪨🛺🚨🚔🚍🚘🚖🛞🚡🚠"
    
    private let paletteEmojiSize: CGFloat = 80
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            ScrollingEmojis(emojis)
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                AsyncImage(url: document.background)
                    .position(Emoji.Position.zero.in(geometry))
                ForEach(document.emojis) { emoji in
                    Text(emoji.string)
                        .font(emoji.font)
                        .position(emoji.position.in(geometry))
                        .draggable(emoji.string)
                }
            }
            .dropDestination(for: Sturldata.self) { sturldata, location in
                return drop(sturldata, at: location, in: geometry)
            }
        }
    }
    
    private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sturldata in sturldatas {
            switch sturldata {
            case .url(let url):
                document.setBackground(url)
                return true
            case .string(let emoji):
                document.addEmoji(emoji, at: emojiPosition(at: location, in: geometry), size: paletteEmojiSize)
                return true
            default:
                break
            }
        }
        return false
    }
    
    private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> Emoji.Position {
        let center = geometry.frame(in: .local).center
        return Emoji.Position(x: Int(location.x - center.x), y: Int(center.y - location.y))
    }
}

struct ScrollingEmojis: View {
    let emojis: [String]
    
    init(_ emojis: String) {
        self.emojis = emojis.uniqued.map(String.init)
    }
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .draggable(emoji)
                }
            }
        }
    }
}

#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
}
