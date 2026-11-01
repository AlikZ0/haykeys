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
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 0.25
        titleLabel?.font = .systemFont(ofSize: 22, weight: .regular)
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.minimumScaleFactor = 0.75
        titleLabel?.lineBreakMode = .byClipping
        contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        accessibilityTraits = .keyboardKey
        imageView?.contentMode = .scaleAspectFit
        setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 21, weight: .regular), forImageIn: .normal)
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
        let foreground: UIColor = isActive ? .black : (isDark ? .white : .black)
        let regular = isDark ? UIColor(white: 0.38, alpha: 1) : .white
        let special = isDark ? UIColor(white: 0.25, alpha: 1) : .white
        let pressed = isDark ? UIColor(white: 0.55, alpha: 1) : UIColor(white: 0.78, alpha: 1)
        backgroundColor = isHighlighted ? pressed : (isActive ? .white : (isSpecial ? special : regular))
        layer.shadowOpacity = isDark ? 0 : 0.12
        setTitleColor(foreground, for: .normal)
        tintColor = foreground
    }

    // Cover the narrow gaps between adjacent Armenian keys without shrinking labels.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -2, dy: 0).contains(point)
    }
}
