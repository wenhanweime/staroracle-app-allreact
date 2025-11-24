import SwiftUI
import PixelPlanetsCore

extension PixelPlanetsCore.Color {
    var swiftUIColor: SwiftUI.Color {
        SwiftUI.Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}
