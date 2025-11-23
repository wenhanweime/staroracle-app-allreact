import Foundation

public struct ColorBinding: Equatable, Sendable {
    public let layer: String
    public let uniform: String
    public let slots: Int

    public init(layer: String, uniform: String, slots: Int) {
        self.layer = layer
        self.uniform = uniform
        self.slots = slots
    }
}

public struct UniformControl: Equatable, Sendable {
    public let layer: String
    public let uniform: String
    public let label: String
    public let min: Float
    public let max: Float
    public let step: Float?

    public init(layer: String, uniform: String, label: String, min: Float, max: Float, step: Float? = nil) {
        self.layer = layer
        self.uniform = uniform
        self.label = label
        self.min = min
        self.max = max
        self.step = step
    }
}

public struct LayerDefinition: Sendable {
    public let name: String
    public let shaderPath: String
    public let uniforms: [String: UniformValue]
    public var visible: Bool
    public var colors: [ColorBinding]

    public init(
        name: String,
        shaderPath: String,
        uniforms: [String: UniformValue],
        visible: Bool = true,
        colors: [ColorBinding] = []
    ) {
        self.name = name
        self.shaderPath = shaderPath
        self.uniforms = uniforms
        self.visible = visible
        self.colors = colors
    }
}

public struct PlanetConfig: Sendable {
    public let id: String
    public let label: String
    public let relativeScale: Float
    public let guiZoom: Float
    public let layers: [LayerDefinition]
    public let uniformControls: [UniformControl]

    public init(
        id: String,
        label: String,
        relativeScale: Float,
        guiZoom: Float,
        layers: [LayerDefinition],
        uniformControls: [UniformControl] = []
    ) {
        self.id = id
        self.label = label
        self.relativeScale = relativeScale
        self.guiZoom = guiZoom
        self.layers = layers
        self.uniformControls = uniformControls
    }
}

public struct LayerSummary: Equatable, Sendable {
    public let name: String
    public var visible: Bool
}

public enum ShaderLibraryError: Error {
    case resourceNotFound(String)
    case unreadableResource(String)
}

public enum ShaderLibrary {
    public static func fragment(_ relativePath: String) throws -> String {
        let path = relativePath.hasSuffix(".frag") ? relativePath : "\(relativePath).frag"
        let url = try locate(path, in: "Shaders")
        do {
            return try String(contentsOf: url)
        } catch {
            throw ShaderLibraryError.unreadableResource(path)
        }
    }

    private static func locate(_ path: String, in subdirectory: String) throws -> URL {
        let components = path.split(separator: "/")
        guard let filename = components.last else {
            throw ShaderLibraryError.resourceNotFound(path)
        }
        let nameParts = filename.split(separator: ".")
        guard let base = nameParts.first else {
            throw ShaderLibraryError.resourceNotFound(path)
        }
        let ext = nameParts.count > 1 ? String(nameParts.last!) : nil
        let directory: String?
        if components.count > 1 {
            let subpath = components.dropLast().joined(separator: "/")
            directory = "\(subdirectory)/\(subpath)"
        } else {
            directory = subdirectory
        }
        // MODIFIED: Use Bundle.main instead of Bundle.module
        if let url = Bundle.main.url(forResource: String(base), withExtension: ext, subdirectory: directory) {
            return url
        }
        throw ShaderLibraryError.resourceNotFound(path)
    }
}

/// Reference-type layer state used at runtime.
public final class LayerState: @unchecked Sendable {
    public let name: String
    public let shaderPath: String
    public let shaderSource: String
    public var uniforms: [String: UniformValue]
    public var visible: Bool
    public let colorBindings: [ColorBinding]

    public init(definition: LayerDefinition) throws {
        self.name = definition.name
        self.shaderPath = definition.shaderPath
        self.shaderSource = try ShaderLibrary.fragment(definition.shaderPath)
        self.uniforms = definition.uniforms.mapValues { $0.clone() }
        self.visible = definition.visible
        self.colorBindings = definition.colors
    }
}
