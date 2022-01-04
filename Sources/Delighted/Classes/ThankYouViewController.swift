import UIKit

public class ThankYouViewController: UIViewController, DelightedPageViewControllerPage {
    let pageViewController: DelightedPageViewController
    let session: SurveySession

    var configuration: SurveyConfiguration {
        return session.configuration
    }

    var theme: Theme {
        return configuration.theme
    }

    lazy var task = DispatchWorkItem { [weak self] in
        self?.pageViewController.dismiss(animated: true) { [weak self] in
            self?.sendToCallback()
        }
    }

    init(pageViewController: DelightedPageViewController, session: SurveySession) {
        self.pageViewController = pageViewController
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Auto dismiss if thank you constains autoCloseDelay
        // First takes it from developer override and then from the thank you configuration
        if let delay = configuration.thankYouAutoCloseDelay ?? session.surveyRequest.thankYou.autoCloseDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(delay), execute: task)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        task.cancel()
        super.viewWillDisappear(animated)
    }

    private func sendToCallback() {
        session.callback?(.surveyClosed(session.status))
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = configuration.font(ofSize: 20)
        label.textColor = theme.primaryTextColor.color
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = configuration.font(ofSize: 16)
        label.textColor = theme.secondaryTextColor.color
        return label
    }()

    private lazy var linkButton: Button = {
        let button = Button(surveyConfiguration: configuration, mode: .primary)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 24)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onLinkClick(sender:)), for: .touchUpInside)
        return button
    }()

    private lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var poweredByLabel: PoweredBy = {
        let button = PoweredBy(configuration: self.configuration)
        return button
    }()

    private lazy var thankYouGroup: ThankYou.Group? = {
        guard let score = session.surveyResponse.score else {
            return nil
        }

        let surveyGroup = session.surveyRequest.survey.type.groups.first(where: { (group) -> Bool in
            return group.scoreMin...group.scoreMax ~= score
        })

        if let name = surveyGroup?.name {
            return session.surveyRequest.thankYou.groups.first(where: { (group) -> Bool in
                return group.name == name
            })
        }

        return nil
    }()

    @objc func onClose(sender: Any?) {
        dismiss(animated: true)
    }

    @objc func onLinkClick(sender: Any?) {
        if let thankYouGroup = thankYouGroup, let url = URL(string: thankYouGroup.linkURL!), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
    }
}

private extension ThankYouViewController {
    private func setupView() {
        view.backgroundColor = theme.backgroundColor.color

        view.addSubview(containerView)
        containerView.addSubview(textLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(linkButton)

        view.addSubview(footerContainer)
        footerContainer.addSubview(poweredByLabel)

        textLabel.text = session.surveyRequest.thankYou.text
        messageLabel.text = thankYouGroup?.messageText

        if let thankYouLinkText = thankYouGroup?.linkText {
            linkButton.setTitle(thankYouLinkText, for: .normal)
        } else {
            linkButton.isHidden = true
        }

        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            textLabel.topAnchor.constraint(equalTo: containerView.topAnchor),

            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            messageLabel.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 20),

            linkButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            linkButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            linkButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            linkButton.heightAnchor.constraint(equalToConstant: 50),

            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            footerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),

            poweredByLabel.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            poweredByLabel.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            poweredByLabel.topAnchor.constraint(equalTo: footerContainer.topAnchor, constant: 10),
            poweredByLabel.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor)
        ])
    }
}
