import Foundation

class ProgressManager {
    static let shared = ProgressManager()
    private let defaults = UserDefaults.standard
    
    // 记录已通关的关卡 ID
    private let completedLevelsKey = "CompletedLevelsKey"
    // 记录已解锁的收获 (Harvest) ID
    private let unlockedHarvestsKey = "UnlockedHarvestsKey"
    
    private init() {}
    
    // MARK: - 关卡进度
    public func markLevelAsCompleted(levelId: String) {
        var completed = getCompletedLevels()
        if !completed.contains(levelId) {
            completed.append(levelId)
            defaults.set(completed, forKey: completedLevelsKey)
        }
    }
    
    public func isLevelCompleted(levelId: String) -> Bool {
        return getCompletedLevels().contains(levelId)
    }
    
    private func getCompletedLevels() -> [String] {
        return defaults.stringArray(forKey: completedLevelsKey) ?? []
    }
    
    // MARK: - 收获/图鉴进度
    public func unlockHarvest(harvestId: String) {
        var unlocked = getUnlockedHarvests()
        if !unlocked.contains(harvestId) {
            unlocked.append(harvestId)
            defaults.set(unlocked, forKey: unlockedHarvestsKey)
        }
    }
    
    public func isHarvestUnlocked(harvestId: String) -> Bool {
        return getUnlockedHarvests().contains(harvestId)
    }
    
    private func getUnlockedHarvests() -> [String] {
        return defaults.stringArray(forKey: unlockedHarvestsKey) ?? []
    }
    
    // MARK: - 重置进度 
    public func resetAllProgress() {
        defaults.removeObject(forKey: completedLevelsKey)
        defaults.removeObject(forKey: unlockedHarvestsKey)
    }
}
