import Foundation
import SwiftUI
import StarOracleCore
import StarOracleFeatures

struct InspirationCardOverlay: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject var starStore: StarStore
    @EnvironmentObject private var chatBridge: NativeChatBridge
    @State private var isFlipped = false
    @State private var isAppearing = false
    @State private var dragOffset: CGSize = .zero
    @State private var isClosing = false
    
    // Card dimensions matching React (~280x400)
    private let cardWidth: CGFloat = 300
    private let cardHeight: CGFloat = 440
    
    var body: some View {
        if let card = starStore.currentInspirationCard {
            ZStack {
                // Dimmed background
                Color.black.opacity(isClosing ? 0 : 0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss(id: card.id)
                    }
                    .animation(.easeOut(duration: 0.3), value: isClosing)
                
                // Card Container
                ZStack {
                    // Front Face
                    CardFrontFace(card: card, onFlip: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isFlipped = true
                        }
                    })
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(
                            .degrees(isFlipped ? 180 : 0),
                            axis: (x: 0.0, y: 1.0, z: 0.0),
                            perspective: 0.8
                        )
                        .accessibilityHidden(isFlipped)
                    
                    // Back Face
                    CardBackFace(card: card, onFlipBack: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isFlipped = false
                        }
                    }, onSubmit: { question in
                        submit(card: card, question: question)
                    })
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0.0, y: 1.0, z: 0.0),
                        perspective: 0.8
                    )
                    .accessibilityHidden(!isFlipped)
                }
                .frame(width: cardWidth, height: cardHeight)
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width / 15)))
                .scaleEffect(isClosing ? 0.8 : (isAppearing ? 1 : 0.9))
                .opacity(isClosing ? 0 : (isAppearing ? 1 : 0))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 100
                            if abs(value.translation.width) > threshold || abs(value.velocity.width) > 500 {
                                dismiss(id: card.id, velocity: value.velocity)
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            }
            .zIndex(100)
            .overlay(alignment: .bottom) {
                if SupabaseRuntime.loadConfig() != nil, AuthSessionStore.load() != nil {
                    if !starStore.personalizedInspirationCandidates.isEmpty {
                        PersonalizedInspirationCandidatesPanel(items: starStore.personalizedInspirationCandidates)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 18)
                            .opacity(isClosing ? 0 : 1)
                            .allowsHitTesting(false)
                    } else {
                        Text("为你生成中…")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.65))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.35), in: Capsule())
                            .padding(.bottom, 18)
                            .opacity(isClosing ? 0 : 1)
                            .allowsHitTesting(false)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    isAppearing = true
                }
            }
        }
    }
    
    private func dismiss(id: String, velocity: CGSize = .zero) {
        withAnimation(.easeIn(duration: 0.25)) {
            isClosing = true
            if velocity != .zero {
                dragOffset.width += velocity.width * 0.2
                dragOffset.height += velocity.height * 0.2
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            starStore.dismissInspirationCard(id: id)
            // Reset state for next time
            isFlipped = false
            isAppearing = false
            isClosing = false
            dragOffset = .zero
        }
    }
    
    private func submit(card: InspirationCard, question: String) {
        let finalQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? card.question : question
        let (mainText, footerText) = inspirationCardMainAndFooterText(card)
        let hintText = inspirationHintText(mainText: mainText, footerText: footerText)
        let systemContext = inspirationSystemContextText(mainText: mainText, footerText: footerText)
        
        // Animate out
        withAnimation(.easeIn(duration: 0.2)) {
            isClosing = true
            dragOffset.height = -200.0
            dragOffset.width = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if SupabaseRuntime.loadConfig() != nil {
                environment.createSession(title: nil)
                let chatId = environment.conversationStore.currentSessionId
                chatBridge.addInspirationHint(chatId: chatId, cardId: card.id, text: hintText)
                starStore.dismissInspirationCard(id: card.id)
                // Reset
                isFlipped = false
                isAppearing = false
                isClosing = false
                dragOffset = .zero

                Task { @MainActor in
                    var messageToSend = finalQuestion
                    do {
                        try await ChatCreateService.ensureChatExists(chatId: chatId, title: nil)
                        try await ChatMessageInsertService.insertSystemMessage(chatId: chatId, content: systemContext)
                    } catch {
                        if StarOracleDebug.verboseLogsEnabled {
                            Foundation.NSLog("⚠️ InspirationCardOverlay | 写入灵感卡片上下文失败 err=%@", error.localizedDescription)
                        }
                        messageToSend = "\(systemContext)\n\n用户提问：\(finalQuestion)"
                    }
                    chatBridge.sendMessage(messageToSend)
                }
                return
            }

            Task {
                try? await starStore.addStar(question: finalQuestion, at: nil)
                starStore.dismissInspirationCard(id: card.id)
                // Reset
                isFlipped = false
                isAppearing = false
                isClosing = false
                dragOffset = .zero
            }
        }
    }

    private func inspirationCardMainAndFooterText(_ card: InspirationCard) -> (String, String?) {
        let contentTypeTag = card.tags.first(where: { $0.hasPrefix("content_type:") }) ?? ""
        let isQuote = contentTypeTag == "content_type:quote"

        let rawMain = (isQuote ? card.question : card.reflection).trimmingCharacters(in: .whitespacesAndNewlines)
        let mainText = rawMain.isEmpty ? "……" : rawMain

        let rawFooter = (isQuote ? card.reflection : card.question).trimmingCharacters(in: .whitespacesAndNewlines)
        let footerText: String?
        if rawFooter.isEmpty {
            footerText = nil
        } else if isQuote {
            footerText = rawFooter.hasPrefix("—") ? rawFooter : "— \(rawFooter)"
        } else {
            footerText = rawFooter
        }
        return (mainText, footerText)
    }

    private func inspirationHintText(mainText: String, footerText: String?) -> String {
        let main = mainText.trimmingCharacters(in: .whitespacesAndNewlines)
        let footer = (footerText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var lines: [String] = []
        if !main.isEmpty {
            lines.append("灵感卡片：\(main)")
        }
        if !footer.isEmpty {
            lines.append(footer)
        }
        return lines.joined(separator: "\n")
    }

    private func inspirationSystemContextText(mainText: String, footerText: String?) -> String {
        let main = mainText.trimmingCharacters(in: .whitespacesAndNewlines)
        let footer = (footerText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var lines: [String] = ["【灵感卡片】"]
        if !main.isEmpty {
            lines.append(main)
        }
        if !footer.isEmpty {
            lines.append(footer)
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Front Face
struct CardFrontFace: View {
    let card: InspirationCard
    var onFlip: () -> Void
    @State private var animateStars = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    Color(hex: "#4a1c6a"),
                    Color(hex: "#2a0f46")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Star Pattern
            GeometryReader { proxy in
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                
                // Background Stars
                ForEach(0..<12) { i in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: center.x + CGFloat.random(in: -80...80),
                            y: center.y + CGFloat.random(in: -100...100)
                        )
                        .opacity(animateStars ? 0.8 : 0.3)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.5...3.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: animateStars
                        )
                }
                
                // Main Star
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .position(center)
                    .shadow(color: .white, radius: 10)
                    .scaleEffect(animateStars ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 2).repeatForever(), value: animateStars)
                
                // Rays
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(LinearGradient(colors: [.white, .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 40, height: 2)
                        .offset(x: 20)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .position(center)
                        .opacity(animateStars ? 0.8 : 0.2)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever().delay(Double(i) * 0.1),
                            value: animateStars
                        )
                }
            }
            
            // Prompt Text
            VStack {
                Spacer()
                Text("翻开卡片，宇宙会回答你")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 40)
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color(hex: "#4a1c6a").opacity(0.5), radius: 20, x: 0, y: 10)
        .onAppear {
            animateStars = true
        }
        .contentShape(Rectangle()) // Ensure entire area is tappable
        .onTapGesture {
            onFlip()
        }
    }
}

