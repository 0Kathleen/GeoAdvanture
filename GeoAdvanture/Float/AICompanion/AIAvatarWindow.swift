//
//  AIAvatarWindowManager.swift
//  AIAvatarWindow.swift
//  GeoAdvanture
//
//  Created by 陈爽 on 2026/4/26.
//

import UIKit

///
/// 单例模式
/// WindowScene 挂载：在 iOS 13+ 中，必须将 Window 挂载到当前的 UIWindowScene 上才能显示
/// 层级控制：后续创建的  AIAvatarWindow 的层级会被设置得非常高，确保不会被任何业务页面的模态弹窗遮挡
///
public class AIAvatarWindowManager {
    
    public static let shared = AIAvatarWindowManager()
    
    private var window: AIAvatarWindow?
    private var isInitialized = false
    
    private init() {}
    
    public func setup(windowScene: UIWindowScene) {
        guard !isInitialized else { return }
        window = AIAvatarWindow(windowScene: windowScene)
        isInitialized = true
    }
    
    public func show() {
        window?.isHidden = false
    }
    
    public func hide() {
        window?.isHidden = true
    }
}

///
///   自定义 UIWindow
///
///   普通的 Window 即使背景设为  clear，依然会拦截整个屏幕的触摸事件，导致底下的 App 无法点击
///   需要在底部重写了 hitTest 方法，精确判断：只要不是点中了 AI Avatar 按钮本身，就把手势往下给底层的业务 Window
///
class AIAvatarWindow: UIWindow {
    private let avatarButton = UIButton(type: .custom)
    private var isDragging = false
    private var displayLink: CADisplayLink?
    
    // 提示气泡
    private let bubbleView = UIImageView()
    private let bubbleLabel = UILabel()
    private var bubbleHideTimer: Timer?
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        
        ///
        /// 提升层级
        /// .alert 级别通常用来展示系统级警告框，我们将级别设为 .alert - 1
        /// 保证它在几乎所有业务 UI 之上，但又不会挡住真正致命的系统警告。
        ///
        self.windowLevel = .alert - 1
        self.backgroundColor = .clear
        
        ///
        /// 挂载一个透明的 RootVC
        /// 从 iOS 13 开始，如果一个 Window 需要有 RootViewController
        ///
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        self.rootViewController = rootVC
        
        setupAvatarButton(in: rootVC.view)
        setupBubbleView(in: rootVC.view)
        
        // Window 必须取消隐藏才能显示
        self.isHidden = false
        
        // 绑定 ViewModel
        bindViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func bindViewModel() {
        AICompanionViewModel.shared.onStateChanged = { [weak self] state in
            guard let self = self else { return }
            self.handleStateChange(state)
        }
    }
    
    private func handleStateChange(_ state: LearningState) {
        switch state {
        case .exploring:
            hideBubble()
            startBreathingAnimation()
            
        case .confused(let tip):
            showBubble(text: tip, type: .confused)
            startThinkingAnimation()
            
        case .struggling(_, _):
            showBubble(text: "我在思考怎么帮你...", type: .struggling)
            startThinkingAnimation()
            
        case .proficient(let encouragement):
            showBubble(text: encouragement, type: .proficient)
            startCelebratingAnimation()
        }
    }
    
    private func setupBubbleView(in view: UIView) {
        bubbleView.image = UIImage(named: "smallBackView")
        bubbleView.contentMode = .scaleToFill
        bubbleView.isUserInteractionEnabled = true
        
        bubbleView.layer.shadowColor = UIColor.black.cgColor
        bubbleView.layer.shadowOpacity = 0.15
        bubbleView.layer.shadowOffset = CGSize(width: 0, height: 4)
        bubbleView.layer.shadowRadius = 6
        bubbleView.alpha = 0
        
        bubbleLabel.font = UIFont(name: "KaiTi_GB2312", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        bubbleLabel.textColor = .black
        bubbleLabel.numberOfLines = 0
        bubbleLabel.textAlignment = .center
        
        bubbleView.addSubview(bubbleLabel)
        view.addSubview(bubbleView)
    }
    
    private func updateBubbleLayout() {
        let screenWidth = self.bounds.width
        let padding: CGFloat = 12
        let avatarFrame = avatarButton.frame
        
        let maxSize = CGSize(width: 200, height: 100)
        let textRect = bubbleLabel.textRect(forBounds: CGRect(origin: .zero, size: maxSize), limitedToNumberOfLines: 0)
        let bubbleWidth = textRect.width + 24
        let bubbleHeight = textRect.height + 16
        
        var bubbleX: CGFloat = 0
        let bubbleY: CGFloat = avatarFrame.minY + (avatarFrame.height - bubbleHeight) / 2
        
        if avatarFrame.midX < screenWidth / 2 {
            bubbleX = avatarFrame.maxX + padding
        } else {
            bubbleX = avatarFrame.minX - bubbleWidth - padding
        }
        bubbleView.frame = CGRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight)
        bubbleLabel.frame = bubbleView.bounds.insetBy(dx: 12, dy: 8)
    }
    
