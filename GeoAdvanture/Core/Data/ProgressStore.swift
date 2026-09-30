//
//  ProgressStore.swift
//  GeoAdvanture
//
//  用户「进度」的唯一持久化入口，基于 CoreData（SQLite 存储）。
//  设计要点：
//   - 内容与进度分离：静态内容走 ContentStore，本类只存用户状态。
//   - 采用「程序化 NSManagedObjectModel」，无需 .xcdatamodeld 文件，纯 Swift，确定性编译。
//   - 所有解锁统一进 UnlockRecord 表，通过 (kind, targetId) 关联内容 id。
//   - 进度写入极低频，统一使用主队列 viewContext；无需自建锁。
//

import Foundation
import CoreData

// MARK: - 解锁类别

enum UnlockKind: String {
    case harvest
    // MARK: 横版探索世界（新玩法）
    case poi          // 已发现的 POI id
    case collectible  // 已采集的图鉴 id
    case instrument   // 已获得的仪器 id
    case integratedMission // 已完成的综合学习任务 id
}

/// 单个知识专题的掌握阶段。阶段只能向前推进，不能因重玩或低分回退。
enum KnowledgeMasteryStage: Int16, Codable, Comparable {
    case locked = 0
    case discovered = 1
    case understood = 2
    case applied = 3

    static func < (lhs: KnowledgeMasteryStage, rhs: KnowledgeMasteryStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct KnowledgeProgressState: Equatable {
    let topicId: String
    let stage: KnowledgeMasteryStage
    let bestScore: Int
    let hasUnreadContent: Bool
    let updatedAt: Date?
}

// MARK: - Managed Object 子类

@objc(UnlockRecord)
class UnlockRecord: NSManagedObject {
    @NSManaged var kind: String
    @NSManaged var targetId: String
    @NSManaged var unlockedAt: Date
}

@objc(LabLevelProgress)
class LabLevelProgress: NSManagedObject {
    @NSManaged var levelId: String
    @NSManaged var bestStars: Int16
    @NSManaged var isCompleted: Bool
    @NSManaged var bestRecordJSON: String?
    @NSManaged var updatedAt: Date
}

/// 横版世界的层进度（新玩法）。独立实体：不复用 LabLevelProgress，
/// 既避免 CoreData 实体重命名的迁移风险，又让实验室既有逻辑完全不受影响。
@objc(WorldProgress)
class WorldProgress: NSManagedObject {
    @NSManaged var worldId: String
    @NSManaged var bestStars: Int16
    @NSManaged var isCompleted: Bool
    @NSManaged var bestRecordJSON: String?
    @NSManaged var updatedAt: Date
}

@objc(UserSettingEntity)
class UserSettingEntity: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var boolValue: Bool
    @NSManaged var stringValue: String?
}

@objc(KnowledgeProgressEntity)
class KnowledgeProgressEntity: NSManagedObject {
    @NSManaged var topicId: String
    @NSManaged var stageRaw: Int16
    @NSManaged var bestScore: Int16
    @NSManaged var hasUnreadContent: Bool
    @NSManaged var updatedAt: Date
}

// MARK: - ProgressStore

final class ProgressStore {

    static let shared = ProgressStore()

    private let container: NSPersistentContainer
    private var ctx: NSManagedObjectContext { container.viewContext }

    /// 一次性「清库」守卫键：本版本起不再保留旧进度记录，首启清空一次即可。
    private static let cleanSlateKey = "progress_clean_slate_v3"

