# SpriteKit 场景性能与体验优化要点（可作项目优化清单）

适用于本项目中 **FlashingScene（仅 App 开场/「开始探索」）→ HomeScene（地球分层点击入口）**、地壳关卡、以及**笔记本顶栏书签**等 SpriteKit 流程。既可作为开发备忘，也可直接写入报告/简历中的「优化点」表述。

**职责划分（避免与 UIKit 重复造轮子）**

| 模块 | SpriteKit | UIKit |
|------|-----------|--------|
| Flashing | 开场动效与开始按钮 | — |
| HomeScene | 分层标签 `layerLabelNode` 点击与动效 | 无 |
| 笔记本 | **书签条**（`NotebookBookmarkScene`） | **列表/正文/规范排版**（`NotebookViewController` + `UITableView`） |

---

## 1. 加载与主线程

| 优化点 | 做法 | 说明 |
|--------|------|------|
| **图集预加载** | `SKTextureAtlas.preload(completion:)` 在后台队列触发，完成后再在主线程 `presentScene` | 减少首帧解码卡顿；[`FlashingViewController`](GeoAdvanture/Flash/FlashingViewController.swift) 已对 Flashing 图集采用此模式。 |
| **SKS / Scene 解析避开主线程峰值** | 在图集 `preload` 回调之后，于**后台队列**执行 `HomeScene(fileNamed:)`（或 `SKNode.nodeWithFile`）再回主线程挂接 | 解析 `.sks` 与构建节点树较耗时；[`FlashingScene`](GeoAdvanture/Flash/FlashingScene.swift) 注释中已写明意图（`preloadAtlasTextures` 路径）。 |
| **避免重复创建 Scene** | 进入 Home 后保留已创建的 `HomeScene` 实例，从笔记本 `dismiss` 回到地球时不再重新 `fileNamed:` | 二次进入成本接近 0；需配合 UIKit 呈现方式（例如不销毁 `SKView`）。 |

---

## 2. 渲染与资源

| 优化点 | 做法 | 说明 |
|--------|------|------|
| **合并纹理为图集** | 关卡/Home 使用 `SKTextureAtlas`，减少绑定次数 | 已用 `FlashingAtlas`、`HomeAtlas` 等。 |
| **ignoresSiblingOrder** | `skView.ignoresSiblingOrder = true` | 在 zPosition 可控时减轻渲染排序成本。 |
| **控制节点数量与粒子** | 摩擦/地震特效用少量粒子或序列帧，避免常驻大量 emitter | 儿童向设备多为手机，GPU/发热敏感。 |

---

## 3. 架构与体验（与 UIKit 混合）

| 优化点 | 做法 | 说明 |
|--------|------|------|
| **UIKit 承载规范 UI** | 笔记本正文、设置、长列表用 `UIViewController`；SpriteKit 做书签条、地球交互、关卡动效 | 列表/富文本/无障碍在 UIKit 更省事；书签切换用轻量 `SKScene` 即可。 |
| **Delegate 生命周期** | 与 Scene 回调相关的 `delegate` 指向 **UIViewController**（或长寿命对象），避免旧 Scene 释放后野指针/无回调 | [`HomeScene`](GeoAdvanture/HomeScene.swift) 分层点击 → [`FlashingViewController`](GeoAdvanture/Flash/FlashingViewController.swift) 通过 `layerSelectionHost` 注入（**回调仅来自 HomeScene，非 Flashing**）。 |
| **可测耗时** | 对 `fileNamed:`、`presentScene`、图集 preload 打 `CFAbsoluteTimeGetCurrent()` 日志 | 便于对比优化前后（工程中已有部分打印）。 |

---

## 4. 调试与发布

| 优化点 | 做法 | 说明 |
|--------|------|------|
| **关闭调试叠加** | 发布包关闭 `showsFPS`、`showsNodeCount`、`showsDrawCount` | 当前 [`FlashingViewController`](GeoAdvanture/Flash/FlashingViewController.swift) 在开发中开启，上架前用 `#if DEBUG` 包裹。 |
| **降级策略** | 低端机减少同屏特效层数或降低 `preferredFramesPerSecond`（若需要） | 按真机 profiling 再定。 |

---

## 5. 一句话总结（写进优化总结/答辩可用）

> 通过 **纹理图集预加载**、**Scene 解析与主线程错峰**、**Scene 实例复用** 降低首屏与转场卡顿；通过 **SpriteKit 与 UIKit 分工**（开场与 Home 交互、笔记本**书签**在 SK；笔记本**正文**在 UIKit）控制复杂度；通过 **Delegate 挂在 ViewController** 避免 Scene 切换后的生命周期问题。

---

*文档版本：1.0*
