# PixelPlanets 原版 vs 当前版本 代码级对比（函数/参数）

说明：脚本自动生成，包含：
- 概要（relativeScale、guiZoom）
- 函数覆写（是否存在）
- UniformControls（min/max/step）
- 每个 Layer 的 shaderPath、ColorBindings、uniform 默认值


## AsteroidPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Asteroid.octaves | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Asteroid.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Asteroid.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: Asteroid

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | asteroid/asteroid.frag | asteroid/asteroid.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| colors | .buffer(...) | .buffer(...) | SAME |
| light_origin | .vec2(Vec2(0, 0)) | .vec2(Vec2(0, 0)) | SAME |
| octaves | .float(2) | .float(2) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.567) | .float(1.567) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(5.294) | .float(5.294) | SAME |
| time_speed | .float(0.4) | .float(0.4) | SAME |

## BlackHolePlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 2 | 2 | SAME |
| guiZoom | 2 | 2 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| BlackHole.light_width | ('0', '0.2', '0.005') | ('0', '0.2', '0.005') | SAME |
| BlackHole.radius | ('0.1', '0.5', '0.005') | ('0.1', '0.5', '0.005') | SAME |
| Disk.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Disk.disk_width | ('0.01', '0.2', '0.005') | ('0.01', '0.2', '0.005') | SAME |
| Disk.n_colors | ('3', '7', '1') | ('3', '7', '1') | SAME |
| Disk.ring_perspective | ('1', '20', '0.2') | ('1', '20', '0.2') | SAME |
| Disk.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| Disk.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: BlackHole

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | black-hole/core.frag | black-hole/core.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| colors | .buffer(...) | .buffer(...) | SAME |
| light_width | .float(0.028) | .float(0.028) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| radius | .float(0.247) | .float(0.247) | SAME |