    private init() {
        let model = ProgressStore.makeModel()
        container = NSPersistentContainer(name: "GeoAdventureProgress", managedObjectModel: model)

        if let description = container.persistentStoreDescriptions.first {
            // 本版本改用新数据结构，旧记录无需保留：首启删除旧库文件，干净重来。
            if !UserDefaults.standard.bool(forKey: Self.cleanSlateKey) {
                if let url = description.url {
                    Self.destroyStoreFiles(at: url)
                }
                // 同时阻止旧 UserDefaults 进度被 LegacyMigrator 回灌
                Self.discardLegacyUserDefaults()
                UserDefaults.standard.set(true, forKey: Self.cleanSlateKey)
                print("🧹 ProgressStore：已清空旧进度记录，干净重来")
            }
            // 保留自动轻量迁移，用于「本版本之后」的新增实体/属性平滑升级。
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { [weak container] _, error in
            guard let error = error else { return }
            print("❌ ProgressStore：CoreData 存储加载失败: \(error)")
            // 兜底：万一仍加载失败，销毁旧库重建，避免 App 卡死。
            if let description = container?.persistentStoreDescriptions.first,
               let url = description.url {
                Self.destroyStoreFiles(at: url)
                container?.loadPersistentStores { _, retryError in
                    if let retryError = retryError {
                        print("❌ ProgressStore：重建存储仍失败: \(retryError)")
                    } else {
                        print("♻️ ProgressStore：已重建 CoreData 存储")
                    }
                }
            }
        }
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    /// 删除 SQLite 主文件及其 -wal / -shm 附属文件。
    private static func destroyStoreFiles(at url: URL) {
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let target = URL(fileURLWithPath: url.path + suffix)
            try? fm.removeItem(at: target)
        }
    }

    /// 让旧的 UserDefaults 进度不再迁入新库：直接把迁移标记置为已完成。
    private static func discardLegacyUserDefaults() {
        UserDefaults.standard.set(true, forKey: "migration_v2_userdefaults_to_coredata")
    }

    // MARK: - 解锁读写

    func isUnlocked(_ kind: UnlockKind, _ id: String) -> Bool {
        let req = NSFetchRequest<UnlockRecord>(entityName: "UnlockRecord")
        req.predicate = NSPredicate(format: "kind == %@ AND targetId == %@", kind.rawValue, id)
        req.fetchLimit = 1
        return ((try? ctx.count(for: req)) ?? 0) > 0
    }

    /// 幂等解锁：已解锁则不重复写入
    @discardableResult
    func unlock(_ kind: UnlockKind, _ id: String) -> Bool {
        guard !isUnlocked(kind, id) else { return false }
        let rec = NSEntityDescription.insertNewObject(forEntityName: "UnlockRecord", into: ctx) as! UnlockRecord
        rec.kind = kind.rawValue
        rec.targetId = id
        rec.unlockedAt = Date()
        save()
        return true
    }

    func unlockedIds(_ kind: UnlockKind) -> Set<String> {
        let req = NSFetchRequest<UnlockRecord>(entityName: "UnlockRecord")
        req.predicate = NSPredicate(format: "kind == %@", kind.rawValue)
        let results = (try? ctx.fetch(req)) ?? []
        return Set(results.map { $0.targetId })
    }

    // MARK: - 知识专题掌握状态

    func knowledgeProgress(topicId: String) -> KnowledgeProgressState {
        guard let entity = fetchKnowledgeProgress(topicId) else {
            return KnowledgeProgressState(
                topicId: topicId,
                stage: .locked,
                bestScore: 0,
                hasUnreadContent: false,
                updatedAt: nil)
        }
        return KnowledgeProgressState(
            topicId: topicId,
            stage: KnowledgeMasteryStage(rawValue: entity.stageRaw) ?? .locked,
            bestScore: Int(entity.bestScore),
            hasUnreadContent: entity.hasUnreadContent,
            updatedAt: entity.updatedAt)
    }

    /// 幂等推进知识阶段；只前进不回退，最好成绩只升不降。
    @discardableResult
    func promoteKnowledge(topicId: String,
                          to stage: KnowledgeMasteryStage,
                          score: Int = 0,
                          markUnread: Bool = true) -> Bool {
        let existing = fetchKnowledgeProgress(topicId)
        let entity = existing
            ?? (NSEntityDescription.insertNewObject(
                forEntityName: "KnowledgeProgressEntity",
                into: ctx) as! KnowledgeProgressEntity)
        let isNew = existing == nil
        if isNew {
            entity.topicId = topicId
            entity.stageRaw = KnowledgeMasteryStage.locked.rawValue
            entity.bestScore = 0
            entity.hasUnreadContent = false
        }

        let oldStage = KnowledgeMasteryStage(rawValue: entity.stageRaw) ?? .locked
        let oldScore = Int(entity.bestScore)
        let stageChanged = stage > oldStage
        let scoreChanged = score > oldScore
        let unreadChanged = markUnread && stageChanged && !entity.hasUnreadContent

        guard isNew || stageChanged || scoreChanged || unreadChanged else {
            return false
        }

        if stageChanged { entity.stageRaw = stage.rawValue }
        if scoreChanged { entity.bestScore = Int16(clamping: score) }
        if unreadChanged { entity.hasUnreadContent = true }
        entity.updatedAt = Date()

        save()
        return true
    }

    func markKnowledgeRead(topicId: String) {
        guard let entity = fetchKnowledgeProgress(topicId), entity.hasUnreadContent else { return }
        entity.hasUnreadContent = false
        entity.updatedAt = Date()
        save()
    }

    func knowledgeProgresses(topicIds: [String]) -> [KnowledgeProgressState] {
        topicIds.map { knowledgeProgress(topicId: $0) }
    }

    /// 兼容 R-3 已有的 harvest 解锁：旧知识卡已解锁时，新专题至少为“已发现”。
    func migrateKnowledgeFromHarvests(topicIds: [String]) {
        for topicId in topicIds where isUnlocked(.harvest, topicId) {
            promoteKnowledge(topicId: topicId, to: .discovered, markUnread: false)
        }
    }

    private func fetchKnowledgeProgress(_ topicId: String) -> KnowledgeProgressEntity? {
        let req = NSFetchRequest<KnowledgeProgressEntity>(entityName: "KnowledgeProgressEntity")
        req.predicate = NSPredicate(format: "topicId == %@", topicId)
        req.fetchLimit = 1
        return (try? ctx.fetch(req))?.first
    }

    // MARK: - 实验室关卡进度（Phase B 预留）

    func labProgress(levelId: String) -> (stars: Int, completed: Bool)? {
        guard let p = fetchLab(levelId) else { return nil }
        return (Int(p.bestStars), p.isCompleted)
    }

    func setLabProgress(levelId: String, stars: Int, completed: Bool, recordJSON: String?) {
        let p = fetchLab(levelId)
            ?? (NSEntityDescription.insertNewObject(forEntityName: "LabLevelProgress", into: ctx) as! LabLevelProgress)
        p.levelId = levelId
        p.bestStars = max(p.bestStars, Int16(stars))   // 星级只升不降
        if completed { p.isCompleted = true }
        if let recordJSON = recordJSON { p.bestRecordJSON = recordJSON }
        p.updatedAt = Date()
        save()
    }

    private func fetchLab(_ levelId: String) -> LabLevelProgress? {
        let req = NSFetchRequest<LabLevelProgress>(entityName: "LabLevelProgress")
        req.predicate = NSPredicate(format: "levelId == %@", levelId)
        req.fetchLimit = 1
        return (try? ctx.fetch(req))?.first
    }

    // MARK: - 横版世界层进度（新玩法）

    func isWorldCompleted(worldId: String) -> Bool {
        fetchWorld(worldId)?.isCompleted ?? false
    }

    func worldProgress(worldId: String) -> (stars: Int, completed: Bool)? {
        guard let p = fetchWorld(worldId) else { return nil }
        return (Int(p.bestStars), p.isCompleted)
    }

    func setWorldProgress(worldId: String, stars: Int = 0, completed: Bool, recordJSON: String? = nil) {
        let p = fetchWorld(worldId)
            ?? (NSEntityDescription.insertNewObject(forEntityName: "WorldProgress", into: ctx) as! WorldProgress)
        p.worldId = worldId
        p.bestStars = max(p.bestStars, Int16(stars))   // 星级只升不降
        if completed { p.isCompleted = true }
        if let recordJSON = recordJSON { p.bestRecordJSON = recordJSON }
        p.updatedAt = Date()
        save()
    }

    private func fetchWorld(_ worldId: String) -> WorldProgress? {
        let req = NSFetchRequest<WorldProgress>(entityName: "WorldProgress")
        req.predicate = NSPredicate(format: "worldId == %@", worldId)
        req.fetchLimit = 1
        return (try? ctx.fetch(req))?.first
    }

    // MARK: - 用户设置

    func bool(forKey key: String, default def: Bool) -> Bool {
        guard let s = fetchSetting(key) else { return def }
        return s.boolValue
    }

    func setBool(_ value: Bool, forKey key: String) {
        let s = fetchSetting(key)
            ?? (NSEntityDescription.insertNewObject(forEntityName: "UserSettingEntity", into: ctx) as! UserSettingEntity)
        s.key = key
        s.boolValue = value
        save()
    }

    private func fetchSetting(_ key: String) -> UserSettingEntity? {
        let req = NSFetchRequest<UserSettingEntity>(entityName: "UserSettingEntity")
        req.predicate = NSPredicate(format: "key == %@", key)
        req.fetchLimit = 1
        return (try? ctx.fetch(req))?.first
    }

    // MARK: - 维护

    /// 重置全部进度（对应旧 resetAllProgress）
    func resetAllProgress() {
        for name in ["UnlockRecord", "LabLevelProgress", "WorldProgress", "UserSettingEntity", "KnowledgeProgressEntity"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? ctx.execute(del)
        }
        ctx.reset()
    }

    /// 定向清除某一圈层的学习与关卡进度，不影响其他圈层和用户设置。
    func resetLayerProgress(worldId: String,
                            poiIds: Set<String>,
                            collectibleIds: Set<String>,
                            harvestIds: Set<String>,
                            knowledgeTopicIds: Set<String>,
                            missionIds: Set<String>,
                            settingKeys: Set<String>) {
        let unlocks = (try? ctx.fetch(NSFetchRequest<UnlockRecord>(entityName: "UnlockRecord"))) ?? []
        for record in unlocks {
            let shouldDelete: Bool
            switch UnlockKind(rawValue: record.kind) {
            case .poi: shouldDelete = poiIds.contains(record.targetId)
            case .collectible: shouldDelete = collectibleIds.contains(record.targetId)
            case .harvest: shouldDelete = harvestIds.contains(record.targetId)
            case .integratedMission: shouldDelete = missionIds.contains(record.targetId)
            case .instrument, .none: shouldDelete = false
            }
            if shouldDelete { ctx.delete(record) }
        }

        let worlds = (try? ctx.fetch(NSFetchRequest<WorldProgress>(entityName: "WorldProgress"))) ?? []
        worlds.filter { $0.worldId == worldId }.forEach(ctx.delete)

        let knowledge = (try? ctx.fetch(
            NSFetchRequest<KnowledgeProgressEntity>(entityName: "KnowledgeProgressEntity"))) ?? []
        knowledge.filter { knowledgeTopicIds.contains($0.topicId) }.forEach(ctx.delete)

        let settings = (try? ctx.fetch(
            NSFetchRequest<UserSettingEntity>(entityName: "UserSettingEntity"))) ?? []
        settings.filter { settingKeys.contains($0.key) }.forEach(ctx.delete)
        save()
    }

    /// 清理指向已删除内容的孤儿解锁记录（可选的数据卫生操作）
    func deleteOrphanUnlockRecords(validIds: Set<String>) {
        let req = NSFetchRequest<UnlockRecord>(entityName: "UnlockRecord")
        let all = (try? ctx.fetch(req)) ?? []
        var changed = false
        for r in all where !validIds.contains(r.targetId) {
            ctx.delete(r)
            changed = true
        }
        if changed { save() }
    }

    // MARK: - 保存

    private func save() {
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            print("❌ ProgressStore：保存失败: \(error)")
        }
    }

