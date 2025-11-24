import Foundation
import GLKit
import OpenGLES

final class PlanetGLRenderer: NSObject {
    private var planet: PlanetBase
    private var programs: [String: ProgramInfo] = [:]
    private var vertexBuffer: GLuint = 0
    // Match original: draw two triangles (6 vertices)
    private let quadVertices: [GLfloat] = [
        -1, -1,
         1, -1,
        -1,  1,
        -1,  1,
         1, -1,
         1,  1,
    ]

    struct ProgramInfo {
        let program: GLuint
        let attribPosition: GLuint
        let uniformLocations: [String: GLint]
        let uniformTypes: [String: GLenum]
    }

    init(planet: PlanetBase) {
        self.planet = planet
        super.init()
        setupBuffers()
        rebuildPrograms()
    }

    // Publicly accessible error for debugging
    private(set) var compileError: String?

    deinit {
        if vertexBuffer != 0 {
            glDeleteBuffers(1, &vertexBuffer)
        }
        programs.values.forEach { info in
            glDeleteProgram(info.program)
        }
    }

    func setPlanet(_ newPlanet: PlanetBase) {
        if planet === newPlanet {
            planet = newPlanet
            return
        }
        planet = newPlanet
        resetAnimationState()
        rebuildPrograms()
    }

    private var elapsedTime: Double = 0
    private var lastTimestamp: CFTimeInterval?

    func updateAnimationTime(_ timestamp: CFTimeInterval) {
        guard !planet.overrideTime else {
            lastTimestamp = nil
            return
        }
        if let previous = lastTimestamp {
            let delta = max(0, timestamp - previous)
            elapsedTime += delta
        }
        lastTimestamp = timestamp
        applyTime(elapsedTime)
    }

    func pauseAnimation(at timestamp: CFTimeInterval) {
        if let previous = lastTimestamp {
            elapsedTime += max(0, timestamp - previous)
        }
        lastTimestamp = nil
        if !planet.overrideTime {
            applyTime(elapsedTime)
        }
    }

    private func resetAnimationState() {
        elapsedTime = 0
        lastTimestamp = nil
        if !planet.overrideTime {
            applyTime(0)
        }
    }

    private func applyTime(_ time: Double) {
        planet.updateTime(Float(time))
    }

    @MainActor
    func draw(in view: GLKView) {
        // Ensure drawable is bound, clear and setup blending (match original)
        view.bindDrawable()
        glDisable(GLenum(GL_DEPTH_TEST))
        glEnable(GLenum(GL_BLEND))
        glBlendFuncSeparate(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA), GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        glClearColor(0, 0, 0, 0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

        let drawableWidth = max(1, GLsizei(view.drawableWidth))
        let drawableHeight = max(1, GLsizei(view.drawableHeight))
        let square = min(drawableWidth, drawableHeight)
        let offsetX: GLsizei = (drawableWidth - square) / 2
        let offsetY: GLsizei = (drawableHeight - square) / 2

        let canvasPixels = Int(square)
        let maxPixels = computeMaxLayerPixels()

        for layer in planet.layers where layer.visible {
            guard let programInfo = programs[layer.name] else { continue }
            glUseProgram(programInfo.program)

            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
            glEnableVertexAttribArray(programInfo.attribPosition)
            glVertexAttribPointer(programInfo.attribPosition, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)

            applyUniforms(for: layer, using: programInfo)
            applyViewport(for: layer, canvasPixels: canvasPixels, maxLayerPixels: maxPixels, offsetX: offsetX, offsetY: offsetY)

            glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
            glDisableVertexAttribArray(programInfo.attribPosition)
        }
    }
}

// MARK: - Program compilation

private extension PlanetGLRenderer {
    func computeMaxLayerPixels() -> Int {
        var maxPixels = 0
        for layer in planet.layers {
            if let value = layer.uniforms["pixels"], case let .float(amount) = value {
                maxPixels = max(maxPixels, Int(abs(amount)))
            }
        }
        return maxPixels
    }

