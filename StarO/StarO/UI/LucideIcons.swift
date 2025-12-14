import SwiftUI

// Minimal Lucide-like icons implemented with SwiftUI Paths using 24x24 viewBox
// Stroke style matches Lucide (round caps/joins, width=2)

struct LucideArrowLeftIcon: View {
    var size: CGFloat = 18
    var color: Color = .white

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 15, y: 19))
                p.addLine(to: CGPoint(x: 9, y: 12))
                p.addLine(to: CGPoint(x: 15, y: 5))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 24, height: 24)
        .scaleEffect(size / 24)
    }
}

struct LucideSearchIcon: View {
    var size: CGFloat = 18
    var color: Color = .white

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: 16, height: 16)
                .offset(x: -1, y: -1)

            Path { p in
                p.move(to: CGPoint(x: 21, y: 21))
                p.addLine(to: CGPoint(x: 16.65, y: 16.65))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: 24, height: 24)
        .scaleEffect(size / 24)
    }
}
