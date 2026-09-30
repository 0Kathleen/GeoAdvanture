//
//  LegacyMigrator.swift
//  GeoAdvanture
//
//  一次性把旧的 UserDefaults 进度迁移到 CoreData(ProgressStore)。
//  首次启动执行一次，以 UserDefaults 标记幂等；为安全起见暂不删除旧 key（保留回滚余地）。
//

import Foundation

enum LegacyMigrator {

    private static let doneKey = "migration_v2_userdefaults_to_coredata"

    static func runIfNeeded(into store: ProgressStore) {
        let d = UserDefaults.standard
        guard !d.bool(forKey: doneKey) else { return }

        // 1. 收获：progress_harvest_<id>
        for id in ContentStore.shared.allHarvestIds where d.bool(forKey: "progress_harvest_\(id)") {
            store.unlock(.harvest, id)
        }

        // 2. 设置：setting_ai_voice
        if d.object(forKey: "setting_ai_voice") != nil {
            store.setBool(d.bool(forKey: "setting_ai_voice"), forKey: "ai_voice")
        }

        // 3. 旧 starter 标记 → 新 starter 标记，避免迁移后重复解锁前两个收获
        if d.bool(forKey: "progress_starter_notebook_harvests_v1") {
            store.setBool(true, forKey: "starter_notebook_harvests_v1")
        }

        d.set(true, forKey: doneKey)
        print("✅ LegacyMigrator：UserDefaults → CoreData 迁移完成")
    }
}
