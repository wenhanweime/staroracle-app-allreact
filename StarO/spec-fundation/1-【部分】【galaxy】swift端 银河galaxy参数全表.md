这是一份完整的银河形态参数表。包含了 `GalaxyParams` 结构体中的所有参数，以及代码中**硬编码的随机种子（Seed）**。

为了方便查阅，我列出了**默认值**以及在 `applyiOSTuning()` 中被修改后的 **iOS 专用值**（代码中 `StarO/Galaxy/GalaxyParams.swift` 的逻辑）。

### 🌌 银河形态与结构参数全表

|分类|参数变量名|类型|默认值|iOS 调整值|影响描述|
|---|---|---|---|---|---|
|**全局种子**|**`Main Seed`** <br>_(硬编码)_|UInt64|`0xA17C9E3`|-|**主结构种子**。决定了所有恒星的具体随机落点。目前硬编码在 `GalaxyGenerator.swift` 中，修改它会改变整个银河的随机分布模式。|
||**`Background Seed`** <br>_(硬编码)_|UInt64|`0x0BADC0DE`|-|**背景种子**。决定了背景微弱星点的随机分布。|
|**整体缩放**|`galaxyScale`|Double|0.88|-|**整体大小**。缩放整个银河在屏幕上的显示比例。|
|**螺旋几何**|`armCount`|Int|5|-|**旋臂数量**。银河拥有的螺旋臂总数。|
||`spiralA`|Double|8.0|-|**螺旋起始扩张**。控制螺旋线起始时的张开程度。|
||`spiralB`|Double|0.29|-|**螺旋缠绕度**。数值越**小**，旋臂缠绕越紧密；数值越大，旋臂越松散。|
|**旋臂形状**|`armWidthInner`|Double|29.0|-|**内侧宽度**。旋臂在靠近核心处的物理宽度。|
||`armWidthOuter`|Double|65.0|-|**外侧宽度**。旋臂在远离核心处的物理宽度。|
||`armWidthGrowth`|Double|2.5|-|**宽度增长指数**。控制宽度从内侧过渡到外侧的曲线。数值越大，外侧变宽得越快。|
||`armWidthScale`|Double|1.0|**2.9**|**宽度整体缩放**。所有旋臂宽度的倍增系数（iOS上显著加宽了旋臂）。|
||`armTransitionSoftness`|Double|3.8|**7.0**|**边缘柔和度**。控制旋臂边缘密度的衰减。数值越大，旋臂边缘越模糊自然。|
|**核心区域**|`coreRadius`|Double|12.0|-|**核心半径**。银河中心高密度球状区域的半径。|
||`coreDensity`|Double|0.7|-|**核心密度**。核心区域星星生成的概率基数。|
||`coreSizeMin`|Double|1.0|-|核心星星的最小尺寸。|
||`coreSizeMax`|Double|3.5|-|核心星星的最大尺寸。|
|**旋臂内容**|`armDensity`|Double|0.6|-|**旋臂密度**。旋臂主体区域生成星星的概率。|
||`armBaseSizeMin`|Double|0.7|-|旋臂中普通星星的最小尺寸。|
||`armBaseSizeMax`|Double|2.0|-|旋臂中普通星星的最大尺寸。|
||`armHighlightSize`|Double|5.0|-|**高亮大星尺寸**。旋臂中偶发的巨型亮星的大小。|
||`armHighlightProb`|Double|0.01|-|**高亮概率**。生成巨型亮星的几率（1%）。|
|**旋臂间隙**|`interArmDensity`|Double|0.150|-|**暗区密度**。旋臂之间空隙区域生成星星的概率。|
||`interArmSizeMin`|Double|0.6|**0.5**|间隙区域星星的最小尺寸（iOS计算值约为0.5）。|
||`interArmSizeMax`|Double|1.2|**0.675**|间隙区域星星的最大尺寸（iOS计算值约为0.675）。|
|**径向控制**|`radialDecay`|Double|0.0015|-|**径向衰减**。随着距离变远，星星密度下降的指数系数。|
||`fadeStartRadius`|Double|0.5|-|**淡出开始**。相对于最大半径的比例，开始强制减少星星。|
||`fadeEndRadius`|Double|1.3|-|**淡出结束**。相对于最大半径的比例，星星完全消失的边界。|
||`outerDensityMaintain`|Double|0.10|-|**边缘维持**。防止边缘完全变黑的最低密度下限。|
|**噪点与抖动**|`jitterStrength`|Double|10.0|**25.0**|**位置抖动**。星星偏离理想螺旋轨道的随机距离。iOS上大幅增加，使银河更弥散自然。|
||`jitterChaos`|Double|0.0|-|**混乱度**。基于噪声图的额外抖动强度。|
||`jitterChaosScale`|Double|0.0|-|混乱度噪声图的缩放比例。|
||`densityNoiseScale`|Double|0.018|-|**密度云团大小**。控制明暗斑块（尘埃感）的噪声纹理大小。|
||`densityNoiseStrength`|Double|0.8|-|**密度云团强度**。控制明暗斑块的对比度。|
|**背景星**|`backgroundDensity`|Double|0.00024|-|**背景密度**。填充整个画布背景的星星密度。|
||`backgroundSizeVariation`|Double|2.0|-|背景星星的大小随机变化幅度。|
|**尺寸倍增**|`armStarSizeMultiplier`|Double|1.0|**1.2**|**核心与旋臂放大**。整体放大核心和旋臂内星星的尺寸。|
||`interArmStarSizeMultiplier`|Double|1.0|**1.35**|**暗区放大**。整体放大旋臂间隙星星的尺寸。|
||`backgroundStarSizeMultiplier`|Double|1.0|**1.1**|**背景放大**。整体放大背景星星的尺寸。|

### 补充说明：代码中的硬编码 Seed

如果您希望能够通过参数控制银河的随机形态（即星星的具体位置分布），建议修改 `GalaxyParams` 和 `GalaxyGenerator`，将以下两个硬编码值参数化：

1. **Main Seed**: `StarO/Galaxy/GalaxyGenerator.swift` 第 89 行左右
    
    ```swift
    let rng = seeded(0xA17C9E3)
    
    ```
    
2. **Background Seed**: `StarO/Galaxy/GalaxyGenerator.swift` 第 185 行左右
    
    ```swift
    let backgroundSeed: UInt64 = 0x0BADC0DE
    
    ```