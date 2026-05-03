//
//  LaboratoryScene.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/5/2.
//

import SpriteKit

protocol LaboratorySceneDelegate: AnyObject {
    /// 实验数据实时更新
    func didUpdateEnvironment(depth: Double, temp: Double, pressure: Double, density: Double)
    /// 实验结束（成功或失败）
    func didFinishExperiment(success: Bool, reason: String)
}

class LaboratoryScene: SKScene, SKPhysicsContactDelegate {
    
    weak var labDelegate: LaboratorySceneDelegate?
    
    // MARK: - 核心节点
    private var backgroundNode: SKSpriteNode!
    private var cameraNode: SKCameraNode!
    private var sampleNode: SKSpriteNode?
    
    // MARK: - 物理引擎与数据
    private let physicsEngine = EarthPhysicsEngine()
    private var currentSampleData: SampleData?
    
    // MARK: - 状态控制
    private var isExperimentRunning = false
    
    // 物理世界的缩放比例：1个点代表多少千米 (例如 1 point = 2 km)
    private let kmPerPoint: Double = 2.0
    private let maxDepthKm: Double = 6371.0
    
    override func didMove(to view: SKView) {
        setupScene()
        setupBackground()
        setupCamera()
    }
    
    private func setupScene() {
        self.backgroundColor = .black
        
        // 配置物理世界
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }
    
    private func setupBackground() {
        // 创建一个超长的背景节点来代表地层
        let totalHeight = CGFloat(maxDepthKm / kmPerPoint)
        
        backgroundNode = SKSpriteNode(color: .darkGray, size: CGSize(width: self.size.width, height: totalHeight))
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 1.0) // 锚点在顶部中心
        backgroundNode.position = CGPoint(x: self.size.width / 2, y: self.size.height)
        backgroundNode.zPosition = -10
        addChild(backgroundNode)
        