    func applyViewport(for layer: LayerState, canvasPixels: Int, maxLayerPixels: Int, offsetX: GLsizei, offsetY: GLsizei) {
        guard canvasPixels > 0 else { return }
        let layerPixels: Float
        if let uniform = layer.uniforms["pixels"], case let .float(value) = uniform {
            layerPixels = abs(value)
        } else {
            glViewport(offsetX, offsetY, GLsizei(canvasPixels), GLsizei(canvasPixels))
            return
        }

        guard maxLayerPixels > 0 else {
            glViewport(offsetX, offsetY, GLsizei(canvasPixels), GLsizei(canvasPixels))
            return
        }

        let ratio = max(0.01, min(1, layerPixels / Float(maxLayerPixels)))
        let viewportSize = max(1, Int(Float(canvasPixels) * ratio))
        let inset = (canvasPixels - viewportSize) / 2
        let startX = offsetX + GLsizei(inset)
        let startY = offsetY + GLsizei(inset)
        glViewport(startX, startY, GLsizei(viewportSize), GLsizei(viewportSize))
    }

    func setupBuffers() {
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        quadVertices.withUnsafeBytes { rawPtr in
            glBufferData(GLenum(GL_ARRAY_BUFFER), rawPtr.count, rawPtr.baseAddress, GLenum(GL_STATIC_DRAW))
        }
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    }

    func rebuildPrograms() {
        programs.values.forEach { info in
            glDeleteProgram(info.program)
        }
        programs.removeAll()
        compileError = nil

        guard let vertexShader = compileShader(type: GLenum(GL_VERTEX_SHADER), source: Self.vertexShaderSource) else {
            if compileError == nil { compileError = "Vertex shader failed to compile" }
            return
        }
        defer { glDeleteShader(vertexShader) }

        for layer in planet.layers {
            guard let fragmentShader = compileShader(type: GLenum(GL_FRAGMENT_SHADER), source: layer.shaderSource) else {
                if compileError == nil { compileError = "Fragment shader for \(layer.name) failed" }
                continue
            }

            guard let program = linkProgram(vertexShader: vertexShader, fragmentShader: fragmentShader) else {
                glDeleteShader(fragmentShader)
                if compileError == nil { compileError = "Link failed for \(layer.name)" }
                continue
            }
            glDeleteShader(fragmentShader)

            let attribPosition = GLuint(glGetAttribLocation(program, "aPosition"))
            let (locations, types) = queryUniforms(program: program)
            
            // Check for missing uniforms
            var missing: [String] = []
            for (name, value) in layer.uniforms {
                // Skip if found
                if locations[name] != nil { continue }
                
                // Handle array uniforms (e.g. colors -> colors[0])
                if case .buffer = value {
                    if locations[name + "[0]"] != nil { continue }
                }
                
                missing.append(name)
            }
            
            if !missing.isEmpty {
                // Note: Some uniforms may be optimized out by GL compiler if unused in shader
                // This is expected and not necessarily an error
                print("[PlanetGLRenderer] Warning: Unused uniforms in \(layer.name): \(missing)")
                // Don't set compileError for unused uniforms, they're benign
            }
            
            programs[layer.name] = ProgramInfo(
                program: program,
                attribPosition: attribPosition,
                uniformLocations: locations,
                uniformTypes: types
            )
        }
    }

    func compileShader(type: GLenum, source: String) -> GLuint? {
        let shader = glCreateShader(type)
        var sourceCString = (source as NSString).utf8String
        var length = GLint(source.utf8.count)
        glShaderSource(shader, 1, &sourceCString, &length)
        glCompileShader(shader)

        var status: GLint = 0
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == GL_FALSE {
            var logLength: GLint = 0
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                var log = [GLchar](repeating: 0, count: Int(logLength))
                glGetShaderInfoLog(shader, logLength, &logLength, &log)
                let message = String(cString: log)
                print("Shader compile error: \(message)")
                compileError = "Shader compile error: \(message)"
            }
            glDeleteShader(shader)
            return nil
        }
        return shader
    }

