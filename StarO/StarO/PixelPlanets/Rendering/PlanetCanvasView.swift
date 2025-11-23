import SwiftUI
import GLKit
import QuartzCore

struct PlanetCanvasView: UIViewRepresentable {
    var planet: PlanetBase
    var pixels: Int
    var playing: Bool

    func makeUIView(context: Context) -> GLKView {
        let glContext = EAGLContext(api: .openGLES2)!
        let view = GLKView(frame: .zero, context: glContext)
        view.enableSetNeedsDisplay = false
        view.drawableColorFormat = .RGBA8888
        view.drawableDepthFormat = .formatNone
        view.drawableMultisample = .multisampleNone
        view.isOpaque = false
        view.delegate = context.coordinator
        view.layer.magnificationFilter = .nearest
        view.layer.minificationFilter = .nearest

        EAGLContext.setCurrent(glContext)
        context.coordinator.view = view
        context.coordinator.renderer = PlanetGLRenderer(planet: planet)
        context.coordinator.updatePixelDensity(pixels, for: view)
        context.coordinator.setPlaying(playing)
        view.display()
        return view
    }

    func updateUIView(_ uiView: GLKView, context: Context) {
        EAGLContext.setCurrent(uiView.context)
        context.coordinator.updatePlanet(planet)
        context.coordinator.updatePixelDensity(pixels, for: uiView)
        context.coordinator.setPlaying(playing)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    @MainActor
    final class Coordinator: NSObject, GLKViewDelegate {
        let parent: PlanetCanvasView
        var renderer: PlanetGLRenderer?
        weak var view: GLKView?
        var displayLink: CADisplayLink?
        private var lastTimestamp: CFTimeInterval?
        private var isPlaying = false
        private var lastScale: CGFloat = 0
        private var currentPlanet: PlanetBase

        init(_ parent: PlanetCanvasView) {
            self.parent = parent
            self.currentPlanet = parent.planet
        }

        func updatePixelDensity(_ pixels: Int, for view: GLKView) {
            let bounds = view.bounds
            let side = max(1, min(bounds.width, bounds.height))
            let desired = CGFloat(max(pixels, 1)) * CGFloat(currentPlanet.relativeScale)
            let targetScale = max(1, desired / side)
            let maximumScale = UIScreen.main.scale * 4
            let clampedScale = min(targetScale, maximumScale)
            if abs(clampedScale - lastScale) > 0.01 {
                view.contentScaleFactor = clampedScale
                lastScale = clampedScale
                view.display()
            }
        }

        func updatePlanet(_ planet: PlanetBase) {
            currentPlanet = planet
            if renderer == nil {
                renderer = PlanetGLRenderer(planet: planet)
            } else {
                renderer?.setPlanet(planet)
            }
            lastTimestamp = nil
        }

        func setPlaying(_ playing: Bool) {
            if playing == isPlaying { return }
            isPlaying = playing
            if playing {
                lastTimestamp = nil
                startDisplayLink()
            } else {
                stopDisplayLink()
                view?.display()
            }
        }

        nonisolated func glkView(_ view: GLKView, drawIn rect: CGRect) {
            // GLKit guarantees this is called on the main thread
            MainActor.assumeIsolated {
                renderer?.draw(in: view)
            }
        }

        private func startDisplayLink() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(step(link:)))
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func stopDisplayLink() {
            if let lastTimestamp, let renderer {
                renderer.pauseAnimation(at: lastTimestamp)
            }
            displayLink?.invalidate()
            displayLink = nil
            lastTimestamp = nil
        }

        @objc private func step(link: CADisplayLink) {
            guard let renderer = renderer else { return }
            lastTimestamp = link.timestamp
            renderer.updateAnimationTime(link.timestamp)
            view?.display()
        }

    }
}