    private enum BubbleType { case confused, struggling, proficient }
    
    private func showBubble(text: String, type: BubbleType) {
        bubbleLabel.text = text
        
        switch type {
        case .confused, .struggling:
            bubbleLabel.textColor = .black
        case .proficient:
            bubbleLabel.textColor = .black
        }
        
        updateBubbleLayout()
        
        // 如果气泡正在显示，只更新文字和布局；否则执行弹出动画
        if bubbleView.alpha == 0 {
            bubbleView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, animations: {
                self.bubbleView.alpha = 1.0
                self.bubbleView.transform = .identity
            })
        }
        
        // 5 秒后自动隐藏
        bubbleHideTimer?.invalidate()
        bubbleHideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.hideBubble()
        }
    }
    
    private func hideBubble() {
        bubbleHideTimer?.invalidate()
        UIView.animate(withDuration: 0.3) {
            self.bubbleView.alpha = 0
        }
    }
    
    private func setupAvatarButton(in view: UIView) {
        avatarButton.setImage(UIImage(named: "AIavatar"), for: .normal)
        avatarButton.imageView?.contentMode = .scaleAspectFit
        
        // 初始位置设定 (例如：左侧靠上)
        let size: CGFloat = 65
        avatarButton.frame = CGRect(x: 20, y: 60, width: size, height: size)
        view.addSubview(avatarButton)
        
        // 拖拽手势 (Pan) - 用于移动位置
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        avatarButton.addGestureRecognizer(panGesture)
        
        // 点击手势 (Tap) - 用于唤出大模型对话面板
        avatarButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        startBreathingAnimation()
    }
    
    // MARK: - 动画效果
    ///
    /// 使用 CoreAnimation (UIView.animate) 实现一个缓慢放大缩小的循环，模拟生命感。
    ///
    private func startBreathingAnimation() {
        avatarButton.layer.removeAllAnimations()
        avatarButton.transform = .identity
        
        UIView.animate(withDuration: 1.2,
                       delay: 0,
                       options: [.autoreverse, .repeat, .allowUserInteraction, .curveEaseInOut],
                       animations: {
            self.avatarButton.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }, completion: nil)
    }
    
    /// 思考动画
    /// 困惑或挣扎时，左右轻微晃动
    private func startThinkingAnimation() {
        avatarButton.layer.removeAllAnimations()
        avatarButton.transform = .identity
        
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.values = [0, -0.15, 0, 0.15, 0]
        animation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        avatarButton.layer.add(animation, forKey: "thinking")
    }
    
    /// 庆祝动画
    /// 成功时，上下欢快跳跃
    private func startCelebratingAnimation() {
        avatarButton.layer.removeAllAnimations()
        avatarButton.transform = .identity
        
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        animation.values = [0, -15, 0, -8, 0]
        animation.keyTimes = [0, 0.3, 0.6, 0.8, 1.0]
        animation.duration = 1.0
        animation.repeatCount = 3 // 跳跃3次后自动停止
        avatarButton.layer.add(animation, forKey: "celebrating")
        
        // 动画结束后恢复呼吸
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, !self.isDragging else { return }
            self.startBreathingAnimation()
        }
    }
    
    // MARK: - 交互处理
    
    ///
    /// 处理拖拽逻辑
    /// 1. 拖拽时必须暂停“呼吸动画”，否则 Transform 矩阵会发生冲突乱飞。
    /// 2. 松手时必须有“磁吸/防出界”逻辑，保证按钮最后贴在屏幕边缘，且不会跑到安全区 (Safe Area) 之外。
    ///
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let btn = gesture.view as? UIButton else { return }
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            isDragging = true
            // 开始拖拽时隐藏气泡
            hideBubble()
            // 暂停呼吸
            btn.layer.removeAllAnimations()
            UIView.animate(withDuration: 0.1) {
                // 拖动时稍微放大并变半透明，给用户物理反馈
                btn.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                btn.alpha = 0.8
            }
        case .changed:
            btn.center = CGPoint(x: btn.center.x + translation.x, y: btn.center.y + translation.y)
            // 同步更新可能存在的气泡位置
            updateBubbleLayout()
            // 必须清零，否则是累加偏移
            gesture.setTranslation(.zero, in: self)
        case .ended, .cancelled:
            isDragging = false
            let screenWidth = self.bounds.width
            let screenHeight = self.bounds.height
            let edgePadding: CGFloat = 10
            
            var finalX = btn.center.x
            var finalY = btn.center.y
            // 磁吸判断：如果在屏幕左半边，就吸在左侧；如果在右半边，就吸在右侧
            if finalX < screenWidth / 2 {
                finalX = btn.bounds.width / 2 + edgePadding
            } else {
                finalX = screenWidth - btn.bounds.width / 2 - edgePadding
            }
            // 越界防卫：防止按钮跑出刘海/灵动岛或者底部 Home 条区域
            let minY = btn.bounds.height / 2 + edgePadding + self.safeAreaInsets.top
            let maxY = screenHeight - btn.bounds.height / 2 - edgePadding - self.safeAreaInsets.bottom
            
            if finalY < minY {
                finalY = minY
            } else if finalY > maxY {
                finalY = maxY
            }
            // 带有弹簧阻尼效果的回弹动画
            UIView.animate(withDuration: 0.4,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.5,
                           options: .curveEaseOut,
                           animations: {
                btn.center = CGPoint(x: finalX, y: finalY)
                btn.transform = .identity
                btn.alpha = 1.0
            }) { _ in
                // 回弹结束后，恢复呼吸动画
                self.startBreathingAnimation()
            }
        default:
            break
        }
    }
    
    ///
    /// 处理点击逻辑
    /// 如果处于拖动状态则拦截点击事件，防止误触
    ///
    @objc private func handleTap() {
        if isDragging { return }
        
        avatarButton.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.avatarButton.transform = CGAffineTransform(scaleX: 5.0, y: 5.0)
            self.avatarButton.alpha = 0
        }) { _ in
            self.openChatViewController()
            
            self.avatarButton.transform = .identity
            self.avatarButton.alpha = 1.0
            self.startBreathingAnimation()
        }
    }
    
    // MARK: - 页面导航
    ///
    ///  Window 不属于正常的路由堆栈（Navigation/Tabbar），
    ///  必须利用 UIWindowScene 树找到当前最顶层的活跃 ViewController，让它来 present
    ///
    private func openChatViewController() {
        let chatVC = ChatViewController()
        chatVC.modalPresentationStyle = .fullScreen
        chatVC.modalTransitionStyle = .crossDissolve
        
        if let topVC = getTopViewController() {
            // 防重入
            if topVC is ChatViewController { return }
            topVC.present(chatVC, animated: true)
        }
    }
    
    ///
    /// 寻找顶层视图控制器
    /// 从 UIApplication 遍历寻找当前用户肉眼能看到的最顶层视图控制器
    ///
    private func getTopViewController() -> UIViewController? {
        // 在 iOS 13+ 中获取当前 active 的 UIWindowScene
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return nil }
        guard let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else { return nil }
        
        var topController = keyWindow.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        if let nav = topController as? UINavigationController {
            topController = nav.visibleViewController
        } else if let tab = topController as? UITabBarController {
            topController = tab.selectedViewController
        }
        
        return topController
    }
    
    // MARK: - Hit Test
    ///
    /// 重写hit-testing
    /// 除了点击avatar本身，其他业务点击不拦截
    ///
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self || hitView == self.rootViewController?.view {
            return nil
        }
        return hitView
    }
}