    func linkProgram(vertexShader: GLuint, fragmentShader: GLuint) -> GLuint? {
        let program = glCreateProgram()
        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)
        glLinkProgram(program)

        var status: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
        if status == GL_FALSE {
            var logLength: GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                var log = [GLchar](repeating: 0, count: Int(logLength))
                glGetProgramInfoLog(program, logLength, &logLength, &log)
                let message = String(cString: log)
                print("Program link error: \(message)")
                compileError = "Program link error: \(message)"
            }
            glDeleteProgram(program)
            return nil
        }
        return program
    }

    func queryUniforms(program: GLuint) -> ([String: GLint], [String: GLenum]) {
        var count: GLint = 0
        glGetProgramiv(program, GLenum(GL_ACTIVE_UNIFORMS), &count)

        var maxLength: GLint = 0
        glGetProgramiv(program, GLenum(GL_ACTIVE_UNIFORM_MAX_LENGTH), &maxLength)

        var locations: [String: GLint] = [:]
        var types: [String: GLenum] = [:]
        var nameBuffer = [GLchar](repeating: 0, count: Int(maxLength))

        for index in 0..<count {
            var size: GLint = 0
            var type: GLenum = 0
            var length: GLsizei = 0
            glGetActiveUniform(program, GLuint(index), GLsizei(maxLength), &length, &size, &type, &nameBuffer)
            let rawName = String(cString: nameBuffer)
            let name = rawName.replacingOccurrences(of: "[0]", with: "")
            let location = glGetUniformLocation(program, name)
            if location >= 0 {
                locations[name] = location
                types[name] = type
            } else {
                print("[PlanetGLRenderer] Warning: Uniform '\(name)' not found in program.")
            }
        }
        return (locations, types)
    }
}

// MARK: - Drawing helpers

private extension PlanetGLRenderer {
    func applyUniforms(for layer: LayerState, using program: ProgramInfo) {
        for (name, uniformValue) in layer.uniforms {
            var targetLocation = program.uniformLocations[name]
            var targetType = program.uniformTypes[name]

            if targetLocation == nil, case .buffer = uniformValue {
                let arrayName = name + "[0]"
                let arrayLocation = glGetUniformLocation(program.program, arrayName)
                if arrayLocation >= 0 {
                    targetLocation = arrayLocation
                    targetType = GLenum(GL_FLOAT_VEC4)
                }
            }

            guard let location = targetLocation else {
                continue
            }

            let type = targetType ?? GLenum(GL_FLOAT)
            setUniform(type: type, location: location, value: uniformValue)
        }
    }

    func setUniform(type: GLenum, location: GLint, value: UniformValue) {
        switch value {
        case .float(let scalar):
            glUniform1f(location, scalar)
        case .vec2(let vector):
            glUniform2f(location, vector.x, vector.y)
        case .vec3(let vector):
            glUniform3f(location, vector.x, vector.y, vector.z)
        case .vec4(let vector):
            glUniform4f(location, vector.x, vector.y, vector.z, vector.w)
        case .buffer(let buffer):
            buffer.withUnsafeBufferPointer { pointer in
                guard let base = pointer.baseAddress else { return }
                switch type {
                case GLenum(GL_FLOAT_VEC4):
                    glUniform4fv(location, GLsizei(buffer.count / 4), base)
                case GLenum(GL_FLOAT_VEC3):
                    glUniform3fv(location, GLsizei(buffer.count / 3), base)
                case GLenum(GL_FLOAT_VEC2):
                    glUniform2fv(location, GLsizei(buffer.count / 2), base)
                default:
                    glUniform1fv(location, GLsizei(buffer.count), base)
                }
            }
        }
    }
}

private extension PlanetGLRenderer {
    static let vertexShaderSource = """
    attribute vec2 aPosition;
    varying vec2 vUV;
    void main() {
        vUV = aPosition * 0.5 + 0.5;
        gl_Position = vec4(aPosition, 0.0, 1.0);
    }
    """
}
