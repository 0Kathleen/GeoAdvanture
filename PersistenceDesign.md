# GeoAdvanture iOS 持久化方案设计与推荐

## 1. 现有业务数据分析
根据当前项目结构与代码，项目中主要存在两类需要持久化的核心数据：

1. **游戏与学习进度（Progress, Medals, Harvests等）**
   - **特点**：包含用户解锁的关卡、获取的勋章、图鉴收集进度以及全局设置（如 `isAIVoiceEnabled`）。数据结构相对简单，主要以 `String` 数组形态存在。
   - **现状**：在 `GameProgressManager.swift` 和 `ProgressManager.swift` 中，主要依赖 **SwiftData** (`UserProgress` 模型) 进行存储。
   
2. **学习行为日志（Learning Behavior Logs）**
   - **特点**：记录用户在应用中的操作行为（如试错记录、成功操作等），属于流水账式的时序数据。后续 AI 会依赖这些记录进行行为分析和学习报告生成，需要支持基于关卡、时间等维度的查询。
   - **现状**：在 `LearningBehaviorStore.swift` 中采用的是 **JSON + 文件系统** 的方式（`user_behavior_logs.json`），并在内存中维护了一个上限 500 条的数组。然而，项目中同时也存在一个基于 SwiftData 的 `LearningBehaviorLogModel`，出现了两种持久化方案重叠的现象。

---

## 2. iOS 常见持久化方案对比

| 方案 | 优势 | 劣势 | 适用场景 |
| :--- | :--- | :--- | :--- |
| **UserDefaults** | 极其轻量，API 调用简单；数据随应用启动加载，读取速度极快。 | 只能存基本数据类型；数据全量读入内存，存储大量数据会导致性能和内存问题。 | 用户偏好设置（如开关、主题、账号标记）。 |
| **文件系统 (JSON/Plist)** | 结构自由，结合 `Codable` 非常便于存取自定义结构体；跨平台迁移或导出调试方便。 | **增删改查性能差**。修改数组中某一项需要全量覆写文件；无索引支持，检索数据需遍历全部对象。 | 缓存文件、网络请求的响应数据、小型配置文件。 |
| **Core Data** | 原生强大，支持对象关系映射 (ORM)、复杂查询、数据迁移和内存管理优化。 | 学习曲线陡峭，多线程下的上下文 (Context) 管理容易引发崩溃，代码较繁琐。 | 复杂且具有强关联性的庞大本地数据库。 |
| **SwiftData** | 基于 Core Data 封装，结合 Swift 宏 (`@Model`)，代码极简；天然支持并发 (Actor 隔离)，类型安全的查询。 | 仅支持 iOS 17 及以上版本；部分高级关系特性暂不如 Core Data 丰富。 | **iOS 17+ 的首选本地数据库方案**，满足绝大部分应用需求。 |
| **SQLite (GRDB/FMDB)** | 性能极致，跨平台一致性好，适合直接操作 SQL 语句或需要多级表联查的极高频读写场景。 | 需引入第三方库，失去部分原生集成特性。 | 微信级别的海量聊天记录、大型本地检索工具。 |

---

## 3. 本项目最优方案推荐

### **结论：全面统一使用 SwiftData 作为核心持久化方案**，废弃现有的 JSON 文件存储。极简单的单点偏好设置可辅以 `UserDefaults`。

**推荐理由：**
1. **统一技术栈与降低维护成本**：目前项目存在 SwiftData 和 JSON 文件读写两套持久化逻辑，统一收编到 SwiftData 可以避免数据不同步和冗余代码（项目中已经有了 `LearningBehaviorLogModel`）。
2. **行为日志场景的绝佳适配**：行为日志不断增长，使用 JSON 每次新增都需要将包含数百条数据的数组重新 Encode 并写入文件，性能会随数据量线性下降。SwiftData 能够轻松实现 **O(1) 的增量插入**，同时提供强大的 `FetchDescriptor` 和 `Predicate`，支持类似“查询某关卡过去3天内的全部错误操作”这样的高效检索。
3. **未来的扩展性**：随着游戏功能增加，关卡进度（Progress）可能不再是单纯的字符串 ID 数组，而会衍生出“得分、通关时间、最高连击数”等复合结构。SwiftData 能够平滑地向关系型结构（Relationship）演进，而无需重构底层。
4. **版本优势**：项目已经使用 SwiftData，说明最低兼容版本已达 iOS 17，完全可以享受其带来的极简开发体验。

---

## 4. 具体落地方案设计

### 4.1 统一管理容器 (SwiftDataManager)
维持 `SwiftDataManager` 单例，管理 `UserProgress` 和 `LearningBehaviorLogModel` 两种模型。
- 当前已有 `@MainActor` 隔离的 `mainContext`，可以增加一个后台处理的方法以支持不在主线程执行的高频日志写入。

### 4.2 游戏与进度数据 (UserProgress)
- **现状保留**：继续维持现有的 `@Model public class UserProgress`。
- **微调优化**：对于 `isAIVoiceEnabled` 这类会在 App 启动极早期（或独立 UI 组件中）读取的配置，如果 SwiftData 容器初始化存在时序问题，可以考虑剥离到 `@AppStorage(UserDefaults)` 中，否则维持在 `UserProgress` 中亦可。

### 4.3 行为记录 (LearningBehaviorLog) 全面迁移
需要对 `LearningBehaviorStore.swift` 进行重构：
1. **废弃 JSON 逻辑**：移除 `FileManager` 的文件存取代码和 `logs` 内存数组。
2. **改为 SwiftData 插入**：
   在 `handleAction` 接收到行为事件时，直接实例化 `LearningBehaviorLogModel` 并通过 `SwiftDataManager.shared.mainContext.insert()` 存入数据库。
   ```swift
   let logModel = LearningBehaviorLogModel(timestamp: action.timestamp, levelId: currentLevel, source: source, target: target, details: details, isError: true)
   SwiftDataManager.shared.mainContext.insert(logModel)
   ```
3. **条件查询**：
   修改 `getRecentErrorLogs` 方法，使用 SwiftData 的 Fetch 抓取数据：
   ```swift
   var descriptor = FetchDescriptor<LearningBehaviorLogModel>(
       predicate: #Predicate { $0.levelId == levelId && $0.isError == true },
       sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
   )
   descriptor.fetchLimit = limit
   return (try? SwiftDataManager.shared.mainContext.fetch(descriptor)) ?? []
   ```
4. **数据库容量控制**：
   可以在应用启动或后台闲置时，执行一次检测。若日志总量超过阈值（如 1000 条），则通过 Fetch 获取最早时间戳的数据并将其删除，替代目前暴力的数组截断，保持轻量运行。