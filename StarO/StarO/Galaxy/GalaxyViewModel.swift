import SwiftUI
import QuartzCore
import StarOracleCore

struct GalaxyHighlight {
    let color: Color
    let activatedAt: CFTimeInterval
    let whiteBias: Double // 0.0 = 偏高亮色, 1.0 = 偏纯白
    var isPermanent: Bool = false
    var expiresAt: Date? = nil
}

struct GalaxyPulse: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let startTime: TimeInterval
    let duration: TimeInterval
    let size: CGFloat
}

struct GalaxyHighlightEntry: Identifiable {
    let id: String
    let ring: Int
    let position: CGPoint
    let size: CGFloat
    let colorHex: String
    let litHex: String

    var identifier: String { id }
}

@MainActor
final class GalaxyViewModel: ObservableObject {
    @Published private(set) var rings: [[GalaxyStar]] = []
    @Published private(set) var backgroundStars: [GalaxyBackgroundStar] = []
    @Published private(set) var pulses: [GalaxyPulse] = []
    @Published private(set) var highlights: [String: GalaxyHighlight] = [:]

    // Canonical reference: iPhone 15 Pro Max portrait points + @3x.
    // We generate the galaxy only against this reference to make the star list stable (fixed order/id).
    var galaxySeed: UInt64 = 0xA17C9E3

    let params: GalaxyParams
    let palette: GalaxyPalette
    let litPalette: GalaxyPalette
    let glowConfig: GlowConfig
    let layerAlpha: GalaxyLayerAlpha

    private(set) var bandSize: CGSize = .zero
    private var lastSize: CGSize = .zero
    private var elapsedTime: TimeInterval = 0
    private let baseDegPerMs = 0.0005
    private let alphaMap: [String: Double]
    private var selectionRandom = SeededRandom(seed: 0xC0FFEE1234567890)
    private var pulseRandom = SeededRandom(seed: 0xDABA0FF1CE123456)
    private var starLookup: [String: GalaxyStar] = [:]
    private var ringRotationCache: [RotationCache] = []
    private var screenPositionLookup: [String: CGPoint] = [:]
    private let highlightTintHex: String
    var timeOrigin: CFTimeInterval = 0 // 与渲染对齐的时间原点

    private let canonicalSize = CGSize(width: 430.0, height: 932.0)
    private let canonicalDpr = 3.0
    private var cachedCanonicalSeed: UInt64?
    private var cachedCanonicalField: GalaxyFieldData?

    var onRegionSelected: ((GalaxyRegion) -> Void)?
    var onTap: ((CGPoint, CGSize, GalaxyRegion, TimeInterval) -> Void)?
    var onHighlightsPersisted: (([GalaxyHighlightEntry]) -> Void)?

    init(
        params: GalaxyParams = .platformDefault(),
        palette: GalaxyPalette = .baseline,
        litPalette: GalaxyPalette = .lit,
        glowConfig: GlowConfig = .baseline,
        layerAlpha: GalaxyLayerAlpha = .baseline
    ) {
        self.params = params
        self.palette = palette
        self.litPalette = litPalette
        self.glowConfig = glowConfig
        self.layerAlpha = layerAlpha
        // 对齐提交 cf1de85... 中使用的高亮色调
        let boostedHighlightHex = "#5AE7FF"
        self.highlightTintHex = boostedHighlightHex
        self.alphaMap = [
            normalizeGalaxyHex(palette.core): layerAlpha.core,
            normalizeGalaxyHex(palette.ridge): layerAlpha.ridge,
            normalizeGalaxyHex(palette.armBright): layerAlpha.armBright,
            normalizeGalaxyHex(palette.armEdge): layerAlpha.armEdge,
            normalizeGalaxyHex(palette.hii): layerAlpha.hii,
            normalizeGalaxyHex(palette.dust): layerAlpha.dust,
            normalizeGalaxyHex(palette.outer): layerAlpha.outer
        ]
    }

