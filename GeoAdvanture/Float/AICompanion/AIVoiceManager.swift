import Foundation
import AVFoundation

class AIVoiceManager: NSObject, URLSessionDataDelegate {
    
    static let shared = AIVoiceManager()
    
    private var session: URLSession!
    private var audioPlayer: AVAudioPlayer?
    
    private var audioBuffer = Data()
    private var sseBuffer = ""
    
    override init() {
        super.init()
        
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - 对外调用
    
    func speak(text: String) {
        
        audioBuffer.removeAll()
        
        let apiKey = "299cbf3e-7eaf-4010-b319-4385ce7df803"
        let urlString = "https://openspeech.bytedance.com/api/v3/tts/unidirectional/sse"
        
        guard let url = URL(string: urlString) else {
            print("❌ URL错误")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("seed-tts-2.0", forHTTPHeaderField: "X-Api-Resource-Id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user": [
                "uid": "12345"
            ],
            "req_params": [
                "text": text,
                "speaker": "zh_male_tiancaitongsheng_uranus_bigtts",
                "audio_params": [
                    "format": "mp3",
                    "sample_rate": 24000
                ]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    // MARK: - 收到响应（HTTP级别判断）
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 非 HTTP 响应")
            completionHandler(.cancel)
            return
        }
        
        print("✅ HTTP状态码:", httpResponse.statusCode)
        
        // ❗关键判断
        if httpResponse.statusCode != 200 {
            print("❌ HTTP错误:", httpResponse.statusCode)
            completionHandler(.cancel)
            return
        }
        
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
        print("✅ Content-Type:", contentType)
        
        if !contentType.contains("text/event-stream") {
            print("❌ 不是 SSE 流，返回异常")
            completionHandler(.cancel)
            return
        }
        
        completionHandler(.allow)
    }
    
    // MARK: - 流数据解析
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        
        // ✅ 拼接流
        sseBuffer += chunk
        
        // SSE 以 \n\n 作为一条完整消息
        let events = sseBuffer.components(separatedBy: "\n\n")
        
        // 最后一个可能是不完整的，先留着
        sseBuffer = events.last ?? ""
        
        for event in events.dropLast() {
            
            let lines = event.split(separator: "\n")
            
            for line in lines {
                
                if line.hasPrefix("data:") {
                    
                    let jsonString = line
                        .replacingOccurrences(of: "data:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    
                    print("🟡 JSON:", jsonString)
                    
                    guard let jsonData = jsonString.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                        
                        print("❌ JSON解析失败")
                        continue
                    }
                    
                    // ✅ 音频
                    if let base64 = json["audio"] as? String,
                       let audioChunk = Data(base64Encoded: base64) {
                        
                        print("✅ 收到音频chunk:", audioChunk.count)
                        audioBuffer.append(audioChunk)
                    }
                    
                    // ✅ 结束
                    if let status = json["status"] as? Int, status == 2 {
                        
                        print("🎉 收到结束标志")
                        
                        DispatchQueue.main.async {
                            self.playFinalAudio()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 播放
    
    private func playFinalAudio() {
        
        guard !audioBuffer.isEmpty else {
            print("❌ audioBuffer 为空，无法播放")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioBuffer)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("❌ 播放失败:", error)
        }
        
        audioBuffer.removeAll()
    }
    
    // MARK: - 结束 / 网络错误
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        
        if let error = error {
            print("❌ 网络层错误:", error)
        } else {
            print("✅ 请求结束")
        }
    }
}
