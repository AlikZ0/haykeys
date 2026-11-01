import UIKit

final class SoundInputView: UIInputView, UIInputViewAudioFeedback {
    var clicksEnabled = true
    var enableInputClicksWhenVisible: Bool { clicksEnabled }
}

final class KeyboardViewController: UIInputViewController {
    private var state = KeyboardState()
    private var applyingSoundSettings = false
    private var appliedTheme: KeyboardTheme?
    private var geometry = KeyboardGeometry(width: 402, landscape: false)
    private let root = UIStackView()
    private var keyRows: [UIStackView] = []
    private var keyButtons: [KeyButton] = []
    private var shiftButton: KeyButton?
    private var returnButton: KeyButton?
    private var globeButton: KeyButton?
    private var spaceLanguageLabel: UILabel?
    private var bottomRow: UIStackView?
    private var bottomInsetConstraint: NSLayoutConstraint?
    private var topInsetConstraint: NSLayoutConstraint?
    private var showsGlobe = false
    private var heightConstraint: NSLayoutConstraint?
    private var deleteTimer: Timer?
    private var previousKeyboardType: UIKeyboardType?
    private var cursorX: CGFloat = 0

    override func loadView() {
        let keyboardView = SoundInputView(frame: .zero, inputViewStyle: .keyboard)
        keyboardView.allowsSelfSizing = true
        keyboardView.backgroundColor = .clear
        inputView = keyboardView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        primaryLanguage = "hy"
        buildKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyInputTraits()
        _ = applySoundSettingsIfSelected()
        refresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = applySoundSettingsIfSelected()
        refresh()
        refreshAfterProxyUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopDeleting()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard view.bounds.width > 0 else { return }
        if appliedTheme != resolvedTheme { refresh() }
        if showsGlobe != needsInputModeSwitchKey {
            buildKeyboard()
            return
        }
        // Face ID iPhones provide the globe/dictation area outside this extension.
        let compact = traitCollection.verticalSizeClass == .compact || view.bounds.width > 560
        // The landscape host reserves horizontal space for the system controls.
        // Use the same safe horizontal bounds for key placement and width calculations.
        let availableWidth = max(0, view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right)
        guard availableWidth > 0 else { return }
        let next = KeyboardGeometry(width: Double(availableWidth), landscape: compact)
        if geometry.width != next.width || geometry.landscape != next.landscape {
            geometry = next
            updateGeometry()
        }
        // The system already owns the globe/microphone area beneath this view.
        // Adding its bottom inset here creates an extra empty strip.
        let height = CGFloat(geometry.preferredHeight)
        if let heightConstraint, abs(heightConstraint.constant - height) > 0.5 {
            heightConstraint.constant = height
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        applyInputTraits()
        _ = applySoundSettingsIfSelected()
        refresh()
        refreshAfterProxyUpdate()
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if applySoundSettingsIfSelected() { return }
        refresh()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        if applySoundSettingsIfSelected() { return }
        refresh()
        refreshAfterProxyUpdate()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        refresh()
    }

    private func applyInputTraits() {
        let type = textDocumentProxy.keyboardType ?? .default
        guard previousKeyboardType != type else { return }
        previousKeyboardType = type
        switch type {
        case .numberPad, .decimalPad, .numbersAndPunctuation, .asciiCapableNumberPad:
            state.selectPage(.numbers)
        default:
            state.selectPage(.letters)
        }
        buildKeyboard()
    }

    private func buildKeyboard() {
        stopDeleting()
        root.removeFromSuperview()
        root.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyRows.removeAll()
        keyButtons.removeAll()
        shiftButton = nil
        returnButton = nil
        globeButton = nil
        spaceLanguageLabel = nil
        showsGlobe = needsInputModeSwitchKey

        root.axis = .vertical
        root.spacing = CGFloat(geometry.rowGap)
        root.translatesAutoresizingMaskIntoConstraints = false
        root.semanticContentAttribute = .forceLeftToRight
        root.insetsLayoutMarginsFromSafeArea = false
        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 6),
            root.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -6)
        ])
        let topInset = root.topAnchor.constraint(equalTo: view.topAnchor, constant: CGFloat(geometry.topInset))
        topInset.isActive = true
        topInsetConstraint = topInset
        let bottomInset = root.bottomAnchor.constraint(
            equalTo: view.bottomAnchor, constant: -CGFloat(geometry.bottomInset)
        )
        bottomInset.isActive = true
        bottomInsetConstraint = bottomInset
        if heightConstraint == nil {
            let constraint = view.heightAnchor.constraint(equalToConstant: CGFloat(geometry.preferredHeight))
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
            heightConstraint = constraint
        }

        for (index, values) in KeyboardLayout.rows(for: state.page).enumerated() {
            let row = makeRow()
            if index == 3 {
                if state.page == .letters {
                    let key = makeKey(action: .shift, special: true)
                    key.accessibilityLabel = "Заглавные буквы"
                    key.accessibilityHint = "Двойное нажатие включает Caps Lock"
                    shiftButton = key
                    row.addArrangedSubview(key)
                } else {
                    let next: KeyboardPage = state.page == .numbers ? .symbols : .numbers
                    let key = makeKey(action: .page(next), special: true)
                    key.setTitle(next == .symbols ? "#+=" : "123", for: .normal)
                    key.accessibilityLabel = next == .symbols ? "Символы" : "Цифры"
                    key.titleLabel?.font = .systemFont(ofSize: 16)
                    row.addArrangedSubview(key)
                }
            }
            for value in values {
                row.addArrangedSubview(makeKey(action: .insert(value)))
            }
            if index == 3 {
                let key = makeKey(action: .backspace, special: true)
                key.setImage(UIImage(systemName: "delete.left"), for: .normal)
                key.accessibilityLabel = "Удалить"
                key.accessibilityHint = "Удерживайте для непрерывного удаления"
                row.addArrangedSubview(key)
            }
            root.addArrangedSubview(row)
            if let first = keyRows.first {
                row.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true
            }
            keyRows.append(row)
        }

        let bottom = makeRow()
        bottom.distribution = .fill
        bottomRow = bottom
        let mode = makeKey(action: .page(state.page == .letters ? .numbers : .letters), special: true)
        mode.setTitle(state.page == .letters ? "123" : "ԱԲԳ", for: .normal)
        mode.titleLabel?.font = .systemFont(ofSize: 20)
        mode.accessibilityLabel = state.page == .letters ? "Цифры и символы" : "Армянские буквы"
        let space = makeKey(action: .space)
        space.accessibilityLabel = "Пробел"
        space.accessibilityHint = "Удерживайте и двигайте палец для перемещения курсора"
        let cursorGesture = UILongPressGestureRecognizer(target: self, action: #selector(moveCursor(_:)))
        cursorGesture.minimumPressDuration = 0.35
        space.addGestureRecognizer(cursorGesture)
        let language = UILabel()
        language.text = "Հայերեն"
        language.font = .systemFont(ofSize: 9, weight: .regular)
        language.isUserInteractionEnabled = false
        language.isAccessibilityElement = false
        language.translatesAutoresizingMaskIntoConstraints = false
        space.addSubview(language)
        NSLayoutConstraint.activate([
            language.trailingAnchor.constraint(equalTo: space.trailingAnchor, constant: -7),
            language.bottomAnchor.constraint(equalTo: space.bottomAnchor, constant: -4)
        ])
        spaceLanguageLabel = language
        let lineBreak = makeKey(action: .lineBreak, special: true)
        lineBreak.titleLabel?.font = .systemFont(ofSize: 16)
        lineBreak.titleLabel?.minimumScaleFactor = 0.65
        lineBreak.accessibilityLabel = "Ввод"
        lineBreak.accessibilityHint = "Удерживайте, чтобы скрыть клавиатуру"
        lineBreak.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(hideKeyboard(_:))))
        returnButton = lineBreak
        bottom.addArrangedSubview(mode)
        if showsGlobe {
            let globe = KeyButton(special: true)
            globe.setImage(UIImage(systemName: "globe"), for: .normal)
            globe.accessibilityLabel = "Сменить клавиатуру"
            globe.accessibilityHint = "Удерживайте, чтобы открыть список клавиатур"
            globe.addTarget(self, action: #selector(playKeyClick), for: .touchDown)
            globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
            bottom.addArrangedSubview(globe)
            globe.widthAnchor.constraint(equalTo: mode.widthAnchor, multiplier: 0.5).isActive = true
            globeButton = globe
            keyButtons.append(globe)
        }
        [space, lineBreak].forEach { bottom.addArrangedSubview($0) }
        NSLayoutConstraint.activate([
            space.widthAnchor.constraint(equalTo: mode.widthAnchor, multiplier: 2.25),
            lineBreak.widthAnchor.constraint(equalTo: mode.widthAnchor, multiplier: 1.1)
        ])
        root.addArrangedSubview(bottom)
        if let first = keyRows.first {
            bottom.heightAnchor.constraint(equalTo: first.heightAnchor).isActive = true
        }

        updateGeometry()
        refresh()
    }

    private func updateGeometry() {
        root.spacing = CGFloat(geometry.rowGap)
        bottomInsetConstraint?.constant = -CGFloat(geometry.bottomInset)
        topInsetConstraint?.constant = CGFloat(geometry.topInset)
        let rows = KeyboardLayout.rows(for: state.page)
        for (index, row) in keyRows.enumerated() {
            let count = rows[index].count + (index == 3 ? 2 : 0)
            let inset = CGFloat(geometry.inset(for: count))
            row.spacing = CGFloat(geometry.keyGap)
            row.isLayoutMarginsRelativeArrangement = true
            row.insetsLayoutMarginsFromSafeArea = false
            row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 0, trailing: inset)
        }
        bottomRow?.spacing = CGFloat(geometry.keyGap)
        for key in keyButtons {
            if case .insert? = key.keyAction {
                key.titleLabel?.font = .systemFont(ofSize: CGFloat(geometry.fontSize), weight: .regular)
            }
        }
    }

    private func makeRow() -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = CGFloat(geometry.keyGap)
        row.distribution = .fillEqually
        row.semanticContentAttribute = .forceLeftToRight
        return row
    }

    private func makeKey(action: KeyAction, special: Bool = false) -> KeyButton {
        let key = KeyButton(action: action, special: special)
        if case .backspace = action {
            key.addTarget(self, action: #selector(startDeleting), for: .touchDown)
            key.addTarget(self, action: #selector(stopDeleting),
                          for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        } else {
            key.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        }
        if case .insert(let value) = action, value == "ե" || value == "ւ" {
            key.alternateText = value == "ե" ? "և" : "ու"
            key.accessibilityHint = "Удерживайте для \(key.alternateText ?? "")"
            let alternateGesture = UILongPressGestureRecognizer(
                target: self, action: #selector(insertAlternate(_:))
            )
            alternateGesture.minimumPressDuration = 0.4
            key.addGestureRecognizer(alternateGesture)
        }
        keyButtons.append(key)
        return key
    }

    @objc private func insertAlternate(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let key = gesture.view as? KeyButton,
              let text = key.alternateText else { return }
        if applySoundSettingsIfSelected() { return }
        playKeyClick()
        insert(state.output(for: text))
    }

    @objc private func keyTapped(_ sender: KeyButton) {
        if applySoundSettingsIfSelected() { return }
        playKeyClick()
        guard let action = sender.keyAction else { return }
        switch action {
        case .insert(let text): insert(state.output(for: text))
        case .space: insert(" ")
        case .lineBreak: insert("\n")
        case .shift:
            state.tapShift(at: Date.timeIntervalSinceReferenceDate)
            refresh()
        case .page(let page):
            state.selectPage(page)
            buildKeyboard()
        case .dismiss: dismissKeyboard()
        case .backspace: break // Handled on touchDown, including press-and-hold.
        }
    }

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        state.didInsert(text)
        refresh()
        refreshAfterProxyUpdate()
    }

    @objc private func playKeyClick() {
        guard (inputView as? SoundInputView)?.clicksEnabled == true else { return }
        UIDevice.current.playInputClick()
    }

    private func applySoundSettingsIfSelected() -> Bool {
        guard !applyingSoundSettings,
              let selected = textDocumentProxy.selectedText,
              let request = SoundSettingsRequest.parse(selected) else { return false }
        applyingSoundSettings = true
        defer { applyingSoundSettings = false }
        UserDefaults.standard.set(request.enabled, forKey: KeyboardSettings.soundKey)
        (inputView as? SoundInputView)?.clicksEnabled = request.enabled
        // Replaces only the selected transaction, never the surrounding document.
        textDocumentProxy.insertText(request.acknowledgement)
        return true
    }

    private var resolvedTheme: KeyboardTheme {
        let interfaceIsDark = traitCollection.userInterfaceStyle == .dark ||
            view.traitCollection.userInterfaceStyle == .dark ||
            view.window?.traitCollection.userInterfaceStyle == .dark
        return KeyboardTheme.resolve(
            interfaceIsDark: interfaceIsDark,
            fieldRequestsDark: textDocumentProxy.keyboardAppearance == .dark
        )
    }

    private func refresh() {
        guard isViewLoaded else { return }
        (inputView as? SoundInputView)?.clicksEnabled = KeyboardSettings.soundEnabled(
            stored: UserDefaults.standard.object(forKey: KeyboardSettings.soundKey) as? Bool
        )
        let theme = resolvedTheme
        appliedTheme = theme
        let dark = theme == .dark
        // UIInputView.Style.keyboard supplies the system blur/tint underneath our keys.
        // Do not cover it with an opaque panel or impose a second set of top corners.
        view.backgroundColor = .clear
        for key in keyButtons {
            key.isDark = dark
            if case .insert(let value)? = key.keyAction {
                let output = state.output(for: value)
                key.setTitle(output, for: .normal)
                key.accessibilityLabel = output
            }
            key.updateColors()
        }
        let shiftIcon = state.shift == .locked ? "capslock.fill" :
            (state.shift == .once ? "shift.fill" : "shift")
        shiftButton?.setImage(UIImage(systemName: shiftIcon), for: .normal)
        shiftButton?.isActive = state.shift != .off
        shiftButton?.accessibilityValue = state.shift == .locked ? "Caps Lock" :
            (state.shift == .once ? "Одна заглавная буква" : "Строчные буквы")
        shiftButton?.updateColors()
        spaceLanguageLabel?.textColor = (dark ? UIColor.white : UIColor.black).withAlphaComponent(0.28)
        updateReturnLabel()
    }

    private func updateReturnLabel() {
        let title: String?
        switch textDocumentProxy.returnKeyType ?? .default {
        case .go: title = "Գնալ"
        case .search, .google, .yahoo: title = "Որոնել"
        case .send: title = "Ուղարկել"
        case .done: title = "Պատրաստ"
        case .next: title = "Հաջորդ"
        default: title = nil
        }
        returnButton?.setTitle(title, for: .normal)
        returnButton?.setImage(title == nil ? UIImage(systemName: "return") : nil, for: .normal)
    }

    private func refreshAfterProxyUpdate() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !self.applySoundSettingsIfSelected() { self.refresh() }
        }
    }

    @objc private func startDeleting() {
        if applySoundSettingsIfSelected() { return }
        stopDeleting()
        deleteOneCharacter()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.deleteOneCharacter()
            self.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.075, repeats: true) { [weak self] _ in
                self?.deleteOneCharacter()
            }
        }
    }

    private func deleteOneCharacter() {
        playKeyClick()
        textDocumentProxy.deleteBackward()
        refreshAfterProxyUpdate()
    }

    @objc private func stopDeleting() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }

    @objc private func hideKeyboard(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { dismissKeyboard() }
    }

    @objc private func moveCursor(_ gesture: UILongPressGestureRecognizer) {
        let x = gesture.location(in: view).x
        switch gesture.state {
        case .began:
            cursorX = x
            spaceLanguageLabel?.text = "↔"
        case .changed:
            let steps = Int((x - cursorX) / 10)
            if steps != 0 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: steps)
                cursorX += CGFloat(steps) * 10
                refreshAfterProxyUpdate()
            }
        case .ended, .cancelled, .failed:
            spaceLanguageLabel?.text = "Հայերեն"
        default: break
        }
    }
}