    private struct RotationCache {
        let sin: Double
        let cos: Double
    }

    var ringCount: Int {
        rings.count
    }

    private var highlightLifetime: CFTimeInterval {
        max(0.01, glowConfig.durationMs / 1000.0 * 1.25)
    }

    @discardableResult
    func prepareIfNeeded(for size: CGSize) -> Bool {
        guard size.width > 0, size.height > 0 else { return false }
        if abs(size.width - lastSize.width) < 1 && abs(size.height - lastSize.height) < 1 {
            return false
        }
        regenerate(for: size)
        lastSize = size
        return true
    }

    func regenerate(for size: CGSize) {
        // Cross-device consistency: always generate against canonical reference.
        // Other devices only scale/fit the canonical field (do not regenerate).
        let reduceMotion = false

        let seed = galaxySeed
        let canonicalField: GalaxyFieldData = {
            if let cached = cachedCanonicalField, cachedCanonicalSeed == seed {
                return cached
            }
            let generated = GalaxyGenerator.generateField(
                size: canonicalSize,
                seed: seed,
                params: params,
                palette: palette,
                litPalette: litPalette,
                structureColoring: true,
                scale: params.galaxyScale,
                deviceScale: canonicalDpr,
                reduceMotion: reduceMotion
            )
            cachedCanonicalSeed = seed
            cachedCanonicalField = generated
            return generated
        }()

        // Scale canonical field into the current canvas while preserving aspect coverage.
        let sx = size.width / canonicalSize.width
        let sy = size.height / canonicalSize.height
        let fit = max(0.01, max(sx, sy))
        let scaledBandSize = CGSize(
            width: canonicalField.bandSize.width * fit,
            height: canonicalField.bandSize.height * fit
        )

        rings = canonicalField.rings.map { ring in
            ring.map { star in
                GalaxyStar(
                    id: star.id,
                    band: star.band,
                    position: CGPoint(x: star.position.x * fit, y: star.position.y * fit),
                    size: star.size * fit,
                    baseColor: star.baseColor,
                    litColor: star.litColor,
                    baseHex: star.baseHex,
                    displayHex: star.displayHex,
                    litHex: star.litHex,
                    bandSize: scaledBandSize
                )
            }
        }
        backgroundStars = canonicalField.background.map { bg in
            GalaxyBackgroundStar(
                id: bg.id,
                position: CGPoint(x: bg.position.x * fit, y: bg.position.y * fit),
                size: bg.size * fit
            )
        }
        bandSize = scaledBandSize

        highlights.removeAll()
        pulses.removeAll()
        elapsedTime = 0
        rebuildStarLookup()
        ringRotationCache = []
        screenPositionLookup = [:]
    }

    func updateElapsedTimeOnly(elapsed: TimeInterval) {
        elapsedTime = max(0, elapsed)
        
        // 仅当有脉冲过期时才修改数组，避免每帧触发 @Published 更新
        if !pulses.isEmpty {
            let countBefore = pulses.count
            let filtered = pulses.filter { elapsedTime - $0.startTime <= $0.duration }
            if filtered.count != countBefore {
                pulses = filtered
            }
        }
        
        purgeExpiredHighlights()
        
        // 仍然更新旋转缓存，以便 handleTap 时能计算正确位置（开销很小，仅10个环）
        updateRotationCache(for: elapsedTime)
        
        // ❌ 不再更新 screenPositionLookup，节省大量 CPU
        // updateScreenPositionCache()
    }

    func update(elapsed: TimeInterval) {
        updateElapsedTimeOnly(elapsed: elapsed)
    }

    func alpha(for star: GalaxyStar) -> Double {
        alphaMap[star.baseHex] ?? 1.0
    }

