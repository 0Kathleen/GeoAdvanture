//
//  AIChatManagerDelegate.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/12/3.
//

protocol AIChatManagerDelegate: AnyObject {
    // 消息列表更新了
    func didUpdateMessages()
    
    // 当前正在回复的那条消息内容变了
    // index: 正在更新的行号, newText: 更新后的完整文本
    func didUpdateStreamText(at index: Int, newText: String)
    
    // 对话彻底结束（成功或失败）
    func didFinishChat(success: Bool, error: Error?)
}
