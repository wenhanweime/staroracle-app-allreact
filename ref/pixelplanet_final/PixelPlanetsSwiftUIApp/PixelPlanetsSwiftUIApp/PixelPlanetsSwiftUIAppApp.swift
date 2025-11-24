import SwiftUI
import Observation

@main
struct PixelPlanetsSwiftUIAppApp: App {
    @State private var viewModel = PlanetViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