    func handleTap(at location: CGPoint, in size: CGSize, tapTimestamp: CFTimeInterval? = nil) {
        guard ringCount > 0 else { return }
        #if DEBUG
        if StarOracleDebug.verboseLogsEnabled {
            print("[GalaxyViewModel] handleTap at (\(location.x), \(location.y)) size (\(size.width), \(size.height))")
        }
        #endif
        
        // 只保留region选择功能
        let region = region(for: location, in: size)
        onRegionSelected?(region)
        // Pass timestamp to callback
        onTap?(location, size, region, tapTimestamp ?? elapsedTime)
        
        // 默认高亮（闪烁）：仅在外部未提供 onTap 回调时启用，避免重复计算高亮导致卡顿。
        if onTap == nil {
            triggerHighlight(at: location, in: size, tapTimestamp: tapTimestamp)
        }
    }
    
    func triggerHighlight(
        at location: CGPoint,
        in size: CGSize,
        tapTimestamp: CFTimeInterval? = nil,
        isPermanent: Bool = false,
        expiresAt: Date? = nil,
        shouldPersist: Bool = false
    ) {
        guard ringCount > 0 else { return }
        
        // Use deterministic RNG if timestamp is provided to ensure consistent selection
        // between transient flash and permanent highlight
        var rng: SeededRandom
        if let ts = tapTimestamp {
            let seed = UInt64(abs(Int64(ts * 1_000_000)))
            rng = SeededRandom(seed: seed)
        } else {
            rng = selectionRandom
        }
        
        // 计算搜索半径（恢复原版下限 30）
        let radiusBase = min(size.width, size.height) * glowConfig.radiusFactor
        let radius = max(CGFloat(30.0), CGFloat(radiusBase))

        // 计算点击时的 elapsed（对齐渲染时间原点），命中按此时刻的位置进行
        let elapsedAtTap: TimeInterval = {
            if let ts = tapTimestamp, timeOrigin > 0 {
                return max(0, ts - timeOrigin)
            }
            return elapsedTime
        }()
        
        // 收集候选星星
        let candidates = collectCandidates(at: location, in: size, radius: radius, elapsed: elapsedAtTap)
        
        guard !candidates.isEmpty else {
            #if DEBUG
            if StarOracleDebug.verboseLogsEnabled {
                print("[GalaxyViewModel] no selectable stars around tap")
            }
            #endif
            return
        }
        
        #if DEBUG
        if StarOracleDebug.verboseLogsEnabled {
            print("[GalaxyViewModel] candidates: \(candidates.count)")
        }
        #endif
        
        // 挑选高亮星星（加权随机）
        let selected = pickHighlights(from: candidates, targetCount: min(30, candidates.count), rng: &rng)
        
        #if DEBUG
        if StarOracleDebug.verboseLogsEnabled {
            print("[GalaxyViewModel] selected: \(selected.count) stars for highlight")
        }
        #endif
        
        // 禁用脉冲动画（删除大球形闪烁，仅保留星点高亮）
        // appendPulses(for: selected)
        
        // 应用高亮状态（用于星星变大变亮）
        let entries = applyHighlights(from: selected, isPermanent: isPermanent, expiresAt: expiresAt, rng: &rng)
        #if DEBUG
        if StarOracleDebug.verboseLogsEnabled {
            print("[GalaxyViewModel] highlights added: \(entries.count), total: \(highlights.count)")
        }
        #endif
        
        // Update global RNG only if we didn't use a deterministic one
        if tapTimestamp == nil {
            selectionRandom = rng
        }
        
        // 通知持久化（如果有回调）
        if shouldPersist, !entries.isEmpty {
            onHighlightsPersisted?(entries)
        }
    }

