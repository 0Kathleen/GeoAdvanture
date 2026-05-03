//
//  AIChatManager.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/12/3.
//

import Foundation

class AIChatManager {
    
    public weak var delegate: AIChatManagerDelegate?

    private(set) var messages: [Word] = []

    private var currentResponseIndex: Int?
    private var isStreamActive: Bool = false
    
    public func addGreetingMessage() {
        let greeting = Word(role: "AI", text: "你好呀！我是岩小探，地球深处的小精灵。你想了解关于地球的什么秘密呢？")
        messages.append(greeting)
        delegate?.didUpdateMessages()
    }
    
    public func sendUserMessage(_ text: String) {
        messages.append(Word(role: "user", text: text))
            
        let placeholder = Word(role: "AI", text: "", isPlaceholder: true)
        messages.append(placeholder)
            
        currentResponseIndex = messages.count - 1
        delegate?.didUpdateMessages()
        startStreamRequest(userInput: text)
    }
    
    public func stopSession() {
        isStreamActive = false
        currentResponseIndex = nil
        AINetworkManager.shared.stop()
    }

    private func startStreamRequest(userInput: String) {
        self.isStreamActive = true

        let parameters: [String: Any] = [
            "model": "qwen-plus-character",
            "stream": true,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userInput]
            ]
        ]
        
        AINetworkManager.shared.requestOptimalStream(
            parameters: parameters,
            prewarm: true
        ) { [weak self] delta in
            
            DispatchQueue.main.async {
                guard let self = self,
                      self.isStreamActive,
                      let index = self.currentResponseIndex,
                      index < self.messages.count else { return }
                
                self.messages[index].text.append(delta)
                if self.messages[index].isPlaceholder {
                    self.messages[index].isPlaceholder = false
                }
                let newText = self.messages[index].text
                self.delegate?.didUpdateStreamText(at: index, newText: newText)
            }
        } onComplete: { [weak self] error in
            DispatchQueue.main.async {
                self?.isStreamActive = false
                self?.currentResponseIndex = nil
                self?.delegate?.didFinishChat(success: error == nil, error: error)
            }
        }
    }
}
