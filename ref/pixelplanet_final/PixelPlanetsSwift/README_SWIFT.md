# PixelPlanetsSwift

Swift port-in-progress of the Pixel Planets procedural shader controls. Mirrors the architecture of the React/Vite prototype by providing:

- `PixelPlanetsCore` library with shaders packaged as resources, deterministic RNG, palette utilities, and the `PlanetBase` abstraction used by all presets.
- `PlanetLibrary` factory that enumerates the available presets (currently Terran Wet / Rivers).
- `PixelPlanetsSwiftCLI` executable that instantiates the first preset, mutates a few uniforms, randomizes colors, and dumps diagnostic info to the console.

## Building

```bash
cd PixelPlanetsSwift
SWIFT_BUILD_DIR=$PWD/.build \
CLANG_MODULE_CACHE_PATH=$PWD/.clang-module-cache \
swift build
```

The extra env vars keep the build inside the workspace so sandboxed environments don\'t try to touch `~/Library`.

## Running the CLI demo

```
SWIFT_BUILD_DIR=$PWD/.build \
CLANG_MODULE_CACHE_PATH=$PWD/.clang-module-cache \
swift run PixelPlanetsSwiftCLI
```

This prints the available presets, the layer/control metadata, random palette info, and the updated land layer time uniform. (If sandbox execution is blocked, the `swift run` command may need to be executed outside the restricted environment; see captured output in `docs/swift-cli-output.txt`.)

## Next steps toward SwiftUI

1. Create a SwiftUI app target (`PixelPlanetsSwiftUI`) that uses a `MetalKit` or `CoreImage` backed view to draw the fragment shaders. The React hooks already show how to bind uniforms per layer; this logic can be moved into a `PlanetRenderer` class that uploads uniforms to a Metal pipeline.
2. Re-implement the control panel using SwiftUI controls bound to the `PlanetBase` interface (seed field, sliders, toggles, color pickers). The `uniformControls` metadata is already structured for auto-generated UI.
3. Add multi-planet selection with `Picker` bound to `PlanetLibrary.allPlanetNames`.
4. Port the rest of the Godot presets by translating each TypeScript planet file into a Swift subclass of `PlanetBase` and registering them in `PlanetLibrary`.
5. Once rendering is functional, add snapshot tests or reference image comparisons using XCTest for deterministic seeds to catch shader regressions.

## Tests

A placeholder test target (`PixelPlanetsCoreTests`) is wired up; unit tests can assert palette/RNG determinism, uniform clamping, and serialization behavior once more functionality is added.
