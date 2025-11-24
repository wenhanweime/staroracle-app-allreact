import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import Observation
import PixelPlanetsCore

@MainActor
@Observable final class PlanetViewModel {
    var planetNames: [String]
    var selectedPlanetName: String
    var planet: PlanetBase?

    var seed: Int = 123_456
    var pixels: Int = 100
    var rotation: Double = 0
    var playing = true
    var manualTimeEnabled = false
    var manualTime: Double = 0
    var light = CGPoint(x: 0.4, y: 0.35)

    init() {
        let names = PlanetLibrary.allPlanetNames
        self.planetNames = names
        self.selectedPlanetName = names.first ?? ""
        self.planet = try? PlanetLibrary.makePlanet(named: selectedPlanetName)
        applyCurrentState()
    }

    func selectPlanet(_ name: String) {
        selectedPlanetName = name
        planet = try? PlanetLibrary.makePlanet(named: name)
        resetState()
        applyCurrentState()
    }

    func applySeed() {
        guard var planet else { return }
        let bitPattern = UInt64(bitPattern: Int64(seed))
        var rng = RandomStream(seed: bitPattern)
        planet.setSeed(seed, rng: &rng)
    }

    func applyPixels() {
        planet?.setPixels(pixels)
    }

    func applyRotation() {
        planet?.setRotation(Float(rotation))
    }

    func updateManualTime() {
        guard let planet else { return }
        if manualTimeEnabled {
            planet.overrideTime = true
            planet.setCustomTime(Float(manualTime))
        } else {
            planet.overrideTime = false
        }
    }

    private func resetState() {
        seed = 123_456 // default seed
        pixels = 100
        pixels = 100
        rotation = 0
        manualTimeEnabled = false
        manualTime = 0
        playing = true
    }

    private func applyCurrentState() {
        applySeed()
        applyPixels()
        applyRotation()
    }
}

struct ContentView: View {
    @Bindable var viewModel: PlanetViewModel

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let spacing: CGFloat = 18
            let horizontalPadding: CGFloat = 24
            let availableWidth = max(size.width - horizontalPadding * 2, 320)
            let forceVertical = availableWidth < 340
            let topHeight = min(max(size.height * 0.5, 260), 420)
            let presetWidth = max(80, min(availableWidth * 0.14, 160))
            let previewWidth = max(240, availableWidth - presetWidth - spacing)
            let stageSide = min(previewWidth, topHeight - 24)

