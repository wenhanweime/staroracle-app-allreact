import Foundation
import simd

public enum UniformValue: Equatable, Sendable {
    case float(Float)
    case vec2(SIMD2<Float>)
    case vec3(SIMD3<Float>)
    case vec4(SIMD4<Float>)
    case buffer([Float])

    public func clone() -> UniformValue {
        switch self {
        case .float, .vec2, .vec3, .vec4:
            return self
        case .buffer(let array):
            return .buffer(Array(array))
        }
    }

    public func asFloat() -> Float? {
        switch self {
        case .float(let value):
            return value
        case .buffer(let array) where array.count == 1:
            return array[0]
        default:
            return nil
        }
    }

    public func asInt() -> Int? {
        guard let value = asFloat() else { return nil }
        return Int(value.rounded())
    }

    public func asVec2() -> SIMD2<Float>? {
        switch self {
        case .vec2(let value):
            return value
        default:
            return nil
        }
    }

    public func asVec3() -> SIMD3<Float>? {
        if case let .vec3(value) = self {
            return value
        }
        return nil
    }

    public func asVec4() -> SIMD4<Float>? {
        if case let .vec4(value) = self {
            return value
        }
        return nil
    }

    public func asBuffer() -> [Float]? {
        if case let .buffer(array) = self {
            return array
        }
        return nil
    }
}