    // MARK: - 程序化数据模型

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let unlock = NSEntityDescription()
        unlock.name = "UnlockRecord"
        unlock.managedObjectClassName = NSStringFromClass(UnlockRecord.self)
        unlock.properties = [
            attr("kind", .stringAttributeType),
            attr("targetId", .stringAttributeType),
            attr("unlockedAt", .dateAttributeType)
        ]

        let lab = NSEntityDescription()
        lab.name = "LabLevelProgress"
        lab.managedObjectClassName = NSStringFromClass(LabLevelProgress.self)
        lab.properties = [
            attr("levelId", .stringAttributeType),
            attr("bestStars", .integer16AttributeType, defaultValue: 0),
            attr("isCompleted", .booleanAttributeType, defaultValue: false),
            attr("bestRecordJSON", .stringAttributeType, optional: true),
            attr("updatedAt", .dateAttributeType)
        ]

        let world = NSEntityDescription()
        world.name = "WorldProgress"
        world.managedObjectClassName = NSStringFromClass(WorldProgress.self)
        world.properties = [
            attr("worldId", .stringAttributeType),
            attr("bestStars", .integer16AttributeType, defaultValue: 0),
            attr("isCompleted", .booleanAttributeType, defaultValue: false),
            attr("bestRecordJSON", .stringAttributeType, optional: true),
            attr("updatedAt", .dateAttributeType)
        ]

