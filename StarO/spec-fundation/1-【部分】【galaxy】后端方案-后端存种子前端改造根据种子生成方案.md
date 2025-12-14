这份文档总结了我们将 StarO 银河系生成架构迁移至 **Supabase + 客户端种子生成** 的完整技术方案。

---

# StarO 银河系“千人千面”架构设计文档

## 1. 核心设计理念

**“后端存种子，前端造银河”**

我们不存储庞大的银河系坐标数据，也不编写新的物理算法。

- **Supabase (后端)**：仅存储一个唯一的整数 `galaxy_seed`（基因种子）。
- **Swift (前端)**：利用现有的渲染引擎，通过 `Seed` 驱动 `GalaxyFactory`（工厂），确定性地生成一套独特的银河参数。

**优势**：

- **数据库零负担**：每人只占 4 字节。
- **开发低成本**：复用现有 Metal 渲染管线，无需修改核心算法。
- **体验一致性**：只要 Seed 不变，用户换设备看到的银河完全一致。

---

## 2. 后端方案 (Supabase)

### 2.1 数据库表设计

在 Supabase 中创建 `user_galaxy_settings` 表（或直接加在 `profiles` 表中）。

```sql
-- SQL 定义
create table public.user_galaxy_settings (
  user_id uuid references auth.users not null primary key, -- 关联 Auth 用户
  galaxy_seed bigint not null,                             -- 核心：决定银河形态的种子 (例如：95272023)
  created_at timestamptz default now()
);

-- 安全策略 (RLS)
alter table user_galaxy_settings enable row level security;
create policy "Users can read own settings" on user_galaxy_settings for select using (auth.uid() = user_id);

```

### 2.2 种子生成逻辑

当用户注册成功（或首次登录）时，触发生成逻辑（可放在 Edge Function 或客户端首次写入）：

- `galaxy_seed` = 随机生成一个 `Int.min` 到 `Int.max` 之间的整数。

---

## 3. 前端方案 (Swift)

### 3.1 新增文件：`GalaxyFactory.swift`

这是一个“参数翻译器”，负责将 `Seed` 转化为具体的 `GalaxyParams` 和 `GalaxyPalette`。

```swift
import SwiftUI

/// 银河工厂：负责根据种子生产独特的银河配置
struct GalaxyFactory {

    /// 输入：Seed (来自 Supabase)
    /// 输出：独特的参数配置 + 配色方案
    static func create(seed: Int) -> (GalaxyParams, GalaxyPalette) {
        // 1. 初始化随机流 (复用现有 GalaxyRandom.swift)
        var rng = SeededRandom(seed: UInt64(abs(seed)))
        var p = GalaxyParams.platformDefault()

        // 2. 形态变异 (Morphology)
        p.armCount = rng.nextInt(in: 2...7)                // 旋臂数量：2-7条
        p.spiralB = rng.nextRange(min: 0.15, max: 0.45)    // 缠绕度：越小越紧
        p.coreRadius = rng.nextRange(min: 6.0, max: 18.0)  // 核心大小
        p.armWidthScale = rng.nextRange(min: 0.6, max: 1.6)// 旋臂粗细
        p.jitterStrength = rng.nextRange(min: 5.0, max: 30.0) // 恒星离散度

        // 3. 密度变异 (Texture)
        let densityMod = rng.nextRange(min: 0.5, max: 1.2)
        p.armDensity *= densityMod
        p.coreDensity *= densityMod

        // 4. 颜色变异 (Atmosphere) - 抽取预设色盘
        let themes: [GalaxyPalette] = [
            .baseline, // 经典深蓝
            .lit,      // 高亮风格
            // 预设：翡翠绿
            GalaxyPalette(core: "#F0FFF0", ridge: "#98FB98", armBright: "#2E8B57", armEdge: "#006400", hii: "#FFD700", dust: "#002200", outer: "#001100"),
            // 预设：熔岩金
            GalaxyPalette(core: "#FFFACD", ridge: "#FFA500", armBright: "#FF4500", armEdge: "#8B0000", hii: "#FFFFFF", dust: "#220000", outer: "#110000"),
            // 预设：紫水晶
            GalaxyPalette(core: "#E6E6FA", ridge: "#D8BFD8", armBright: "#BA55D3", armEdge: "#4B0082", hii: "#00FFFF", dust: "#110022", outer: "#050011")
        ]

        let themeIndex = rng.nextInt(in: 0..<themes.count)
        let selectedPalette = themes[themeIndex]

        return (p, selectedPalette)
    }
}

// 辅助扩展：简化随机范围写法
extension SeededRandom {
    mutating func nextInt(in range: Range<Int>) -> Int {
        return range.lowerBound + Int(next() * Float(range.count))
    }
    mutating func nextRange(min: Double, max: Double) -> Double {
        return min + Double(next()) * (max - min)
    }
}

```

