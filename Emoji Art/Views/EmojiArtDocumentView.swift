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
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            HStack {
                PaletteChooser()
                    .font(.system(size: Constants.paletteEmojiSize))
                    .padding(.horizontal)
                    .scrollIndicators(.hidden)
                AnimatedActionButton("Delete", systemImage: "trash.fill", role: .destructive) {
                    selectedEmojis.forEach {
                        document.removeEmoji(withId: $0)
                        selectedEmojis.remove($0)
                    }
                }
                .disabled(selectedEmojis.isEmpty)
                .font(.system(size: Constants.deleteButtonFontSize))
                .padding(15)
            }
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .onTapGesture {
                        selectedEmojis = []
                    }
                if document.background.isFetching {
                    ProgressView()
                        .scaleEffect(2)
                        .tint(.blue)
                        .position(Emoji.Position.zero.in(geometry))
                }
                documentContents(in: geometry)
                    .scaleEffect(zoom * (selectedEmojis.isEmpty ? gestureZoom : 1))
                    .offset(pan + gesturePan)
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .onTapGesture(count: 2) {
                zoomToFit(document.bbox, in: geometry)
                print("Called double tap")
            }
            .dropDestination(for: Sturldata.self) { sturldata, location in
                return drop(sturldata, at: location, in: geometry)
            }
            .onChange(of: document.background.failureReason) { _, reason in
                showBackgroundFailureAlert = reason != nil
            }
            .onChange(of: document.background.uiImage) { _, uiImage in
                zoomToFit(uiImage?.size, in: geometry)
            }
            .alert(
                "Set Background",
                isPresented: $showBackgroundFailureAlert,
                presenting: document.background.failureReason,
                actions: { _ in Button("OK", role: .cancel) {}},
                message: { reason in Text(reason) })
        }
    }
    
    private func zoomToFit(_ size: CGSize?, in geometry: GeometryProxy) {
        if let size {
            zoomToFit(CGRect(center: .zero, size: size), in: geometry)
        }
    }
    
    private func zoomToFit(_ rect: CGRect, in geometry: GeometryProxy) {
        withAnimation {
            if rect.size.width > 0, rect.size.height > 0,
               geometry.size.width > 0, geometry.size.height > 0 {
                let hZoom = geometry.size.width / rect.size.width
                let vZoom = geometry.size.height / rect.size.height
                zoom = min(hZoom, vZoom)
                pan = CGOffset(
                    width: -rect.midX * zoom,
                    height: -rect.midY * zoom
                )
            }
        }
    }
    
    @State private var zoom: CGFloat = 1
    @State private var pan: CGOffset = .zero
    
    @State private var showBackgroundFailureAlert = false
    
    @GestureState private var gestureZoom: CGFloat = 1
    @GestureState private var gesturePan: CGOffset = .zero
    
    @State private var selectedEmojis: Set<Emoji.ID> = []
    
    @GestureState private var gestureDragSelection: CGOffset = .zero
    @GestureState private var gestureDragUnselected: UnselectedDragState = .init()
    
    private struct UnselectedDragState {
        var emojiId: Emoji.ID?
        var offset: CGOffset = .zero
    }
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { inMotionPinchScale, gestureZoom, _ in
                gestureZoom = inMotionPinchScale
            }
            .onEnded { endingPinchScale in
                if selectedEmojis.isEmpty {
                    zoom *= endingPinchScale
                } else {
                    selectedEmojis.forEach { document.resize(emojiWithId: $0, by: endingPinchScale) }
                }
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { inMotionDragPosition, gesturePan, _ in
                gesturePan = inMotionDragPosition.translation
            }
            .onEnded { endingDragPosition in
                pan += endingDragPosition.translation
            }
    }
    
    private var dragSelectionGesture: some Gesture {
        DragGesture()
            .updating($gestureDragSelection) { inMotionDragPosition, gestureDragSelection, _ in
                gestureDragSelection = inMotionDragPosition.translation
            }
            .onEnded { endingDragPosition in
                selectedEmojis.forEach { document.move(emojiWithId: $0, by: endingDragPosition.translation) }
            }
    }
    
    private func dragUnselectedGesture(emojiId: Emoji.ID) -> some Gesture {
        DragGesture()
            .updating($gestureDragUnselected) { inMotionDragPosition, gestureDragUnselected, _ in
                gestureDragUnselected.emojiId = emojiId
                gestureDragUnselected.offset = inMotionDragPosition.translation
            }
            .onEnded { endingDragPosition in
                document.move(emojiWithId: emojiId, by: endingDragPosition.translation)
            }
    }
    
    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        if let uiImage = document.background.uiImage {
            Image(uiImage: uiImage)
                .position(Emoji.Position.zero.in(geometry))
                .onTapGesture {
                    selectedEmojis = []
                }
        }
        ForEach(document.emojis) { emoji in
            emojiView(from: emoji, in: geometry)
        }
    }
    
    @ViewBuilder
    private func emojiView(from emoji: Emoji, in geometry: GeometryProxy) -> some View {
        let isSelected = selectedEmojis.contains(emoji.id)
        let isUnselectedAndDragged = !isSelected && gestureDragUnselected.emojiId != nil && gestureDragUnselected.emojiId! == emoji.id
        Text(emoji.string)
            .font(emoji.font)
            .border(.green, width: isSelected ? Constants.selectionBorderWidth / gestureZoom : 0)
            .scaleEffect(isSelected ? gestureZoom : 1)
            .position(emoji.position.in(geometry))
            .offset(isSelected ? gestureDragSelection : .zero)
            .offset(isUnselectedAndDragged ? gestureDragUnselected.offset : .zero)
            .onTapGesture {
                if isSelected {
                    selectedEmojis.remove(emoji.id)
                } else {
                    selectedEmojis.insert(emoji.id)
                }
            }
            .gesture(isSelected ? dragSelectionGesture : nil)
            .gesture(!isSelected ? dragUnselectedGesture(emojiId: emoji.id) : nil)
    }
    
    private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sturldata in sturldatas {
            switch sturldata {
            case .url(let url):
                document.setBackground(url)
                return true
            case .string(let emoji):
                document.addEmoji(
                    emoji,
                    at: emojiPosition(at: location, in: geometry),
                    size: Constants.paletteEmojiSize / zoom
                )
                return true
            default:
                break
            }
        }
        return false
    }
    
    private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> Emoji.Position {
        let center = geometry.frame(in: .local).center
        return Emoji.Position(
            x: Int((location.x - center.x - pan.width) / zoom),
            y: Int((center.y - location.y + pan.height) / zoom))
    }
    
    private struct Constants {
        static let paletteEmojiSize: CGFloat = 80
        static let selectionBorderWidth: CGFloat = 5
        static let deleteButtonFontSize: CGFloat = 30
    }
}

#Preview {
    EmojiArtDocumentView(document: EmojiArtDocument())
        .environmentObject(PaletteStore(named: "preview"))
}