// MARK: - Back Face
struct CardBackFace: View {
    let card: InspirationCard
    let onFlipBack: () -> Void
    let onSubmit: (String) -> Void
    
    @State private var inputText = ""
    @FocusState private var isFocused: Bool

    private var contentTypeTag: String {
        card.tags.first(where: { $0.hasPrefix("content_type:") }) ?? ""
    }

    private var isQuote: Bool {
        contentTypeTag == "content_type:quote"
    }

    private var mainText: String {
        let value = (isQuote ? card.question : card.reflection).trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty { return value }
        return "……"
    }

    private var footerText: String {
        let value = (isQuote ? card.reflection : card.question).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        if isQuote {
            return value.hasPrefix("—") ? value : "— \(value)"
        }
        return value
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A1A2E")
            
            VStack {
                // Header
                HStack {
                    Text("来自宇宙的答案")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#8A5FBD"))
                    
                    Spacer()
                    
                    Button(action: onFlipBack) {
                        Text("返回正面")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Answer
                Text(mainText)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .shadow(color: .white.opacity(0.3), radius: 8)
                
                Spacer()
                
                // Reflection/Footer
                if !footerText.isEmpty {
                    Text(footerText)
                        .font(.system(size: 12, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("说说你的困惑吧", text: $inputText)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .tint(Color(hex: "#5AE7FF"))
                        .focused($isFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            onSubmit(inputText)
                        }
                    
                    Button(action: { onSubmit(inputText) }) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(inputText.isEmpty ? Color.white.opacity(0.1) : Color(hex: "#8A5FBD"))
                            )
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        // Removed internal rotation to fix mirrored text
        // .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .contentShape(Rectangle())
        .onTapGesture {
            onFlipBack()
        }
    }
}

// Helper for Hex Color
// Helper for Hex Color
// Removed duplicate extension, now using shared Color+Hex.swift