### 3.2 修改 `GalaxyViewModel`

在 `regenerate` 方法中接入工厂。

```swift
// StarO/Galaxy/GalaxyViewModel.swift

class GalaxyViewModel: ObservableObject {
    // 新增属性
    var userSeed: Int = 123456 // 默认值，登录后被覆盖

    func regenerate(for size: CGSize) {
        // [修改前] 使用默认参数
        // let params = self.params

        // [修改后] 使用工厂生成的参数
        let (uniqueParams, uniquePalette) = GalaxyFactory.create(seed: userSeed)

        let field = GalaxyGenerator.generateField(
            size: size,
            params: uniqueParams,   // <--- 注入
            palette: uniquePalette, // <--- 注入
            // ... 其他参数保持不变
        )
        // ...
    }

    // 新增方法供外部调用
    func updateUserSeed(_ seed: Int) {
        self.userSeed = seed
        self.lastSize = .zero // 强制下一次重绘
        // 触发 UI 更新
        objectWillChange.send()
    }
}

```

---

## 4. 参数定义与调整范围 (DNA 图谱)

此表定义了 `GalaxyFactory` 中允许随机变化的范围，确保生成的银河既独特又美观。

### ✅ 变量 (根据 Seed 随机)

|参数类别|参数名|默认值|随机区间 (Min-Max)|视觉影响|
|---|---|---|---|---|
|**形态**|`armCount`|5|**2 ~ 7**|决定是棒状、三叶草还是风车形态。|
||`spiralB`|0.29|**0.15 ~ 0.45**|决定旋臂卷得紧（蚊香）还是松（章鱼）。|
||`coreRadius`|12.0|**6.0 ~ 18.0**|决定中心亮球的大小。|
||`armWidthScale`|1.0|**0.6 ~ 1.6**|决定旋臂是丝带状还是云团状。|
|**质感**|`jitterStrength`|10.0|**5.0 ~ 30.0**|决定星星分布是规则（数学感）还是离散（自然感）。|
||`armDensity`|0.6|**0.3 ~ 0.9**|决定银河的明暗浓稠度。|
|**颜色**|`GalaxyPalette`|蓝色系|**5种预设主题**|决定整体氛围（蓝、紫、金、绿、红）。|

### ⛔️ 常量 (必须固定)

以下参数**禁止随机**，否则可能导致渲染错误或视觉崩坏：

1. `spiralA`: 螺旋数学基数。
2. `galaxyScale`: 整体缩放比例（需适配 UI）。
3. `radialDecay`: 径向衰减（防止银河边缘被切断）。
4. `densityNoiseScale`: 噪声采样率（防止云雾变成噪点）。

---

## 5. 实施步骤清单

1. **数据库**：在 Supabase 创建 `user_galaxy_settings` 表。
2. **代码创建**：新建 `GalaxyFactory.swift`，复制上文代码。
3. **代码接入**：修改 `GalaxyViewModel.swift` 的 `regenerate` 方法。
4. **数据流联调**：
    - App 启动/登录。
    - 调用 Supabase API 获取当前用户的 `galaxy_seed`。
    - 调用 `viewModel.updateUserSeed(fetchedSeed)`。
    - 调用 `viewModel.prepareIfNeeded(for: size)` 触发重绘。
5. **测试**：注册 3 个不同账号，观察是否生成了 3 个形态迥异的银河系。