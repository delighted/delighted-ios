import UIKit

class Scale: UIView {
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

    private lazy var ces: CESComponent = {
        let view = CESComponent(
            configuration: configuration,
            minLabel: minLabel,
            maxLabel: maxLabel,
            minNumber: minNumber,
            maxNumber: maxNumber,
            onSelection: onSelection)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var nps: NPSComponent = {
        let view = NPSComponent(
            configuration: configuration,
            minLabel: minLabel,
            maxLabel: maxLabel,
            minNumber: minNumber,
            maxNumber: maxNumber,
            onSelection: onSelection)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var showNPS = {
        return maxNumber - minNumber > 5
    }()

    func adjustForInitialDisplay() {
        if showNPS {
            nps.adjustForInitialDisplay()
        }
    }

    private func setupView() {
        clipsToBounds = false

        let view: UIView = showNPS ? nps : ces
        self.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
    }
}
