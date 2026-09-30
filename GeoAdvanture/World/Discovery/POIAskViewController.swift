//
//  POIAskViewController.swift
//  GeoAdvanture
//
//  发现卡「问一问」弹层(PR-6 · 一期 AI 小功能)。
//  复用现有 AI 基础设施:AIContextManager 生成「按 POI」的 system prompt,
//  AINetworkManager.requestOptimalStream 做流式 + 打字机;断网/失败回退 POI 固定讲解。
//  轻量单轮问答:点快捷问或输入 → 上方展示对话流(打字机)。真美术到位后(PR-7)把头像/气泡换资源即可。
//

import UIKit
import SnapKit

final class POIAskViewController: UIViewController {

    private let poi: POI

    // UI
    private let dimView = UIView()
    private let sheet = UIView()
    private let answerView = UITextView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let chipsScroll = UIScrollView()
    private let chipsStack = UIStackView()

    private var isStreaming = false
    /// 本轮 AI 回答已累计的字数(用于判断是否需要回退固定讲解)。
    private var currentAnswerChars = 0

    /// 每个 POI 的常见追问(快捷问)。数据侧未配置时,用 POI 标题动态兜底。
    private var quickQuestions: [String] {
        [
            "「\(poi.title)」是怎么形成的呀?",
            "它和地球内部有什么关系呢?",
            "现实中哪里能看到它?"
        ]
    }

    init(poi: POI) {
        self.poi = poi
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildUI()
        appendGreeting()
        registerKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AINetworkManager.shared.stop()
    }

    // MARK: - UI

    private func buildUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))

        sheet.backgroundColor = UIColor(white: 0.12, alpha: 1)
        sheet.layer.cornerRadius = 22
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(440)
        }

        // 头部:向导头像 + 标题 + 关闭
        let avatar = UILabel()
        avatar.text = "🧭"
        avatar.font = .systemFont(ofSize: 30)
        avatar.textAlignment = .center
        avatar.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.25)
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true
        sheet.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        let titleLabel = UILabel()
        titleLabel.text = "问一问 · 岩小探"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        sheet.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(20)
        }

        let subtitle = UILabel()
        subtitle.text = "关于「\(poi.title)」尽管问我~"
        subtitle.font = .systemFont(ofSize: 12)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.6)
        sheet.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("✕", for: .normal)
        closeBtn.setTitleColor(.white, for: .normal)
        closeBtn.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        sheet.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalTo(avatar)
            make.width.height.equalTo(32)
        }

        // 对话流
        answerView.backgroundColor = UIColor(white: 0.16, alpha: 1)
        answerView.layer.cornerRadius = 14
        answerView.isEditable = false
        answerView.font = .systemFont(ofSize: 15)
        answerView.textColor = UIColor(white: 0.95, alpha: 1)
        answerView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        sheet.addSubview(answerView)
        answerView.snp.makeConstraints { make in
            make.top.equalTo(avatar.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(200)
        }

        // 快捷问 chips
        chipsScroll.showsHorizontalScrollIndicator = false
        sheet.addSubview(chipsScroll)
        chipsScroll.snp.makeConstraints { make in
            make.top.equalTo(answerView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
        }
        chipsStack.axis = .horizontal
        chipsStack.spacing = 8
        chipsStack.alignment = .center
        chipsScroll.addSubview(chipsStack)
        chipsStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalToSuperview()
        }
        for q in quickQuestions {
            chipsStack.addArrangedSubview(makeChip(q))
        }

        // 输入栏
        inputField.placeholder = "输入你的问题…"
        inputField.textColor = .white
        inputField.font = .systemFont(ofSize: 15)
        inputField.backgroundColor = UIColor(white: 0.2, alpha: 1)
        inputField.layer.cornerRadius = 18
        inputField.attributedPlaceholder = NSAttributedString(
            string: "输入你的问题…",
            attributes: [.foregroundColor: UIColor(white: 0.6, alpha: 1)])
        inputField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        inputField.leftViewMode = .always
        inputField.returnKeyType = .send
        inputField.delegate = self
        sheet.addSubview(inputField)

        sendButton.setTitle("发送", for: .normal)
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        sendButton.backgroundColor = .systemBlue
        sendButton.layer.cornerRadius = 18
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sheet.addSubview(sendButton)

        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.width.equalTo(64)
            make.height.equalTo(40)
        }
        inputField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalTo(sendButton.snp.leading).offset(-10)
            make.centerY.equalTo(sendButton)
            make.height.equalTo(40)
        }
    }

    private func makeChip(_ text: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(text, for: .normal)
        b.setTitleColor(.systemTeal, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 13)
        b.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.15)
        b.layer.cornerRadius = 15
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        b.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        return b
    }

    // MARK: - 对话

    private func appendGreeting() {
        answerView.text = "🧭 岩小探：你好呀!关于「\(poi.title)」,你想知道什么呢?点下面的问题,或者直接打字问我哦~\n"
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard let q = sender.title(for: .normal) else { return }
        ask(q)
    }

    @objc private func sendTapped() {
        let text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputField.text = ""
        ask(text)
    }

    private func ask(_ question: String) {
        guard !isStreaming else { return }
        view.endEditing(true)
        isStreaming = true
        currentAnswerChars = 0
        setSendEnabled(false)

        appendLine("\n🧒 我：\(question)")
        appendLine("\n🧭 岩小探：")

        let parameters: [String: Any] = [
            "model": "qwen-plus-character",
            "stream": true,
            "messages": [
                ["role": "system", "content": AIContextManager.shared.getPOIPrompt(for: poi)],
                ["role": "user", "content": question]
            ]
        ]

        AINetworkManager.shared.requestOptimalStream(parameters: parameters, prewarm: true) { [weak self] delta in
            guard let self = self else { return }
            self.currentAnswerChars += delta.count
            self.answerView.insertText(delta)
            self.scrollAnswerToBottom()
        } onComplete: { [weak self] error in
            guard let self = self else { return }
            self.isStreaming = false
            self.setSendEnabled(true)
            // 断网 / 失败 / 没吐出任何内容 → 回退到 POI 固定讲解,保证「不崩、有答案」
            if error != nil || self.currentAnswerChars == 0 {
                if self.currentAnswerChars == 0 {
                    self.answerView.insertText(self.poi.explanation)
                } else {
                    self.appendLine("\n(悄悄说:岩小探信号有点弱,先看看这个吧~)\n\(self.poi.explanation)")
                }
                self.scrollAnswerToBottom()
            }
        }
    }

    private func appendLine(_ text: String) {
        answerView.text.append(text)
        scrollAnswerToBottom()
    }

    private func scrollAnswerToBottom() {
        let len = (answerView.text as NSString).length
        if len > 0 { answerView.scrollRangeToVisible(NSRange(location: len - 1, length: 1)) }
    }

    private func setSendEnabled(_ enabled: Bool) {
        sendButton.isEnabled = enabled
        sendButton.alpha = enabled ? 1 : 0.5
    }

    @objc private func close() {
        AINetworkManager.shared.stop()
        dismiss(animated: true)
    }

    // MARK: - 键盘

    private func registerKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardChange(_ note: Notification) {
        guard let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let overlap = max(0, view.bounds.height - frame.origin.y)
        sheet.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-overlap)
        }
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardHide() {
        sheet.snp.updateConstraints { make in make.bottom.equalToSuperview() }
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
}

// MARK: - UITextFieldDelegate

extension POIAskViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}
