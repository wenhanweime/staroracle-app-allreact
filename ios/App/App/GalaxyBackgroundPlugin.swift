import Foundation
import Capacitor
import UIKit

@objc(GalaxyBackgroundPlugin)
public class GalaxyBackgroundPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "GalaxyBackgroundPlugin"
    public let jsName = "GalaxyBackground"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "configure", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setQuality", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setMode", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setHighlights", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearHighlights", returnType: CAPPluginReturnPromise)
    ]

    private let manager = GalaxyBackgroundManager()

    public override func load() {
        super.load()
        if let bridge = bridge {
            manager.attach(to: bridge)
        }
    }

    @objc func configure(_ call: CAPPluginCall) {
        let qualityRaw = call.getString("quality")
        let reducedMotion = call.getBool("reducedMotion")
        let quality = GalaxyRenderQuality.from(qualityRaw)

        manager.configure(quality: quality, reducedMotion: reducedMotion)
        call.resolve()
    }

    @objc func setQuality(_ call: CAPPluginCall) {
        let qualityRaw = call.getString("quality")
        let reducedMotion = call.getBool("reducedMotion")
        let quality = GalaxyRenderQuality.from(qualityRaw)

        manager.configure(quality: quality, reducedMotion: reducedMotion)
        call.resolve()
    }

    @objc func setMode(_ call: CAPPluginCall) {
        let mode = call.getString("mode") ?? "native"
        manager.setMode(mode)
        call.resolve()
    }

    @objc func setHighlights(_ call: CAPPluginCall) {
        guard let rawHighlights = call.getArray("highlights", Any.self) else {
            manager.clearHighlights()
            call.resolve()
            return
        }

        let highlights = rawHighlights.compactMap { item -> GalaxyHighlightPayload? in
            guard let dict = item as? [String: Any],
                  let id = dict["id"] as? String else {
                return nil
            }

            let colorHex = (dict["color"] as? String) ?? "#FFFFFF"
            let color = UIColor(hexString: colorHex) ?? UIColor.white
            let intensity = CGFloat(dict["intensity"] as? Double ?? 1.0)

            var point: CGPoint? = nil
            if let x = dict["x"] as? Double,
               let y = dict["y"] as? Double {
                point = CGPoint(x: x, y: y)
            }

            return GalaxyHighlightPayload(id: id, point: point, color: color, intensity: max(0.5, intensity))
        }

        manager.setHighlights(highlights)
        call.resolve()
    }

    @objc func clearHighlights(_ call: CAPPluginCall) {
        manager.clearHighlights()
        call.resolve()
    }
}

// MARK: - HEX颜色辅助
private extension UIColor {
    convenience init?(hexString: String) {
        var formatted = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if formatted.hasPrefix("#") {
            formatted.removeFirst()
        }

        guard formatted.count == 6,
              let hexNumber = UInt32(formatted, radix: 16) else {
            return nil
        }

        let r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
        let b = CGFloat(hexNumber & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
