//
//  EmojiArt.swift
//  Emoji Art
//
//  Created by Nicholas Vanhaute on 7/29/24.
//

import Foundation

struct EmojiArt: Codable {
    var background: URL?
    private(set) var emojis: [Emoji] = []
    
    func json() throws -> Data {
        let encoded = try JSONEncoder().encode(self)
        print("EmojiArt = \(String(data: encoded, encoding: .utf8) ?? "nil")")
        return encoded
    }
    
    init() {
        
    }
    
    init(json: Data) throws {
        self = try JSONDecoder().decode(EmojiArt.self, from: json)
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ emoji: String, at position: Emoji.Position, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(
            string: emoji,
            position: position,
            size: size,
            id: uniqueEmojiId
        ))
    }
    
    mutating func removeEmoji(withId id: Emoji.ID) {
        if let index = index(of: id) {
            emojis.remove(at: index)
        }
    }
    
    subscript(_ emojiId: Emoji.ID) -> Emoji? {
        if let index = index(of: emojiId) {
            return emojis[index]
        } else {
            return nil
        }
    }
    
    subscript(_ emoji: Emoji) -> Emoji {
        get {
            if let index = index(of: emoji.id) {
                return emojis[index]
            } else {
                return emoji
            }
        }
        set {
            if let index = index(of: emoji.id) {
                emojis[index] = newValue
            }
        }
    }
    
    private func index(of emojiId: Emoji.ID) -> Int? {
        emojis.firstIndex { $0.id == emojiId }
    }
    
    struct Emoji: Codable, Identifiable {
        let string: String
        var position: Position
        var size: Int
        var id: Int
        
        struct Position: Codable {
            var x: Int
            var y: Int
            
            static let zero = Position(x: 0, y: 0)
        }
    }
}
