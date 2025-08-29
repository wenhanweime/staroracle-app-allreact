# UI元素状态和位置记录表

## 位置描述方法说明

基于行业最佳实践，本文档采用**边距定位+约束关系**的混合描述方法：

### **主要描述方式**
- **边距定位**: 描述组件到容器边缘的距离（如：bottom: 20px, leading: 16px）
- **约束关系**: 描述组件间的相对关系（如：浮窗.top = 输入框.bottom + 10px）
- **安全区适配**: 基于safeAreaLayoutGuide的相对定位

### **辅助验证方式**  
- **绝对坐标**: 用于精确验证和调试（如：(16, 750)）
- **具体设备示例**: 提供真实像素值参考

---

## 坐标系统说明
- **参考系**: iOS UIKit坐标系，左上角原点(0,0)
- **X轴**: 向右为正，Y轴向下为正
- **安全区**: 使用safeAreaLayoutGuide作为主要定位参考
- **单位**: 像素(px) / 点(pt)

---

## 屏幕基础参数

| 参数 | 数值 | 绝对坐标 | 说明 |
|------|------|----------|------|
| 屏幕宽度 | screenWidth | - | 设备屏幕宽度 |
| 屏幕高度 | screenHeight | - | 设备屏幕高度 |
| 安全区顶部 | safeAreaTop | (0, 0) → (screenWidth, safeAreaTop) | 刘海/动态岛区域 |
| 安全区底部 | safeAreaBottom | (0, screenHeight-safeAreaBottom) → (screenWidth, screenHeight) | Home指示器区域 |
| 可用区域高度 | screenHeight - safeAreaTop - safeAreaBottom | - | 实际可用显示区域 |

### 绝对坐标参考点

| 参考点 | 绝对坐标 | 说明 |
|--------|----------|------|
| 屏幕左上角 | (0, 0) | iOS坐标系原点 |
| 屏幕右上角 | (screenWidth, 0) | 屏幕宽度边界 |
| 屏幕左下角 | (0, screenHeight) | 屏幕高度边界 |
| 屏幕右下角 | (screenWidth, screenHeight) | 屏幕完整尺寸 |
| 安全区左上角 | (0, safeAreaTop) | 可用区域起始点 |
| 安全区右下角 | (screenWidth, screenHeight - safeAreaBottom) | 可用区域结束点 |

---

## InputDrawer（输入框）组件

### 基础属性
| 属性 | 数值 | 说明 |
|------|------|------|
| 高度 | 48px | 固定高度，匹配Web版h-12 |
| 左边距 | leading: 16px | 距离安全区左边缘 |
| 右边距 | trailing: 16px | 距离安全区右边缘 |
| 宽度 | 容器宽度 - 32px | 自动计算实际宽度 |

### 位置状态详表

#### 1. 默认状态（无浮窗）
**边距定位（主要）**
| 边距类型 | 数值 | Auto Layout约束 | 说明 |
|----------|------|----------------|------|
| 底边距 | bottom: 20px | safeAreaLayoutGuide.bottomAnchor - 20 | 距离安全区底部20px |
| 左边距 | leading: 16px | leadingAnchor + 16 | 距离屏幕左边缘16px |
| 右边距 | trailing: 16px | trailingAnchor - 16 | 距离屏幕右边缘16px |
| 高度约束 | height: 48px | heightAnchor = 48 | 固定高度48px |

**约束关系**
- `inputDrawer.bottomAnchor = safeAreaLayoutGuide.bottomAnchor - 20`
- `inputDrawer.leadingAnchor = superview.leadingAnchor + 16`
- `inputDrawer.trailingAnchor = superview.trailingAnchor - 16`

**验证坐标**: (16, screenHeight-safeAreaBottom-68) → (screenWidth-16, screenHeight-safeAreaBottom-20)

#### 2. 收缩状态（有浮窗collapsed）
**边距定位（主要）**
| 边距类型 | 数值 | Auto Layout约束 | 说明 |
|----------|------|----------------|------|
| 底边距 | bottom: 40px | safeAreaLayoutGuide.bottomAnchor - 40 | 降低整体高度50px |
| 左边距 | leading: 16px | leadingAnchor + 16 | 保持左边距 |
| 右边距 | trailing: 16px | trailingAnchor - 16 | 保持右边距 |
| 高度约束 | height: 48px | heightAnchor = 48 | 高度不变 |

**约束关系**
- `inputDrawer.bottomAnchor = safeAreaLayoutGuide.bottomAnchor - 40`
- 水平约束保持不变

**验证坐标**: (16, screenHeight-safeAreaBottom-88) → (screenWidth-16, screenHeight-safeAreaBottom-40)

