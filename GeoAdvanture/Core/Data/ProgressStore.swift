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
    case medal
    case crustScene
    case harvest
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

@objc(UserSettingEntity)
class UserSettingEntity: NSManagedObject {
    @NSManaged var key: String
    @NSManaged var boolValue: Bool
    @NSManaged var stringValue: String?
}

// MARK: - ProgressStore

final class ProgressStore {

    static let shared = ProgressStore()

    private let container: NSPersistentContainer
    private var ctx: NSManagedObjectContext { container.viewContext }

    private init() {
        let model = ProgressStore.makeModel()
        container = NSPersistentContainer(name: "GeoAdventureProgress", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ ProgressStore：CoreData 存储加载失败: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
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
        for name in ["UnlockRecord", "LabLevelProgress", "UserSettingEntity"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? ctx.execute(del)
        }
        ctx.reset()
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

        let setting = NSEntityDescription()
        setting.name = "UserSettingEntity"
        setting.managedObjectClassName = NSStringFromClass(UserSettingEntity.self)
        setting.properties = [
            attr("key", .stringAttributeType),
            attr("boolValue", .booleanAttributeType, defaultValue: false),
            attr("stringValue", .stringAttributeType, optional: true)
        ]

        model.entities = [unlock, lab, setting]
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
