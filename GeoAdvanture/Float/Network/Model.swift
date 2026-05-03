//
//  Model.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2025/11/11.
//

import Alamofire

struct StreamResponse: Codable {
    let choices: [StreamChoice]?
    let data: StreamData?
}

struct StreamData: Codable{
    let choices:[StreamChoice]?
}

struct StreamChoice: Codable {
    let messages: [StreamMessage]?
    let message: StreamMessage?
    let delta: StreamMessage?
    let stopReason:String?
}

struct StreamMessage: Codable {
    let role: String?
    let content: String?
}

let apiKey = "sk-a47a6e60b932470999c6f6604602af06"
let url = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
let systemPrompt = """
你是“岩小探”，《地心奇境》（GeoAdvanture）App 中的专属地质科普向导和地壳小精灵。你将与充满好奇心的小探险家（App 用户，主要是儿童）进行对话。

- 姓名：岩小豆
- 年龄：外表和心智像个7、8岁的小孩，但实际上已经有几十亿岁了。
- 性格：活泼开朗、热情友善、充满好奇心、极具耐心。有时候有点小调皮，喜欢用生动有趣的比喻。
- 职业：地球深处的地质科普向导 / 探险小助手。
- 简介：你是一个住在地壳深处的小精灵，对地球的构造（地壳、地幔、地核）、地震、火山、岩石等知识了如指掌。你的使命是带领小朋友们探索地球内部的奥秘，把枯燥的科学变成有趣的童话。

要求：
1. 坚守人设：必须始终以“岩小探”的身份说话，绝对不能承认自己是 AI、人工智能或大语言模型。
2. 科学与童趣并重：回答的知识必须科学准确，但绝对不能使用生硬的学术名词。必须用儿童能听懂的语言和比喻来解释（例如：地壳是“鸡蛋壳”或“巨大的岩石拼图”）。
3. 话题引导：如果小探险家问了与地球、地质、自然科学无关的问题，你要巧妙地用角色口吻拒绝，并引导回地球探索的话题。
4. 语气风格：亲切、生动、充满童趣。多使用可爱的语气词（如：呀、呢、哦、啦、哇）。每次回答尽量简短，控制在 100 - 200 字以内。
5. 动作与神态：在对话中绝对不要使用括号来表现你的动作或表情（如不要出现“(手舞足蹈地说着)”等词语）。
"""
let headers :HTTPHeaders = [
    "Content-Type" : "application/json",
    "Authorization": "Bearer \(apiKey)",
    "Accept": "text/event-stream",
    "Cache-Control": "no-cache",
    "X-Accel-Buffering": "no",
]

//let headers :HTTPHeaders = [
//    "Content-Type" : "application/json",
//    "X-AcA-DataInspection" : "enable",
//    "x-fag-servicename" : "aca-chat-send",
//    "x-fag-appcode": "aca",
//    "Authorization": "Bearer \(apiKey)",
//]


let lineMaxCharCount = 34
let lineHeight: CGFloat = 22

struct Word{
    var role:String = ""
    var text:String = ""
    var isPlaceholder: Bool = false // 是否是占位消息
}
