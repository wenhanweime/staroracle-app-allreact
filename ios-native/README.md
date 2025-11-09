# StarOracle Native Migration

该目录包含正在构建的纯 Swift 原生版本工程骨架。结构与规划如下：

- `StarOracleApp/`：SwiftUI 主应用 Target，占位于 `Package.swift` 中，后续将转为 Xcode iOS App。
- `Packages/`
  - `StarOracleCore/`：基础数据模型与算法。
  - `StarOracleServices/`：AI、音效、触觉等服务层。
  - `StarOracleFeatures/`：星卡、聊天、银河等业务 Feature。
  - `StarOracleUIComponents/`：通用 SwiftUI 组件库。

每个子目录目前均以 Swift Package Library 的形式初始化，后续会逐步补充具体实现与单元测试。
