import UIKit

class CESComponent: UIView, Component {

    let configuration: SurveyConfiguration
    let minLabel: String
    let maxLabel: String

    let minNumber: Int
    let maxNumber: Int

    var theme: Theme {
        return configuration.theme
    }

    typealias OnSelection = (Int) -> Void
    let onSelection: OnSelection

    init(configuration: SurveyConfiguration, minLabel: String, maxLabel: String, minNumber: Int, maxNumber: Int, onSelection: @escaping OnSelection) {
        self.configuration = configuration
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.minNumber = minNumber
        self.maxNumber = maxNumber
        self.onSelection = onSelection
        super.init(frame: CGRect.zero)
        setupView()
    }

    override init(frame: CGRect) {
        fatalError()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private lazy var buttons: [Button] = {
        var buttons = [Button]()

        for i in minNumber...maxNumber {
            let button = Button(surveyConfiguration: configuration, mode: .scale)
            button.setTitle("\(i)", for: .normal)
            button.titleLabel?.font = configuration.font(ofSize: 16)
            button.isSelected = true

            button.addTarget(self, action: #selector(onSelection(sender:)), for: .touchUpInside)
            button.width(constant: 50)
            button.heightEqualWidth()

            buttons.append(button)
        }

        return buttons
    }()

    private lazy var lowerLabel: UILabel = {
        let label = UILabel()
        label.text = minLabel
        label.textColor = theme.secondaryTextColor.color
        label.font = configuration.font(ofSize: 15)
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private lazy var higherLabel: UILabel = {
        let label = UILabel()
        label.text = maxLabel
        label.textColor = theme.secondaryTextColor.color
        label.font = configuration.font(ofSize: 15)
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()

    private func setupView() {
        let component = ViewLayout.createCenterHorizontalStackView(
            subviews: buttons,
            alignment: .center,
            distribution: maxNumber >= 5 ? .fillEqually : .equalSpacing,
            spacing: 8
        )

        let labels = ViewLayout.createCenterHorizontalStackView(subviews: [lowerLabel, higherLabel], alignment: .top, distribution: .equalSpacing, spacing: 12)

        let container = ViewLayout.createCenterVerticalStackView(subviews: [component, labels], spacing: 18)
        container.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(container)

        // Component should scale full width if there are 5 or more
        // Otherwise component should be tight to the center
        if maxNumber >= 5 {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: self.topAnchor),
                container.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                container.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                container.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: self.topAnchor),
                container.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor),
                container.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor),
                container.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                container.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }

    func adjustForFullScreen() {
        lowerLabel.isHidden = true
        higherLabel.isHidden = true
    }

    @objc func onSelection(sender: Any?) {
        guard let buttonSelected = sender as? Button else {
            Logger.log(.fatal, "Could not cast selected object as a button")
            return
        }

        for button in buttons {
            button.isSelected = false
        }
        buttonSelected.isSelected = true

        if let index = buttons.firstIndex(of: buttonSelected) {
            let value = index + minNumber
            onSelection(value)
        } else {
            Logger.log(.fatal, "Error getting value from selected button")
        }
    }
}