#### 3. 键盘弹出状态
**边距定位（主要）**
| 边距类型 | 计算方式 | Auto Layout约束 | 说明 |
|----------|----------|----------------|------|
| 键盘上边距 | keyboardTop: 16px | keyboardLayoutGuide.topAnchor - 16 | 距离键盘顶部16px |
| 左边距 | leading: 16px | leadingAnchor + 16 | 保持左边距 |
| 右边距 | trailing: 16px | trailingAnchor - 16 | 保持右边距 |
| 高度约束 | height: 48px | heightAnchor = 48 | 高度不变 |

**约束关系**
- `inputDrawer.bottomAnchor = keyboardLayoutGuide.topAnchor - 16`
- 键盘消失时恢复到`bottomSpaceBeforeKeyboard`

**状态恢复**: 键盘隐藏后，bottomAnchor恢复到键盘出现前的状态

### 内部元素位置

| 元素 | X位置 | Y位置 | 尺寸 | 说明 |
|------|-------|-------|------|------|
| 觉察动画 | 12px (ml-3) | 居中 | 32x32px | 左侧动画元素 |
| 文本输入框 | 觉察动画右侧+8px | 居中 | 自适应宽度 | 主输入区域 |
| 麦克风按钮 | 发送按钮左侧-8px | 居中 | 32x32px | 语音输入 |
| 发送按钮 | 右侧-12px (mr-3) | 居中 | 36x36px | 发送消息 |

---

## ChatOverlay（浮窗）组件

### 基础属性
| 属性 | 数值 | 说明 |
|------|------|------|
| 高度 | 65px | 固定高度，永不改变 |
| 圆角半径 | 32.5px | collapsed状态顶部圆角 |
| 圆角样式 | 顶部圆角 | maskedCorners: 只有上边两个角圆角，营造从屏幕外延伸进来的效果 |
| 左边距 | leading: 16px | 距离屏幕左边缘，与输入框对齐 |
| 右边距 | trailing: 16px | 距离屏幕右边缘，与输入框对齐 |
| 实际宽度 | screenWidth - 32px | 与输入框相同宽度 |

### 位置状态详表

#### 1. Collapsed（收缩状态）- 固定位置
**边距定位（主要）**
| 边距类型 | 数值 | Auto Layout约束 | 说明 |
|----------|------|----------------|------|
| 顶边距（相对安全区） | top: relativeTopFromSafeArea | topAnchor = safeAreaLayoutGuide.topAnchor + relativeTop | 相对于安全区顶部的位置 |
| 底边距实际 | bottom: 15px | ✅ 安全距离 | **已修正**：避免被手势条遮挡 |
| 左边距 | leading: 16px | leadingAnchor + 16 | 距离屏幕左边缘16px |
| 右边距 | trailing: 16px | trailingAnchor - 16 | 距离屏幕右边缘16px |
| 高度约束 | height: 65px | heightAnchor = 65 | 固定高度65px |

**位置计算过程**
1. 收缩状态输入框底部距离安全区底部：40px
2. 浮窗顶部 = 输入框底部 + 10px = 安全区底部上方30px
3. 浮窗底部 = 浮窗顶部 + 65px = 安全区底部下方35px
4. **⚠️ 注意**：浮窗底部会超出安全区35px，需要验证实际效果

**约束关系**
- `chatOverlay.topAnchor = safeAreaLayoutGuide.topAnchor + relativeTopFromSafeArea`
- `chatOverlay.leadingAnchor = superview.leadingAnchor + 16`  
- `chatOverlay.trailingAnchor = superview.trailingAnchor - 16`
- `chatOverlay.heightAnchor = 65`

**实现方案约束关系**

```swift
// 1. 计算输入框底部绝对位置
let inputBottomSpaceCollapsed: CGFloat = 40
let inputDrawerBottomCollapsed = screenHeight - safeAreaBottom - inputBottomSpaceCollapsed

// 2. 计算浮窗顶部绝对位置（输入框下方10px）
let gap: CGFloat = 10
let floatingTop = inputDrawerBottomCollapsed + gap

// 3. 转换为相对于安全区顶部的坐标
let relativeTopFromSafeArea = floatingTop - safeAreaTop

// 4. 设置Auto Layout约束
containerTopConstraint = containerView.topAnchor.constraint(
    equalTo: view.safeAreaLayoutGuide.topAnchor, 
    constant: relativeTopFromSafeArea
)
containerHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: 65)
containerLeadingConstraint = containerView.leadingAnchor.constraint(
    equalTo: view.leadingAnchor, 
    constant: 16
)
containerTrailingConstraint = containerView.trailingAnchor.constraint(
    equalTo: view.trailingAnchor, 
    constant: -16
)

// 5. 设置圆角样式：只有顶部圆角，营造延伸效果
containerView.layer.cornerRadius = 32.5
containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
```