    private func collectCandidates(at location: CGPoint, in size: CGSize, radius: CGFloat, elapsed: TimeInterval) -> [HighlightCandidate] {
        var results: [HighlightCandidate] = []
        let radiusSquared = radius * radius
        for (index, ring) in rings.enumerated() {
            for star in ring {
                // 这里按需计算位置，虽然比查表慢，但因为只在点击时触发，完全可接受
                let pos = screenPosition(for: star, ringIndex: index, in: size, elapsed: elapsed)
                let dx = pos.x - location.x
                let dy = pos.y - location.y
                let distanceSquared = dx * dx + dy * dy
                if distanceSquared <= radiusSquared {
                    results.append(HighlightCandidate(star: star, position: pos, distance: distanceSquared))
                }
            }
        }
        if results.isEmpty {
            var nearest: HighlightCandidate?
            var minDst = Double.greatestFiniteMagnitude
            for (index, ring) in rings.enumerated() {
                for star in ring {
                    let pos = screenPosition(for: star, ringIndex: index, in: size, elapsed: elapsed)
                    let dx = pos.x - location.x
                    let dy = pos.y - location.y
                    let distanceSquared = dx * dx + dy * dy
                    if distanceSquared < minDst {
                        minDst = distanceSquared
                        nearest = HighlightCandidate(star: star, position: pos, distance: distanceSquared)
                    }
                }
            }
            if let nearest, minDst < 2500 { // 50*50，如果最近的星星在50像素内，也允许选中
                return [nearest]
            }
        }
        return results
    }

    private func pickHighlights(from candidates: [HighlightCandidate], targetCount: Int, rng: inout SeededRandom) -> [HighlightCandidate] {
        let cappedTarget = min(max(targetCount, 0), candidates.count)
        guard cappedTarget > 0 else { return [] }

        // 1) 中心密集核心：按距离排序，优先选取一部分最近的点
        // 注意：这里的“核心”是指点击位置的中心，而不是银河的核心（band=0）
        let sortedByDistance = candidates.sorted { $0.distance < $1.distance }
        let coreCount = min(max(3, Int(ceil(Double(cappedTarget) * 0.4))), cappedTarget)
        let denseStars = Array(sortedByDistance.prefix(coreCount))
        
        if denseStars.count >= cappedTarget { return denseStars }
        
        let denseIDs = Set(denseStars.map { $0.star.id })
        let remainingCandidates = candidates.filter { !denseIDs.contains($0.star.id) }
        let remainingTarget = cappedTarget - denseStars.count
        
        // 2) 距离加权抽样（无放回）：越靠近中心，被选中概率越高
        // 距离权重：w = ((R - d)/R)^gamma
        let maxDistance = remainingCandidates.map { $0.distance }.max() ?? 1.0
        let R = sqrt(max(1e-9, maxDistance))
        let gamma: Double = 2.2

        struct WeightedKey { let candidate: HighlightCandidate; let key: Double }
        var keys: [WeightedKey] = []
        keys.reserveCapacity(remainingCandidates.count)
        
        for c in remainingCandidates {
            let d = sqrt(max(0.0, c.distance))
            let ratio = max(0.0, min(1.0, 1.0 - d / R))
            let w = pow(ratio, gamma)
            let u = max(1e-9, min(0.999999, rng.next()))
            let key = -log(u) / max(w, 1e-9) // 小 key 表示更高的选择机会
            keys.append(WeightedKey(candidate: c, key: key))
        }
        
        keys.sort { $0.key < $1.key }
        let weightedSelected = keys.prefix(remainingTarget).map { $0.candidate }

        return denseStars + weightedSelected
    }

    private func appendPulses(for candidates: [HighlightCandidate]) {
        let baseDuration = glowConfig.durationMs / 1000.0
        let now = elapsedTime
        var rng = pulseRandom
        var pulsesToAdd: [GalaxyPulse] = []
        pulsesToAdd.reserveCapacity(candidates.count)
        for candidate in candidates {
            let duration = baseDuration * rng.next(in: 0.65...1.05)
            let scale = rng.next(in: 1.15...1.6)
            let size = max(4.0, candidate.star.size * scale)
            let color = highlightColor(for: candidate.star)
            let pulse = GalaxyPulse(
                position: candidate.position,
                color: color,
                startTime: now,
                duration: duration,
                size: CGFloat(size)
            )
            pulsesToAdd.append(pulse)
        }
        pulseRandom = rng
        pulses.append(contentsOf: pulsesToAdd)
        #if DEBUG
        if !pulsesToAdd.isEmpty {
            print("[GalaxyViewModel] pulses added: \(pulsesToAdd.count)")
        }
        #endif
        if pulses.count > 120 {
            pulses = Array(pulses.suffix(120))
        }
    }