            ZStack {
                LinearGradient(
                    colors: [
                        SwiftUI.Color(red: 0.02, green: 0.02, blue: 0.06),
                        SwiftUI.Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: spacing) {
                        if forceVertical {
                            presetSidebar(width: availableWidth)
                                .frame(height: topHeight)

                            previewSection(
                                width: availableWidth,
                                height: topHeight,
                                stageSide: min(availableWidth - 24, stageSide)
                            )
                        } else {
                            HStack(alignment: .top, spacing: spacing) {
                                presetSidebar(width: presetWidth)
                                        .frame(width: presetWidth, height: topHeight, alignment: .top)

                                previewSection(
                                    width: previewWidth,
                                    height: topHeight,
                                    stageSide: stageSide
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                        }

                        ControlPanel(
                            viewModel: viewModel,
                            availableWidth: availableWidth
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.vertical, spacing)
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }

    private func presetSidebar(width: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("行星预设")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.bottom, 4)

                ForEach(viewModel.planetNames, id: \.self) { name in
                    let isSelected = name == viewModel.selectedPlanetName
                    Button {
                        if !isSelected {
                            viewModel.selectPlanet(name)
                        }
                    } label: {
                        HStack {
                            Text(name)
                                .font(isSelected ? .callout.weight(.semibold) : .callout)
                                .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.75))
                            Spacer()
                            if isSelected {
                                Image(systemName: "chevron.right.circle.fill")
                                    .foregroundStyle(SwiftUI.Color.green)
                                    .imageScale(.medium)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? SwiftUI.Color.white.opacity(0.25) : SwiftUI.Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 12)
        }
        .frame(width: width)
        .background(SwiftUI.Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func previewSection(width: CGFloat, height: CGFloat, stageSide: CGFloat) -> some View {
        RendererStage(viewModel: viewModel, canvasSize: stageSide)
            .frame(maxWidth: width, alignment: .center)
            .frame(width: width, alignment: .center)
            .frame(height: height, alignment: .center)
    }
}

struct ControlPanel: View {
    @Bindable var viewModel: PlanetViewModel
    var availableWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            uniformSection

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: 12) {
                seedSection
                pixelsSection
                rotationSection
                timeSection
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SwiftUI.Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: availableWidth, alignment: .leading)
    }

    private var cardColumns: [GridItem] {
        let minWidth: CGFloat
        if availableWidth > 680 {
            minWidth = 240
        } else if availableWidth > 520 {
            minWidth = 200
        } else if availableWidth > 420 {
            minWidth = 160
        } else {
            minWidth = 140
        }
        return [
            GridItem(.adaptive(minimum: minWidth, maximum: 360), spacing: 12, alignment: .top)
        ]
    }

    private var uniformColumns: [GridItem] {
        let minWidth: CGFloat
        if availableWidth > 680 {
            minWidth = 170
        } else if availableWidth > 520 {
            minWidth = 150
        } else {
            minWidth = 130
        }
        return [
            GridItem(.adaptive(minimum: minWidth, maximum: 240), spacing: 10, alignment: .top)
        ]
    }

    private var seedSection: some View {
        ControlCard(title: "随机种子") {
            HStack(spacing: 8) {
                TextField("Seed", value: $viewModel.seed, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)
                    .controlSize(.small)
                Button("应用") { viewModel.applySeed() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("随机") {
                    viewModel.seed = Int.random(in: 0..<1_000_000)
                    viewModel.applySeed()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }

    private var pixelsSection: some View {
        ControlCard(title: "像素采样") {
            HStack {
                Text("\(viewModel.pixels)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Slider(value: Binding(
                get: { Double(viewModel.pixels) },
                set: { newValue in
                    viewModel.pixels = Int(newValue)
                    viewModel.applyPixels()
                }
            ), in: 12...1000, step: 1)
            .controlSize(.small)
        }
    }

    private var rotationSection: some View {
        ControlCard(title: "旋转") {
            HStack {
                Text("\(viewModel.rotation, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Slider(value: $viewModel.rotation, in: 0...(Double.pi * 2), step: 0.01)
                .onChange(of: viewModel.rotation) { _, _ in viewModel.applyRotation() }
                .controlSize(.small)
        }
    }

    private var timeSection: some View {
        ControlCard(title: "时间控制") {
            Toggle("暂停动画", isOn: Binding(
                get: { !viewModel.playing },
                set: { viewModel.playing = !$0 }
            ))
            .controlSize(.small)
            Toggle("手动时间控制", isOn: $viewModel.manualTimeEnabled)
                .onChange(of: viewModel.manualTimeEnabled) { _, _ in viewModel.updateManualTime() }
                .controlSize(.small)
            if viewModel.manualTimeEnabled {
                Slider(value: $viewModel.manualTime, in: 0...1, step: 0.001)
                    .onChange(of: viewModel.manualTime) { _, _ in viewModel.updateManualTime() }
                    .controlSize(.small)
                Text(viewModel.manualTime, format: .number.precision(.fractionLength(3)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var uniformSection: some View {
        ControlCard(title: "Uniform 控制") {
            if let planet = viewModel.planet {
                let controls = planet.uniformControlsList()
                LazyVGrid(columns: uniformColumns, spacing: 10) {
                    ForEach(Array(controls.enumerated()), id: \.offset) { _, control in
                        UniformControlView(planet: planet, control: control)
                    }
                }
            } else {
                Text("未加载任何行星")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ControlCard<Content: View>: View {
    let title: String?
    let content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SwiftUI.Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 2)
    }
}

struct UniformControlView: View {
    let planet: PlanetBase
    let control: UniformControl
    @State private var value: Double

    init(planet: PlanetBase, control: UniformControl) {
        self.planet = planet
        self.control = control
        let initial = planet.uniformValue(layerName: control.layer, uniform: control.uniform)?.asFloat() ?? control.min
        _value = State(initialValue: Double(initial))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(control.label): \(value, specifier: "%.3f")")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Slider(value: $value, in: Double(control.min)...Double(control.max), step: Double(control.step ?? 0.01))
                .onChange(of: value) { _, newValue in
                    planet.setUniformValue(layerName: control.layer, uniform: control.uniform, value: .float(Float(newValue)))
                }
                .controlSize(.mini)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RendererStage: View {
    @Bindable var viewModel: PlanetViewModel
    let canvasSize: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            if let planet = viewModel.planet {
                GeometryReader { proxy in
                    let side = min(proxy.size.width, proxy.size.height)
                    PlanetCanvasView(
                        planet: planet,
                        pixels: viewModel.pixels,
                        playing: viewModel.playing || viewModel.manualTimeEnabled
                    )
                    .frame(width: side, height: side)
                    .clipShape(Circle())
                    .contentShape(Circle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let nx = clamp(value.location.x / side)
                                let ny = clamp(value.location.y / side)
                                viewModel.light = CGPoint(x: nx, y: ny)
                                planet.setLight(Vec2(Float(nx), Float(ny)))
                            }
                    )
                }
                .frame(width: canvasSize, height: canvasSize)
                .padding(.top, 12)

                PaletteStrip(colors: planet.colorsPalette())
                    .frame(height: 28)
                    .clipShape(Capsule())

                VStack(spacing: 6) {
                    Text("当前行星: \(planet.label)")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if viewModel.manualTimeEnabled {
                        Text("手动时间: \(viewModel.manualTime, format: .number.precision(.fractionLength(3)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(viewModel.playing ? "动画播放中…" : "动画已暂停")
                            .font(.subheadline)
                            .foregroundStyle(viewModel.playing ? .green : .secondary)
                    }
                }
            } else {
                Text("未加载行星")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }
}

struct PaletteStrip: View {
    let colors: [PixelPlanetsCore.Color]

    var body: some View {
        HStack(spacing: 0) {
            if colors.isEmpty {
                SwiftUI.Color.gray
            } else {
                ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                    color.swiftUIColor
                }
            }
        }
    }
}

#Preview("Control Panel") {
    ContentView(viewModel: PlanetViewModel())
}