**验证坐标**: (16, screenHeight-safeAreaBottom-30) → (screenWidth-16, screenHeight-safeAreaBottom+35)
**⚠️ 说明**: 浮窗底部会超出安全区35px，实际显示需要验证

#### 2. Expanded（展开状态）
**边距定位（主要）**
| 边距类型 | 数值 | Auto Layout约束 | 说明 |
|----------|------|----------------|------|
| 顶边距 | top: max(safeAreaTop, 80)px | topAnchor + max(safeAreaTop, 80) | 距离安全区顶部或80px |
| 底边距 | bottom: 80px | safeAreaLayoutGuide.bottomAnchor - 80 | 为输入框让出空间 |
| 左边距 | leading: 0px | leadingAnchor + 0 | 贴近屏幕左边缘 |
| 右边距 | trailing: 0px | trailingAnchor - 0 | 贴近屏幕右边缘 |

**约束关系**
- `chatOverlay.topAnchor = max(safeAreaLayoutGuide.topAnchor, 80)`
- `chatOverlay.bottomAnchor = safeAreaLayoutGuide.bottomAnchor - 80`
- `chatOverlay.leadingAnchor = superview.leadingAnchor`
- `chatOverlay.trailingAnchor = superview.trailingAnchor`

**实现方案约束关系**

```swift
// 1. 计算顶部位置（安全区顶部和80px取较大值）
let topMargin = max(safeAreaTop, 80)
let expandedBottomMargin: CGFloat = 80

// 2. 计算动态高度
let expandedHeight = screenHeight - topMargin - expandedBottomMargin

// 3. 设置Auto Layout约束
containerTopConstraint.constant = topMargin - safeAreaTop  // 转换为相对安全区坐标
containerHeightConstraint.constant = expandedHeight
containerLeadingConstraint.constant = 0   // 覆盖整个屏幕宽度
containerTrailingConstraint.constant = 0

// 4. 设置圆角样式：只有顶部圆角，营造延伸效果
containerView.layer.cornerRadius = 12
containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
```

**验证坐标**: (0, max(safeAreaTop, 80)) → (screenWidth, screenHeight-safeAreaBottom-80)

**动态属性**
| 属性 | 计算方式 | 说明 |
|------|----------|------|
| 实际高度 | screenHeight - max(safeAreaTop, 80) - safeAreaBottom - 80 | 动态计算显示区域 |
| 圆角半径 | 12px | 展开状态顶部圆角 |
| 圆角样式 | 顶部圆角 | maskedCorners: 只有上边两个角圆角 |
| 背景遮罩 | 全屏覆盖 | 透明度alpha = 1 |

#### 3. Hidden（隐藏状态）
**边距定位（主要）**
| 边距类型 | 数值 | Auto Layout约束 | 说明 |
|----------|------|----------------|------|
| 透明度 | alpha: 0 | containerView.alpha = 0 | 完全隐藏 |
| 位置约束 | 保持不变 | 保持上次约束状态 | 不改变Layout约束 |

**实现方案约束关系**

```swift
// Hidden状态只改变透明度，不修改约束
containerView.alpha = 0

// 约束保持上一次状态不变
// containerTopConstraint.constant 保持不变
// containerHeightConstraint.constant 保持不变  
// containerLeadingConstraint.constant 保持不变
// containerTrailingConstraint.constant 保持不变
```

**验证坐标**: 保持上次状态的绝对坐标（不可见但位置不变）

---

## 具体设备示例（iPhone 14 Pro）

### 设备基础参数
- **屏幕尺寸**: 393 × 852 点
- **安全区顶部**: 59px（动态岛）
- **安全区底部**: 34px（Home指示器）

### InputDrawer 绝对坐标示例

#### 默认状态（无浮窗）
| 参数 | 绝对坐标值 | 计算过程 |
|------|------------|----------|
| 左上角 | (16, 750) | (16, 852 - 34 - 68) |
| 右上角 | (377, 750) | (393 - 16, 852 - 34 - 68) |
| 左下角 | (16, 798) | (16, 852 - 34 - 20) |
| 右下角 | (377, 798) | (393 - 16, 852 - 34 - 20) |
| 中心点 | (196.5, 774) | (393/2, 852 - 34 - 44) |

#### 收缩状态（有浮窗）
| 参数 | 绝对坐标值 | 计算过程 |
|------|------------|----------|
| 左上角 | (16, 730) | (16, 852 - 34 - 88) |
| 右上角 | (377, 730) | (393 - 16, 852 - 34 - 88) |
| 左下角 | (16, 778) | (16, 852 - 34 - 40) |
| 右下角 | (377, 778) | (393 - 16, 852 - 34 - 40) |
| 中心点 | (196.5, 754) | (393/2, 852 - 34 - 64) |

### ChatOverlay 绝对坐标示例