    private func applyHighlights(from candidates: [HighlightCandidate], isPermanent: Bool, expiresAt: Date?, rng: inout SeededRandom) -> [GalaxyHighlightEntry] {
        guard !candidates.isEmpty else { return [] }
        var outputs: [GalaxyHighlightEntry] = []
        outputs.reserveCapacity(candidates.count)
        var seen: Set<String> = []

        for candidate in candidates {
            let color = highlightColor(for: candidate.star)
            // 为每个高亮分配一个随机的白偏移（决定偏白还是偏高亮色）
            let bias = rng.next()
            
            // Update or create highlight
            // If it already exists and is permanent, keep it permanent
            let existing = highlights[candidate.star.id]
            let shouldBePermanent = isPermanent || (existing?.isPermanent ?? false)

            let shouldKeepExpires: Date? = {
                if shouldBePermanent { return nil }
                if let a = existing?.expiresAt, let b = expiresAt { return max(a, b) }
                return expiresAt ?? existing?.expiresAt
            }()

            highlights[candidate.star.id] = GalaxyHighlight(
                color: color,
                activatedAt: CACurrentMediaTime(), // Reset animation time
                whiteBias: bias,
                isPermanent: shouldBePermanent,
                expiresAt: shouldKeepExpires
            )
            
            if !seen.contains(candidate.star.id) {
                seen.insert(candidate.star.id)
                let entry = GalaxyHighlightEntry(
                    id: candidate.star.id,
                    ring: candidate.star.band,
                    position: candidate.position,
                    size: candidate.star.size,
                    colorHex: candidate.star.baseHex,
                    litHex: candidate.star.litHex
                )
                outputs.append(entry)
            }
        }
        return outputs
    }

    func highlightFlashProgress(for star: GalaxyStar) -> Double {
        guard let highlight = highlights[star.id] else { return 1.0 }
        let duration = max(0.01, glowConfig.durationMs / 1000.0 * 0.6)
        let progress = (elapsedTime - highlight.activatedAt) / duration
        return min(max(progress, 0.0), 1.0)
    }
    
    func isHighlighted(_ star: GalaxyStar) -> Bool {
        return highlights[star.id] != nil
    }

    func highlightEntries() -> [(GalaxyStar, GalaxyHighlight)] {
        highlights.compactMap { key, highlight in
            guard let star = starLookup[key] else { return nil }
            return (star, highlight)
        }
    }

    private func rebuildStarLookup() {
        var map: [String: GalaxyStar] = [:]
        for ring in rings {
            for star in ring {
                map[star.id] = star
            }
        }
        starLookup = map
    }

    private func purgeExpiredHighlights() {
        // Remove highlights that have exceeded their duration, UNLESS they are permanent or have an active TTL.
        let duration = max(0.01, glowConfig.durationMs / 1000.0)
        let nowMono = CACurrentMediaTime()
        let nowDate = Date()
        
        highlights = highlights.filter { _, highlight in
            if highlight.isPermanent { return true }
            if let exp = highlight.expiresAt {
                return exp > nowDate
            }
            return (nowMono - highlight.activatedAt <= duration)
        }
    }

