//
//  EmojiArtApp.swift
//  Emoji Art
//
//  Created by Nicholas Vanhaute on 7/29/24.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var defaultDocument = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: defaultDocument)
        }
    }
}