        // 绘制地层分界线
        drawLayerLine(depthKm: 35, color: .lightGray, name: "莫霍面 (35km)")
        drawLayerLine(depthKm: 660, color: .systemRed, name: "上下地幔边界 (660km)")
        drawLayerLine(depthKm: 2890, color: .orange, name: "核幔边界 (2890km)")
        drawLayerLine(depthKm: 5150, color: .yellow, name: "内外核边界 (5150km)")
        drawLayerLine(depthKm: 6371, color: .white, name: "地心 (6371km)")
    }
    
    private func drawLayerLine(depthKm: Double, color: UIColor, name: String) {
        let yPos = -CGFloat(depthKm / kmPerPoint)
        let line = SKSpriteNode(color: color, size: CGSize(width: self.size.width, height: 2))
        line.position = CGPoint(x: 0, y: yPos)
        backgroundNode.addChild(line)
        
        let label = SKLabelNode(text: name)
        label.fontName = "HelveticaNeue-Bold"
        label.fontSize = 12
        label.fontColor = color
        label.position = CGPoint(x: -self.size.width/2 + 10, y: yPos + 5)
        label.horizontalAlignmentMode = .left
        backgroundNode.addChild(label)
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        self.camera = cameraNode
        addChild(cameraNode)
    }
    
    // MARK: - 公开方法：控制实验
    
    func startExperiment(with sample: SampleData) {
        self.currentSampleData = sample
        
        sampleNode?.removeFromParent()
        createSampleNode(with: sample)
        
        cameraNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        isExperimentRunning = true
    }
    
    func resetExperiment() {
        isExperimentRunning = false
        sampleNode?.removeFromParent()
        sampleNode = nil
        
        let moveAction = SKAction.move(to: CGPoint(x: self.size.width / 2, y: self.size.height / 2), duration: 1.0)
        moveAction.timingMode = .easeOut
        cameraNode.run(moveAction)
        
        labDelegate?.didUpdateEnvironment(depth: 0, temp: 15, pressure: 0, density: 2.7)
    }
    
    private func createSampleNode(with data: SampleData) {
        let baseSize: CGFloat = 40.0
        let scale = CGFloat(max(0.5, min(2.0, 10.0 / data.density)))
        let finalSize = CGSize(width: baseSize * scale, height: baseSize * scale)
        
        sampleNode = SKSpriteNode(color: .white, size: finalSize)
        
        let hue = CGFloat(min(1.0, data.meltingPoint / 4000.0)) * 0.6
        sampleNode?.color = UIColor(hue: hue, saturation: 0.8, brightness: 0.9, alpha: 1.0)
        sampleNode?.colorBlendFactor = 1.0
        
        sampleNode?.position = CGPoint(x: self.size.width / 2, y: self.size.height - 100)
        sampleNode?.zPosition = 10
        
        sampleNode?.physicsBody = SKPhysicsBody(rectangleOf: finalSize)
        sampleNode?.physicsBody?.isDynamic = true
        sampleNode?.physicsBody?.allowsRotation = true
        sampleNode?.physicsBody?.mass = CGFloat(data.density)
        
        if let node = sampleNode {
            addChild(node)
        }
    }
    
    // MARK: - 游戏循环 (Update)
    
    override func update(_ currentTime: TimeInterval) {
        guard isExperimentRunning, let sample = sampleNode, let sampleData = currentSampleData else { return }
        
        // 1. 计算当前深度 (km)
        let dropDistancePoints = Double(self.size.height - sample.position.y)
        let currentDepthKm = max(0, dropDistancePoints * kmPerPoint)
        
        // 2. 获取环境数据
        let env = physicsEngine.getEnvironment(at: currentDepthKm)
        
        // 通知 UI 更新仪表盘
        labDelegate?.didUpdateEnvironment(
            depth: env.depth,
            temp: env.temperature,
            pressure: env.pressure,
            density: env.density
        )
        
        // 3. 摄像机跟随样本下落
        cameraNode.position.y = sample.position.y
        
        // 4. 物理场动态调整 (阻力与浮力)
        applyDynamicPhysics(sample: sample, sampleData: sampleData, env: env)
        
        // 5. 生死判定
        checkDestruction(sample: sample, sampleData: sampleData, env: env)
    }
    
    private func applyDynamicPhysics(sample: SKSpriteNode, sampleData: SampleData, env: EarthLayerData) {
        guard let physicsBody = sample.physicsBody else { return }
        
        // 根据地层状态调整阻力
        switch env.state {
        case .solid:
            // 固态地壳：假设通过重力破裂下沉，阻力较大
            physicsBody.linearDamping = 2.0
        case .plastic:
            // 塑性地幔：高黏稠度，阻力极大
            physicsBody.linearDamping = 5.0
        case .liquid:
            // 液态外核：阻力减小，但产生浮力
            physicsBody.linearDamping = 1.0
            
            // 阿基米德浮力原理：F = ρ_liquid * V * g
            // 简化计算：如果样本密度小于环境密度，施加向上的力抵消重力，使其悬浮
            if sampleData.density < env.density {
                // 施加一个向上的力，大小与重力成正比，使其减速并最终悬浮
                let buoyancyForce = CGFloat(env.density / sampleData.density) * physicsBody.mass * 9.8 * 2.0
                physicsBody.applyForce(CGVector(dx: 0, dy: buoyancyForce))
            }
        }
    }
    
    private func checkDestruction(sample: SKSpriteNode, sampleData: SampleData, env: EarthLayerData) {
        // 1. 熔化判定
        let actualMeltingPoint = physicsEngine.calculateActualMeltingPoint(
            baseMeltingPoint: sampleData.meltingPoint,
            currentPressure: env.pressure
        )
        
        if env.temperature > actualMeltingPoint {
            triggerDestruction(reason: "温度过高 (\(Int(env.temperature))°C)，样本已熔化气化。", type: .melt)
            return
        }
        
        // 2. 碎裂判定
        if env.pressure > sampleData.strength {
            triggerDestruction(reason: "压力过大 (\(String(format: "%.1f", env.pressure)) GPa)，样本晶格崩塌碎裂。", type: .crush)
            return
        }
        
        // 3. 悬浮判定 (卡在核幔边界)
        if env.state == .liquid && sampleData.density < env.density {
            // 如果速度已经很慢，说明悬浮稳定了
            if let velocity = sample.physicsBody?.velocity.dy, abs(velocity) < 10 {
                triggerDestruction(reason: "密度不足 (\(sampleData.density) g/cm³ < 外核 \(env.density) g/cm³)，样本悬浮在液态外核表面，无法继续下沉。", type: .float)
                return
            }
        }
        
        // 4. 成功抵达地心
        if env.depth >= maxDepthKm {
            triggerSuccess()
        }
    }
    
    enum DestructionType {
        case melt
        case crush
        case float
    }
    
    private func triggerDestruction(reason: String, type: DestructionType) {
        isExperimentRunning = false
        guard let sample = sampleNode else { return }
        
        let pos = sample.position
        sample.removeFromParent()
        
        // 播放特效
        switch type {
        case .melt:
            playMeltEffect(at: pos)
        case .crush:
            playCrushEffect(at: pos)
        case .float:
            // 悬浮不需要爆炸特效，只需停止
            break
        }
        
        labDelegate?.didFinishExperiment(success: false, reason: reason)
    }
    
    private func triggerSuccess() {
        isExperimentRunning = false
        guard let sample = sampleNode else { return }
        
        let pos = sample.position
        
        // 播放结晶特效 (用一个高亮的粒子代替)
        playSuccessEffect(at: pos)
        
        labDelegate?.didFinishExperiment(success: true, reason: "完美参数！样本成功抵御了地心 5500°C 高温与 360 GPa 极高压，结晶为稀有宝石！")
    }
    
    // MARK: - 粒子特效 (代码生成，无需外部文件)
    
    private func playMeltEffect(at position: CGPoint) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark") // 如果没有图片，会退化为色块
        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 100
        emitter.particleLifetime = 1.5
        emitter.particlePositionRange = CGVector(dx: 40, dy: 40)
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 4
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.5
        emitter.particleScale = 0.5
        emitter.particleScaleSpeed = -0.2
        emitter.particleColor = .orange
        emitter.particleColorBlendFactor = 1.0
        emitter.position = position
        
        addChild(emitter)
        
        // 播放完后移除
        let wait = SKAction.wait(forDuration: 2.0)
        let remove = SKAction.removeFromParent()
        emitter.run(SKAction.sequence([wait, remove]))
    }
    
    private func playCrushEffect(at position: CGPoint) {
        // 生成多个小碎片
        for _ in 0..<8 {
            let piece = SKSpriteNode(color: currentSampleData != nil ? UIColor(hue: CGFloat(min(1.0, currentSampleData!.meltingPoint / 4000.0)) * 0.6, saturation: 0.8, brightness: 0.9, alpha: 1.0) : .white, size: CGSize(width: 10, height: 10))
            piece.position = position
            piece.physicsBody = SKPhysicsBody(rectangleOf: piece.size)
            piece.physicsBody?.isDynamic = true
            addChild(piece)
            
            // 随机爆炸冲量
            let dx = CGFloat.random(in: -50...50)
            let dy = CGFloat.random(in: -50...50)
            piece.physicsBody?.applyImpulse(CGVector(dx: dx, dy: dy))
            
            // 渐隐并移除
            let fade = SKAction.fadeOut(withDuration: 1.5)
            let remove = SKAction.removeFromParent()
            piece.run(SKAction.sequence([fade, remove]))
        }
    }
    
    private func playSuccessEffect(at position: CGPoint) {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 50
        emitter.numParticlesToEmit = 200
        emitter.particleLifetime = 2.0
        emitter.particlePositionRange = CGVector(dx: 20, dy: 20)
        emitter.particleSpeed = 50
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -0.5
        emitter.particleScale = 0.8
        emitter.particleScaleSpeed = -0.3
        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0
        emitter.position = position
        
        addChild(emitter)
    }
}
