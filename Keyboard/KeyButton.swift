import UIKit

enum KeyAction {
    case insert(String)
    case shift
    case backspace
    case page(KeyboardPage)
    case space
    case lineBreak
    case dismiss
}

final class KeyButton: UIButton {
    var keyAction: KeyAction?
    var alternateText: String?
    var isSpecial = false
    var isActive = false
    var isDark = false

    override var isHighlighted: Bool {
        didSet { updateColors() }
    }

    init(action: KeyAction? = nil, special: Bool = false) {
        keyAction = action
        isSpecial = special
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 6
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 0
        titleLabel?.font = .systemFont(ofSize: 25)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.45
        titleLabel?.lineBreakMode = .byClipping
        contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        accessibilityTraits = .keyboardKey
        updateColors()
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(action:special:)")
    }

    override func accessibilityActivate() -> Bool {
        if case .backspace? = keyAction {
            sendActions(for: .touchDown)
            sendActions(for: .touchUpInside)
            return true
        }
        return super.accessibilityActivate()
    }

    func updateColors() {
        let foreground: UIColor = isDark ? .white : .black
        let regular = isDark ? UIColor(white: 0.36, alpha: 1) : .white
        let special = isDark ? UIColor(white: 0.22, alpha: 1) : UIColor(white: 0.67, alpha: 1)
        backgroundColor = isHighlighted ? (isDark ? .darkGray : UIColor(white: 0.76, alpha: 1))
            : (isActive ? regular : (isSpecial ? special : regular))
        setTitleColor(foreground, for: .normal)
        tintColor = foreground
    }
}