#### Collapsed状态
| 参数 | 绝对坐标值 | 计算过程 |
|------|------------|----------|
| 左上角 | (16, 788) | (16, 852 - 34 - 30) |
| 右上角 | (377, 788) | (393 - 16, 852 - 34 - 30) |
| 左下角 | (16, 853) | (16, 852 - 34 + 35) ⚠️ 超出屏幕 |
| 右下角 | (377, 853) | (393 - 16, 852 - 34 + 35) ⚠️ 超出屏幕 |
| 中心点 | (196.5, 820.5) | (393/2, 852 - 34 + 2.5) |

#### Expanded状态
| 参数 | 绝对坐标值 | 计算过程 |
|------|------------|----------|
| 左上角 | (0, 80) | (0, max(59, 80)) |
| 右上角 | (393, 80) | (393, max(59, 80)) |
| 左下角 | (0, 738) | (0, 852 - 34 - 80) |
| 右下角 | (393, 738) | (393, 852 - 34 - 80) |
| 中心点 | (196.5, 409) | (393/2, (80 + 738)/2) |
| 高度 | 658px | 852 - 80 - 80 - 34 |

### 关键间距验证
- **输入框与浮窗间距**: 788 - 778 = 10px ✅
- **浮窗底部与屏幕底部**: 853 - 852 = 1px ⚠️（超出屏幕1px）
- **输入框与屏幕边距**: 16px ✅
- **⚠️ 警告**: 当前设置下浮窗会轻微超出屏幕底部，需要实际测试效果

---

## 窗口层级管理

### 层级顺序（从底到顶）
| 层级 | 组件 | windowLevel | 说明 |
|------|------|-------------|------|
| 1 | 主应用窗口 | UIWindow.Level.normal (0) | 基础应用内容 |
| 2 | ChatOverlay | UIWindow.Level.statusBar - 1 (999) | 浮窗显示 |
| 3 | InputDrawer | UIWindow.Level.statusBar - 0.5 (999.5) | 输入框始终在最前 |

### 触摸事件处理
- **InputDrawer**: 输入框区域内正常处理，区域外透传
- **ChatOverlay**: 浮窗区域内正常处理，区域外透传
- **事件优先级**: InputDrawer > ChatOverlay > 主应用

---

## 关键间距规范

| 间距类型 | 数值 | 应用场景 |
|----------|------|----------|
| 组件边距 | 16px | 输入框、浮窗距离屏幕边缘 |
| 组件间距 | 10px | 浮窗与输入框之间的间距 |
| 键盘边距 | 16px | 输入框距离键盘顶部 |
| 安全区边距 | 自动 | 适应不同设备的安全区 |

---

## 状态转换矩阵

### InputDrawer 状态转换
| 当前状态 | 触发事件 | 目标状态 | 位置变化 |
|----------|----------|----------|----------|
| 默认(20px) | 浮窗显示 | 上移(80px) | bottomSpace: 20→80 |
| 上移(80px) | 浮窗隐藏 | 默认(20px) | bottomSpace: 80→20 |
| 任意位置 | 键盘弹出 | 键盘上方 | 动态计算，保存原位置 |
| 键盘上方 | 键盘收起 | 恢复原位 | 恢复bottomSpaceBeforeKeyboard |

### ChatOverlay 状态转换
| 当前状态 | 触发事件 | 目标状态 | 位置变化 |
|----------|----------|----------|----------|
| Hidden | show(collapsed=true) | Collapsed | 固定位置显示 |
| Collapsed | 点击展开 | Expanded | 全屏显示 |
| Expanded | 点击收起 | Collapsed | 回到固定位置 |
| 任意状态 | hide() | Hidden | 透明度为0 |

---

## 调试信息模板

### 日志输出格式
```swift
NSLog("🎯 [组件名] 状态: [状态名] - 位置: (x: [X坐标], y: [Y坐标]), 尺寸: (w: [宽度], h: [高度])")
```

### 关键检查点
1. **InputDrawer位置**: 检查bottomSpace值与实际位置是否匹配
2. **ChatOverlay位置**: 检查与InputDrawer的相对间距是否为10px
3. **键盘处理**: 检查位置恢复是否正确
4. **安全区适配**: 检查在不同设备上的显示效果

---

## 更新记录

| 版本 | 日期 | 修改内容 | 修改原因 |
|------|------|----------|----------|
| 1.0 | 2025-01-28 | 初始版本 | 建立位置管理规范 |

---

## 备注

1. **所有位置计算都基于iOS UIKit坐标系**
2. **浮窗高度65px是固定不变的，任何状态下都不应该改变**
3. **输入框与浮窗的10px间距是设计规范，必须严格遵守**
4. **键盘处理要确保位置恢复的准确性**
5. **窗口层级确保输入框始终在浮窗前面，便于用户交互**
6. **圆角样式使用maskedCorners只显示顶部圆角，营造从屏幕底部延伸上来的视觉效果**