### Layer: Disk

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | black-hole/ring.frag | black-hole/ring.frag | SAME |
| ColorBindings | [('colors', '5')] | [('colors', '5')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(3) | .float(3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| disk_width | .float(0.065) | .float(0.065) | SAME |
| light_origin | .vec2(Vec2(0.607, 0.444)) | .vec2(Vec2(0.607, 0.444)) | SAME |
| n_colors | .float(5) | .float(5) | SAME |
| pixels | .float(300) | .float(300) | SAME |
| ring_perspective | .float(14) | .float(14) | SAME |
| rotation | .float(0.766) | .float(0.766) | SAME |
| seed | .float(8.175) | .float(8.175) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(6.598) | .float(6.598) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.2) | .float(0.2) | SAME |

## CircularGalaxyPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 2 | 2 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Galaxy.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Galaxy.dither_size | ('0', '6', '0.1') | ('0', '6', '0.1') | SAME |
| Galaxy.layer_height | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Galaxy.n_layers | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Galaxy.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| Galaxy.swirl | ('-12', '12', '0.5') | ('-12', '12', '0.5') | SAME |
| Galaxy.time_speed | ('0', '4', '0.05') | ('0', '4', '0.05') | SAME |
| Galaxy.zoom | ('0.5', '2.5', '0.05') | ('0.5', '2.5', '0.05') | SAME |
| GalaxyLinear.branch_count | ('2', '8', '1') | ('2', '8', '1') | SAME |
| GalaxyLinear.branch_sharpness | ('1', '6', '0.1') | ('1', '6', '0.1') | SAME |
| GalaxyLinear.flicker_strength | ('0', '1', '0.05') | ('0', '1', '0.05') | SAME |
| GalaxyLinear.halo_softness | ('0.05', '0.4', '0.01') | ('0.05', '0.4', '0.01') | SAME |
| GalaxyLinear.morph_speed | ('0.1', '1', '0.02') | ('0.1', '1', '0.02') | SAME |
| GalaxyLinear.rotation_speed | ('0', '2', '0.05') | ('0', '2', '0.05') | SAME |
| GalaxyLinear.spark_scale | ('0.5', '2.5', '0.05') | ('0.5', '2.5', '0.05') | SAME |
| GalaxyLinear.time_speed | ('0', '2', '0.05') | ('0', '2', '0.05') | SAME |

- Layers

### Layer: Galaxy

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | galaxy/galaxy.frag | galaxy/galaxy.frag | SAME |
| ColorBindings | [('colors', '7')] | [('colors', '7')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| branch_count | .float(4) | .float(4) | SAME |
| branch_sharpness | .float(3) | .float(3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| flicker_strength | .float(0.7) | .float(0.7) | SAME |
| halo_softness | .float(0.2) | .float(0.2) | SAME |
| morph_speed | .float(0.4) | .float(0.4) | SAME |
| n_colors | .float(6) | .float(6) | SAME |
| pixels | .float(220) | .float(220) | SAME |
| rotation_speed | .float(1.2) | .float(1.2) | SAME |
| spark_scale | .float(1.2) | .float(1.2) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.8) | .float(0.8) | SAME |

### Layer: GalaxyLinear

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | galaxy/linear_twinkle.frag | galaxy/linear_twinkle.frag | SAME |
| ColorBindings | [('colors', '7')] | [('colors', '7')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| branch_count | .float(4) | .float(4) | SAME |
| branch_sharpness | .float(3) | .float(3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| flicker_strength | .float(0.7) | .float(0.7) | SAME |
| halo_softness | .float(0.2) | .float(0.2) | SAME |
| morph_speed | .float(0.4) | .float(0.4) | SAME |
| n_colors | .float(6) | .float(6) | SAME |
| pixels | .float(220) | .float(220) | SAME |
| rotation_speed | .float(1.2) | .float(1.2) | SAME |
| spark_scale | .float(1.2) | .float(1.2) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.8) | .float(0.8) | SAME |

## DryTerranPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Land.OCTAVES | ('1', '12', '1') | ('1', '12', '1') | SAME |
| Land.dither_size | ('0', '6', '0.1') | ('0', '6', '0.1') | SAME |
| Land.light_distance1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.light_distance2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.size | ('1', '20', '0.1') | ('1', '20', '0.1') | SAME |
| Land.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: Land

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | dry-terran/land.frag | dry-terran/land.frag | SAME |
| ColorBindings | [('colors', '5')] | [('colors', '5')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(3) | .float(3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(2) | .float(2) | SAME |
| light_distance1 | .float(0.362) | .float(0.362) | SAME |
| light_distance2 | .float(0.525) | .float(0.525) | SAME |
| light_origin | .vec2(Vec2(0.4, 0.3)) | .vec2(Vec2(0.4, 0.3)) | SAME |
| n_colors | .float(5) | .float(5) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.175) | .float(1.175) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(8) | .float(8) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.1) | .float(0.1) | SAME |

## GalaxyPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 2.5 | 2.5 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Galaxy.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Galaxy.dither_size | ('0', '6', '0.1') | ('0', '6', '0.1') | SAME |
| Galaxy.layer_height | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Galaxy.n_layers | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Galaxy.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| Galaxy.swirl | ('-12', '12', '0.5') | ('-12', '12', '0.5') | SAME |
| Galaxy.tilt | ('1', '6', '0.1') | ('1', '6', '0.1') | SAME |
| Galaxy.time_speed | ('0', '4', '0.05') | ('0', '4', '0.05') | SAME |
| Galaxy.zoom | ('0.5', '3', '0.05') | ('0.5', '3', '0.05') | SAME |

- Layers

### Layer: Galaxy

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | galaxy/galaxy.frag | galaxy/galaxy.frag | SAME |
| ColorBindings | [('colors', '7')] | [('colors', '7')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(1) | .float(1) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(2) | .float(2) | SAME |
| layer_height | .float(0.4) | .float(0.4) | SAME |
| n_colors | .float(6) | .float(6) | SAME |
| n_layers | .float(4) | .float(4) | SAME |
| pixels | .float(200) | .float(200) | SAME |
| rotation | .float(0.674) | .float(0.674) | SAME |
| seed | .float(5.881) | .float(5.881) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(7) | .float(7) | SAME |
| swirl | .float(-9) | .float(-9) | SAME |
| tilt | .float(3) | .float(3) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(1) | .float(1) | SAME |
| zoom | .float(1.375) | .float(1.375) | SAME |

## GasPlanetLayersPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 3 | 3 | SAME |
| guiZoom | 2.5 | 2.5 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| GasLayers.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| GasLayers.bands | ('0', '2', '0.01') | ('0', '2', '0.01') | SAME |
| GasLayers.cloud_cover | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| GasLayers.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| GasLayers.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| GasLayers.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| GasLayers.stretch | ('1', '3', '0.05') | ('1', '3', '0.05') | SAME |
| GasLayers.time_speed | ('0', '0.2', '0.005') | ('0', '0.2', '0.005') | SAME |
| Ring.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Ring.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Ring.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Ring.ring_perspective | ('1', '20', '0.1') | ('1', '20', '0.1') | SAME |
| Ring.ring_width | ('0.01', '0.3', '0.005') | ('0.01', '0.3', '0.005') | SAME |
| Ring.scale_rel_to_planet | ('1', '10', '0.1') | ('1', '10', '0.1') | SAME |
| Ring.size | ('1', '20', '0.1') | ('1', '20', '0.1') | SAME |
| Ring.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: GasLayers

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | gas-planet-layers/layers.frag | gas-planet-layers/layers.frag | SAME |
| ColorBindings | [('colors', '3'), ('dark_colors', '3')] | [('colors', '3'), ('dark_colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(3) | .float(3) | SAME |
| bands | .float(0.892) | .float(0.892) | SAME |
| cloud_cover | .float(0.61) | .float(0.61) | SAME |
| cloud_curve | .float(1.376) | .float(1.376) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dark_colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.52) | .float(0.52) | SAME |
| light_border_2 | .float(0.62) | .float(0.62) | SAME |
| light_origin | .vec2(Vec2(-0.1, 0.3)) | .vec2(Vec2(-0.1, 0.3)) | SAME |
| n_colors | .float(3) | .float(3) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(6.314) | .float(6.314) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(10.107) | .float(10.107) | SAME |
| stretch | .float(2.204) | .float(2.204) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.05) | .float(0.05) | SAME |

### Layer: Ring

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | gas-planet-layers/ring.frag | gas-planet-layers/ring.frag | SAME |
| ColorBindings | [('colors', '3'), ('dark_colors', '3')] | [('colors', '3'), ('dark_colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(4) | .float(4) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dark_colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.52) | .float(0.52) | SAME |
| light_border_2 | .float(0.62) | .float(0.62) | SAME |
| light_origin | .vec2(Vec2(-0.1, 0.3)) | .vec2(Vec2(-0.1, 0.3)) | SAME |
| n_colors | .float(3) | .float(3) | SAME |
| pixels | .float(300) | .float(300) | SAME |
| ring_perspective | .float(6) | .float(6) | SAME |
| ring_width | .float(0.127) | .float(0.127) | SAME |
| rotation | .float(0.7) | .float(0.7) | SAME |
| scale_rel_to_planet | .float(6) | .float(6) | SAME |
| seed | .float(8.461) | .float(8.461) | SAME |
| size | .float(15) | .float(15) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.2) | .float(0.2) | SAME |

## GasPlanetPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Cloud.OCTAVES | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Cloud.cloud_cover | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.cloud_curve | ('0.5', '2', '0.05') | ('0.5', '2', '0.05') | SAME |
| Cloud.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| Cloud.stretch | ('0.5', '3', '0.05') | ('0.5', '3', '0.05') | SAME |
| Cloud.time_speed | ('-1', '1', '0.01') | ('-1', '1', '0.01') | SAME |
| Cloud2.OCTAVES | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Cloud2.cloud_cover | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud2.cloud_curve | ('0.5', '2', '0.05') | ('0.5', '2', '0.05') | SAME |
| Cloud2.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud2.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud2.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| Cloud2.stretch | ('0.5', '3', '0.05') | ('0.5', '3', '0.05') | SAME |
| Cloud2.time_speed | ('-1', '1', '0.01') | ('-1', '1', '0.01') | SAME |

- Layers

### Layer: Cloud

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | common/clouds.frag | common/clouds.frag | SAME |
| ColorBindings | [('colors', '4')] | [('colors', '4')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(5) | .float(5) | SAME |
| cloud_cover | .float(0) | .float(0) | SAME |
| cloud_curve | .float(1.3) | .float(1.3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.692) | .float(0.692) | SAME |
| light_border_2 | .float(0.666) | .float(0.666) | SAME |
| light_origin | .vec2(Vec2(0.25, 0.25)) | .vec2(Vec2(0.25, 0.25)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(5.939) | .float(5.939) | SAME |
| size | .float(9) | .float(9) | SAME |
| stretch | .float(1) | .float(1) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.7) | .float(0.7) | SAME |

### Layer: Cloud2

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | common/clouds.frag | common/clouds.frag | SAME |
| ColorBindings | [('colors', '4')] | [('colors', '4')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(5) | .float(5) | SAME |
| cloud_cover | .float(0.538) | .float(0.538) | SAME |
| cloud_curve | .float(1.3) | .float(1.3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.439) | .float(0.439) | SAME |
| light_border_2 | .float(0.746) | .float(0.746) | SAME |
| light_origin | .vec2(Vec2(0.25, 0.25)) | .vec2(Vec2(0.25, 0.25)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(5.939) | .float(5.939) | SAME |
| size | .float(9) | .float(9) | SAME |
| stretch | .float(1) | .float(1) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.47) | .float(0.47) | SAME |

## IceWorldPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Clouds.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Clouds.cloud_cover | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Clouds.cloud_curve | ('0.5', '2', '0.05') | ('0.5', '2', '0.05') | SAME |
| Clouds.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Clouds.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Clouds.size | ('1', '10', '0.1') | ('1', '10', '0.1') | SAME |
| Clouds.stretch | ('1', '3', '0.05') | ('1', '3', '0.05') | SAME |
| Clouds.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Lakes.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Lakes.lake_cutoff | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Lakes.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Lakes.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Lakes.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Lakes.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Land.dither_size | ('0', '6', '0.1') | ('0', '6', '0.1') | SAME |
| Land.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Land.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: Clouds

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | common/clouds.frag | common/clouds.frag | SAME |
| ColorBindings | [('colors', '4')] | [('colors', '4')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(4) | .float(4) | SAME |
| cloud_cover | .float(0.546) | .float(0.546) | SAME |
| cloud_curve | .float(1.3) | .float(1.3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.566) | .float(0.566) | SAME |
| light_border_2 | .float(0.781) | .float(0.781) | SAME |
| light_origin | .vec2(Vec2(0.3, 0.3)) | .vec2(Vec2(0.3, 0.3)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.14) | .float(1.14) | SAME |
| size | .float(4) | .float(4) | SAME |
| stretch | .float(2.5) | .float(2.5) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.1) | .float(0.1) | SAME |

### Layer: Lakes

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | ice-world/lakes.frag | ice-world/lakes.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(3) | .float(3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| lake_cutoff | .float(0.55) | .float(0.55) | SAME |
| light_border_1 | .float(0.024) | .float(0.024) | SAME |
| light_border_2 | .float(0.047) | .float(0.047) | SAME |
| light_origin | .vec2(Vec2(0.3, 0.3)) | .vec2(Vec2(0.3, 0.3)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.14) | .float(1.14) | SAME |
| size | .float(10) | .float(10) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.2) | .float(0.2) | SAME |

### Layer: Land

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | landmasses/water.frag | landmasses/water.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(2) | .float(2) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(2) | .float(2) | SAME |
| light_border_1 | .float(0.48) | .float(0.48) | SAME |
| light_border_2 | .float(0.632) | .float(0.632) | SAME |
| light_origin | .vec2(Vec2(0.3, 0.3)) | .vec2(Vec2(0.3, 0.3)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.036) | .float(1.036) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(8) | .float(8) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.25) | .float(0.25) | SAME |

## LandMassesPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Cloud.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Cloud.cloud_cover | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.cloud_curve | ('0.5', '2', '0.05') | ('0.5', '2', '0.05') | SAME |
| Cloud.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Cloud.stretch | ('1', '3', '0.05') | ('1', '3', '0.05') | SAME |
| Cloud.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.OCTAVES | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Land.land_cutoff | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Land.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Water.OCTAVES | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Water.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Water.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Water.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Water.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: Cloud

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | common/clouds.frag | common/clouds.frag | SAME |
| ColorBindings | [('colors', '4')] | [('colors', '4')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(2) | .float(2) | SAME |
| cloud_cover | .float(0.415) | .float(0.415) | SAME |
| cloud_curve | .float(1.3) | .float(1.3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.52) | .float(0.52) | SAME |
| light_border_2 | .float(0.62) | .float(0.62) | SAME |
| light_origin | .vec2(Vec2(0.39, 0.39)) | .vec2(Vec2(0.39, 0.39)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(5.939) | .float(5.939) | SAME |
| size | .float(7.745) | .float(7.745) | SAME |
| stretch | .float(2) | .float(2) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.47) | .float(0.47) | SAME |

### Layer: Land

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | landmasses/land.frag | landmasses/land.frag | SAME |
| ColorBindings | [('colors', '4')] | [('colors', '4')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(6) | .float(6) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(2) | .float(2) | SAME |
| land_cutoff | .float(0.633) | .float(0.633) | SAME |
| light_border_1 | .float(0.32) | .float(0.32) | SAME |
| light_border_2 | .float(0.534) | .float(0.534) | SAME |
| light_origin | .vec2(Vec2(0.39, 0.39)) | .vec2(Vec2(0.39, 0.39)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0.2) | .float(0.2) | SAME |
| seed | .float(7.947) | .float(7.947) | SAME |
| size | .float(4.292) | .float(4.292) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.2) | .float(0.2) | SAME |

### Layer: Water

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | landmasses/water.frag | landmasses/water.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(3) | .float(3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(2) | .float(2) | SAME |
| light_border_1 | .float(0.4) | .float(0.4) | SAME |
| light_border_2 | .float(0.6) | .float(0.6) | SAME |
| light_origin | .vec2(Vec2(0.39, 0.39)) | .vec2(Vec2(0.39, 0.39)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(10.0) | .float(10.0) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(5.228) | .float(5.228) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.1) | .float(0.1) | SAME |

## LavaWorldPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Craters.light_border | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Craters.size | ('1', '10', '0.1') | ('1', '10', '0.1') | SAME |
| Craters.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Land.dither_size | ('0', '6', '0.1') | ('0', '6', '0.1') | SAME |
| Land.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| Land.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| LavaRivers.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| LavaRivers.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| LavaRivers.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| LavaRivers.river_cutoff | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| LavaRivers.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| LavaRivers.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: Craters

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | no-atmosphere/craters.frag | no-atmosphere/craters.frag | SAME |
| ColorBindings | [('colors', '2')] | [('colors', '2')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border | .float(0.4) | .float(0.4) | SAME |
| light_origin | .vec2(Vec2(0.3, 0.3)) | .vec2(Vec2(0.3, 0.3)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.561) | .float(1.561) | SAME |
| size | .float(3.5) | .float(3.5) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.2) | .float(0.2) | SAME |

### Layer: Land

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | no-atmosphere/ground.frag | no-atmosphere/ground.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(3) | .float(3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(2) | .float(2) | SAME |
| light_border_1 | .float(0.4) | .float(0.4) | SAME |
| light_border_2 | .float(0.6) | .float(0.6) | SAME |
| light_origin | .vec2(Vec2(0.3, 0.3)) | .vec2(Vec2(0.3, 0.3)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.551) | .float(1.551) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(10) | .float(10) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.2) | .float(0.2) | SAME |

### Layer: LavaRivers

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | lava-world/rivers.frag | lava-world/rivers.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(4) | .float(4) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.019) | .float(0.019) | SAME |
| light_border_2 | .float(0.036) | .float(0.036) | SAME |
| light_origin | .vec2(Vec2(0.3, 0.3)) | .vec2(Vec2(0.3, 0.3)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| river_cutoff | .float(0.579) | .float(0.579) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(2.527) | .float(2.527) | SAME |
| size | .float(10) | .float(10) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.2) | .float(0.2) | SAME |

## NoAtmospherePlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Craters.light_border | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Craters.size | ('1', '10', '0.1') | ('1', '10', '0.1') | SAME |
| Craters.time_speed | ('0', '0.1', '0.001') | ('0', '0.1', '0.001') | SAME |
| Ground.OCTAVES | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Ground.dither_size | ('0', '6', '0.1') | ('0', '6', '0.1') | SAME |
| Ground.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Ground.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Ground.size | ('1', '15', '0.1') | ('1', '15', '0.1') | SAME |
| Ground.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: Craters

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | no-atmosphere/craters.frag | no-atmosphere/craters.frag | SAME |
| ColorBindings | [('colors', '2')] | [('colors', '2')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border | .float(0.465) | .float(0.465) | SAME |
| light_origin | .vec2(Vec2(0.25, 0.25)) | .vec2(Vec2(0.25, 0.25)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(4.517) | .float(4.517) | SAME |
| size | .float(5) | .float(5) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.001) | .float(0.001) | SAME |

### Layer: Ground

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | no-atmosphere/ground.frag | no-atmosphere/ground.frag | SAME |
| ColorBindings | [('colors', '3')] | [('colors', '3')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(4) | .float(4) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(2) | .float(2) | SAME |
| light_border_1 | .float(0.615) | .float(0.615) | SAME |
| light_border_2 | .float(0.729) | .float(0.729) | SAME |
| light_origin | .vec2(Vec2(0.25, 0.25)) | .vec2(Vec2(0.25, 0.25)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(1.012) | .float(1.012) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(8) | .float(8) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.4) | .float(0.4) | SAME |

## RiversPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 1 | 1 | SAME |
| guiZoom | 1 | 1 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Cloud.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Cloud.cloud_cover | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.cloud_curve | ('0.5', '2', '0.05') | ('0.5', '2', '0.05') | SAME |
| Cloud.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Cloud.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Cloud.stretch | ('0.5', '3', '0.05') | ('0.5', '3', '0.05') | SAME |
| Cloud.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.OCTAVES | ('1', '8', '1') | ('1', '8', '1') | SAME |
| Land.dither_size | ('0', '6', '0.1') | ('0', '6', '0.1') | SAME |
| Land.light_border_1 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.light_border_2 | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.river_cutoff | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| Land.size | ('1', '12', '0.1') | ('1', '12', '0.1') | SAME |
| Land.time_speed | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |

- Layers

### Layer: Cloud

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | common/clouds.frag | common/clouds.frag | SAME |
| ColorBindings | [('colors', '4')] | [('colors', '4')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(2) | .float(2) | SAME |
| cloud_cover | .float(0.47) | .float(0.47) | SAME |
| cloud_curve | .float(1.3) | .float(1.3) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| light_border_1 | .float(0.52) | .float(0.52) | SAME |
| light_border_2 | .float(0.62) | .float(0.62) | SAME |
| light_origin | .vec2(Vec2(0.39, 0.39)) | .vec2(Vec2(0.39, 0.39)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| rotation | .float(0) | .float(0) | SAME |
| seed | .float(5.939) | .float(5.939) | SAME |
| size | .float(7.315) | .float(7.315) | SAME |
| stretch | .float(2) | .float(2) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.1) | .float(0.1) | SAME |

### Layer: Land

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| shaderPath | rivers/land.frag | rivers/land.frag | SAME |
| ColorBindings | [('colors', '6')] | [('colors', '6')] | SAME |

| uniform | 原版默认值 | 当前默认值 | 状态 |
|---|---|---|---|
| OCTAVES | .float(6) | .float(6) | SAME |
| colors | .buffer(...) | .buffer(...) | SAME |
| dither_size | .float(3.951) | .float(3.951) | SAME |
| light_border_1 | .float(0.287) | .float(0.287) | SAME |
| light_border_2 | .float(0.476) | .float(0.476) | SAME |
| light_origin | .vec2(Vec2(0.39, 0.39)) | .vec2(Vec2(0.39, 0.39)) | SAME |
| pixels | .float(100) | .float(100) | SAME |
| river_cutoff | .float(0.368) | .float(0.368) | SAME |
| rotation | .float(0.2) | .float(0.2) | SAME |
| seed | .float(8.98) | .float(8.98) | SAME |
| should_dither | .float(1) | .float(1) | SAME |
| size | .float(4.6) | .float(4.6) | SAME |
| time | .float(0) | .float(0) | SAME |
| time_speed | .float(0.1) | .float(0.1) | SAME |

## StarPlanet.swift

| 项 | 原版 | 当前 | 状态 |
|---|---|---|---|
| relativeScale | 2 | 2 | SAME |
| guiZoom | 2 | 2 | SAME |

- 函数覆写

| 函数 | 原版 | 当前 | 状态 |
|---|---|---|---|
| isDitherEnabled | Y | Y | SAME |
| randomizeColors | Y | Y | SAME |
| setCustomTime | Y | Y | SAME |
| setDither | Y | Y | SAME |
| setLight | Y | Y | SAME |
| setPixels | Y | Y | SAME |
| setRotation | Y | Y | SAME |
| setSeed | Y | Y | SAME |
| updateTime | Y | Y | SAME |

- UniformControls

| layer.uniform | 原版(min,max,step) | 当前(min,max,step) | 状态 |
|---|---|---|---|
| Blobs.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Blobs.circle_amount | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Blobs.circle_size | ('0.5', '2', '0.05') | ('0.5', '2', '0.05') | SAME |
| Blobs.size | ('1', '10', '0.1') | ('1', '10', '0.1') | SAME |
| Blobs.time_speed | ('0', '0.3', '0.005') | ('0', '0.3', '0.005') | SAME |
| Star.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| Star.TILES | ('1', '4', '1') | ('1', '4', '1') | SAME |
| Star.n_colors | ('2', '6', '1') | ('2', '6', '1') | SAME |
| Star.size | ('1', '10', '0.1') | ('1', '10', '0.1') | SAME |
| Star.time_speed | ('0', '0.2', '0.005') | ('0', '0.2', '0.005') | SAME |
| StarFlares.OCTAVES | ('1', '6', '1') | ('1', '6', '1') | SAME |
| StarFlares.circle_amount | ('1', '6', '1') | ('1', '6', '1') | SAME |
| StarFlares.circle_scale | ('0.5', '3', '0.05') | ('0.5', '3', '0.05') | SAME |
| StarFlares.scale | ('0.5', '3', '0.05') | ('0.5', '3', '0.05') | SAME |
| StarFlares.size | ('0.5', '6', '0.1') | ('0.5', '6', '0.1') | SAME |
| StarFlares.storm_dither_width | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| StarFlares.storm_width | ('0', '1', '0.01') | ('0', '1', '0.01') | SAME |
| StarFlares.time_speed | ('0', '0.3', '0.005') | ('0', '0.3', '0.005') | SAME |
| TwinkleCore.size | ('1', '10', '0.1') | ('1', '10', '0.1') | SAME |
| TwinkleCore.time_speed | ('0', '0.2', '0.005') | ('0', '0.2', '0.005') | SAME |
| TwinkleGlow.branch_count | ('2', '6', '1') | ('2', '6', '1') | SAME |
| TwinkleGlow.flicker_strength | ('0', '1', '0.05') | ('0', '1', '0.05') | SAME |
| TwinkleGlow.halo_softness | ('0.05', '0.3', '0.01') | ('0.05', '0.3', '0.01') | SAME |
| TwinkleGlow.rotation_speed | ('0', '2', '0.05') | ('0', '2', '0.05') | SAME |
| TwinkleGlow.spark_scale | ('0.6', '2.5', '0.05') | ('0.6', '2.5', '0.05') | SAME |
| TwinkleGlow.spark_sharpness | ('1', '6', '0.1') | ('1', '6', '0.1') | SAME |
| TwinkleGlow.star_radius | ('0.3', '0.6', '0.01') | ('0.3', '0.6', '0.01') | SAME |
| TwinkleGlow.time_speed | ('0.2', '4', '0.05') | ('0.2', '4', '0.05') | SAME |

- Layers