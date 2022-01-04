import UIKit

class CloseButton: UIButton {

    let theme: Theme

    lazy var xImageView: UIImageView = {
        let imageView = UIImageView(image: Images.x.templateImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = theme.closeButton.normalTextColor.color

        return imageView
    }()

    lazy var circleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = theme.closeButton.normalBackgroundColor.color

        view.layer.masksToBounds = false
        view.layer.cornerRadius = 12
        view.layer.borderColor = theme.closeButton.normalBorderColor.color.cgColor
        view.layer.borderWidth = 2

        view.isUserInteractionEnabled = false

        return view
    }()

    override var isHighlighted: Bool {
        willSet {
            super.isHighlighted = newValue
            updateTint()
        }
    }

    init(theme: Theme) {
        self.theme = theme
        super.init(frame: .zero)
        setupView()
        updateTint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTint() {
        switch isHighlighted {
        case false:
            xImageView.tintColor = theme.closeButton.normalTextColor.color
            circleView.backgroundColor = theme.closeButton.normalBackgroundColor.color
            circleView.layer.borderColor = theme.closeButton.normalBorderColor.color.cgColor
        case true:
            xImageView.tintColor = theme.closeButton.highlightedTextColor.color
            circleView.backgroundColor = theme.closeButton.highlightedBackgroundColor.color
            circleView.layer.borderColor = theme.closeButton.highlightedBorderColor.color.cgColor
        }
    }

    func setupView() {
        addSubview(circleView)
        addSubview(xImageView)

        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 24),
            circleView.heightAnchor.constraint(equalToConstant: 24),

            xImageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            xImageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
            xImageView.widthAnchor.constraint(equalToConstant: 10),
            xImageView.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
}