    func mergeTemporaryHighlights(indices: [Int], expiresAt: Date) {
        guard !indices.isEmpty else { return }
        let now = CACurrentMediaTime()
        let activatedAt = now - 10_000 // restore without flash
        for idx in indices {
            let starId = "s-\(idx)"
            guard let star = starLookup[starId] else { continue }
            let color = highlightColor(for: star)
            let existing = highlights[starId]
            if existing?.isPermanent == true { continue }
            let mergedExpiresAt = {
                if let old = existing?.expiresAt { return max(old, expiresAt) }
                return expiresAt
            }()
            highlights[starId] = GalaxyHighlight(
                color: color,
                activatedAt: activatedAt,
                whiteBias: 0.0,
                isPermanent: false,
                expiresAt: mergedExpiresAt
            )
        }
    }

    func setPermanentHighlights(indices: [Int]) {
        let targetIds = Set(indices.map { "s-\($0)" })
        if targetIds.isEmpty {
            highlights = highlights.filter { _, highlight in
                !highlight.isPermanent
            }
            return
        }

        highlights = highlights.filter { key, highlight in
            if !highlight.isPermanent { return true }
            return targetIds.contains(key)
        }

        let now = CACurrentMediaTime()
        let activatedAt = now - 10_000 // restore without flash
        for starId in targetIds {
            guard let star = starLookup[starId] else { continue }
            let color = highlightColor(for: star)
            let existing = highlights[starId]
            if existing?.isPermanent == true { continue }
            highlights[starId] = GalaxyHighlight(
                color: color,
                activatedAt: activatedAt,
                whiteBias: 0.0,
                isPermanent: true,
                expiresAt: nil
            )
        }
    }

    private func highlightColor(for star: GalaxyStar) -> Color {
        galaxyBlendHex(star.litHex, highlightTintHex, ratio: 0.45)
    }


    private func updateRotationCache(for elapsed: TimeInterval) {
        guard ringCount > 0 else {
            ringRotationCache = []
            return
        }
        let angle = baseDegPerMs * elapsed * 1000.0 * (.pi / 180.0)
        let cacheEntry = RotationCache(sin: sin(angle), cos: cos(angle))
        ringRotationCache = Array(repeating: cacheEntry, count: ringCount)
    }

    private func updateScreenPositionCache() {
        // ❌ 移除全量缓存更新，因为渲染已经移至 GPU
        screenPositionLookup = [:]
    }

    private func region(for location: CGPoint, in size: CGSize) -> GalaxyRegion {
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let angle = atan2(location.y - center.y, location.x - center.x)
        let degrees = (angle * 180.0 / .pi + 360.0).truncatingRemainder(dividingBy: 360.0)
        if degrees < 120.0 { return .emotion }
        if degrees < 240.0 { return .relation }
        return .growth
    }

    func screenPosition(for star: GalaxyStar, ringIndex: Int, in size: CGSize, elapsed: TimeInterval) -> CGPoint {
        // 实时计算位置，仅用于点击检测（低频）
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let scale = CGFloat(params.galaxyScale)
        let bandCenter = CGPoint(x: star.bandSize.width / 2.0, y: star.bandSize.height / 2.0)
        let dx = Double(star.position.x - bandCenter.x)
        let dy = Double(star.position.y - bandCenter.y)
        
        // 确保使用与 GPU 一致的旋转逻辑
        // GPU: angle = 0.0087266 * uniforms.time
        // CPU: baseDegPerMs * elapsed * 1000.0 * (.pi / 180.0)
        // baseDegPerMs = 0.0005
        // 0.0005 * 1000 * 0.017453 = 0.0087265
        // 一致
        
        let angle = baseDegPerMs * elapsed * 1000.0 * (.pi / 180.0)
        let rx = dx * cos(angle) - dy * sin(angle)
        let ry = dx * sin(angle) + dy * cos(angle)
        let sx = center.x + CGFloat(rx) * scale
        let sy = center.y + CGFloat(ry) * scale
        return CGPoint(x: sx, y: sy)
    }
}

private struct HighlightCandidate {
    let star: GalaxyStar
    let position: CGPoint
    let distance: CGFloat
}