        let setting = NSEntityDescription()
        setting.name = "UserSettingEntity"
        setting.managedObjectClassName = NSStringFromClass(UserSettingEntity.self)
        setting.properties = [
            attr("key", .stringAttributeType),
            attr("boolValue", .booleanAttributeType, defaultValue: false),
            attr("stringValue", .stringAttributeType, optional: true)
        ]

        let knowledge = NSEntityDescription()
        knowledge.name = "KnowledgeProgressEntity"
        knowledge.managedObjectClassName = NSStringFromClass(KnowledgeProgressEntity.self)
        knowledge.properties = [
            attr("topicId", .stringAttributeType),
            attr("stageRaw", .integer16AttributeType, defaultValue: KnowledgeMasteryStage.locked.rawValue),
            attr("bestScore", .integer16AttributeType, defaultValue: 0),
            attr("hasUnreadContent", .booleanAttributeType, defaultValue: false),
            attr("updatedAt", .dateAttributeType)
        ]

        model.entities = [unlock, lab, world, setting, knowledge]
        return model
    }

    private static func attr(_ name: String,
                             _ type: NSAttributeType,
                             optional: Bool = false,
                             defaultValue: Any? = nil) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        if let defaultValue = defaultValue { a.defaultValue = defaultValue }
        return a
    }
}
