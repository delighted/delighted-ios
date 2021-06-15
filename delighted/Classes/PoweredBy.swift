import UIKit

class PoweredBy: UIButton {

    let buttonConfiguration: SurveyConfiguration

    init(configuration: SurveyConfiguration) {
        self.buttonConfiguration = configuration
        super.init(frame: CGRect.zero)
        setupView()
    }

    override init(frame: CGRect) {
        fatalError()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        setTitle(buttonConfiguration.poweredByLinkText, for: .normal)
        setTitleColor(buttonConfiguration.theme.secondaryTextColor.color, for: .normal)
        titleLabel?.numberOfLines = 1
        titleLabel?.textAlignment = .center
        titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .light)

        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }

    @objc func onTap() {
        if let url = URL(string: buttonConfiguration.poweredByLinkURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
}
