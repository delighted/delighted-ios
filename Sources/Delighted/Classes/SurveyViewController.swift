import UIKit

public class SurveyViewController: UIViewController, DelightedPageViewControllerPage {
    let pageViewController: DelightedPageViewController
    var session: SurveySession

    var survey: Survey {
        return session.surveyRequest.survey
    }
    var configuration: SurveyConfiguration {
        return session.configuration
    }

    var theme: Theme {
        return configuration.theme
    }

    var isFullScreen = false

    let footerBottomMarging: CGFloat = 20

    init(pageViewController: DelightedPageViewController, session: SurveySession) {
        self.pageViewController = pageViewController
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        session.disconnectPusher()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Tap gesture to hide modal on background tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap(sender:)))
        tapGesture.delegate = self
        backgroundView.addGestureRecognizer(tapGesture)
        backgroundView.isUserInteractionEnabled = true

        setupView()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerNotifications()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
        super.viewWillDisappear(animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        unregisterNotifications()
        super.viewDidDisappear(animated)
    }

    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        pageViewController.dismiss(animated: flag, completion: completion)
    }

    @objc func onTap(sender: Any?) {
        hide { [weak self] in
            self?.dismiss(animated: false) { [weak self] in
                self?.sendToCallback()
            }
        }
    }

    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.semiTransparentBlack
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = theme.backgroundColor.color

        view.clipsToBounds = true
        view.layer.cornerRadius = theme.containerCornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var closeButton: UIButton = {
        let button = CloseButton(theme: theme)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onCloseModal(sender:)), for: .touchUpInside)

        return button
    }()

    private lazy var closeButtonForNavController: UIButton = {
        let button = CloseButton(theme: theme)
        button.addTarget(self, action: #selector(onCloseNavigationController(sender:)), for: .touchUpInside)

        return button
    }()

    private lazy var questionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.attributedText = survey.template.questionText.setParagraphStyle(lineSpacing: 3, alignment: .center)
        label.font = configuration.font(ofSize: 18)
        label.textColor = theme.primaryTextColor.color
        label.numberOfLines = 0

        return label
    }()

    private lazy var questionComponent: Component = {
        let component: Component
        switch survey.type.id {
        case .ces:
            component = CESComponent(
                configuration: configuration,
                minLabel: configuration.notLikelyText,
                maxLabel: configuration.veryLikelyText,
                minNumber: 1,
                maxNumber: 5,
                onSelection: self.onSelection
            )
        case .ces7:
            component = CESComponent(
                configuration: configuration,
                minLabel: configuration.notLikelyText,
                maxLabel: configuration.veryLikelyText,
                minNumber: 1,
                maxNumber: 7,
                onSelection: self.onSelection
            )
        case .csat:
            component = CSATComponent(
                configuration: configuration,
                minLabel: configuration.notLikelyText,
                maxLabel: configuration.veryLikelyText,
                minNumber: 1,
                maxNumber: 5,
                onSelection: self.onSelection
            )
        case .csat3:
            component = CSAT3Component(configuration: configuration, template: survey.template, onSelection: self.onSelection)
        case .smileys:
            component = SmileysComponent(configuration: configuration, onSelection: self.onSelection)
        case .starsFive:
            component = StarsComponent(configuration: configuration, onSelection: self.onSelection)
        case .thumbs:
            component = ThumbsComponent(configuration: configuration, onSelection: self.onSelection)
        case .nps, .enps:
            component = NPSComponent(
                configuration: configuration,
                minLabel: configuration.notLikelyText,
                maxLabel: configuration.veryLikelyText,
                minNumber: 0,
                maxNumber: 10,
                onSelection: self.onSelection
            )
        case .pmf:
            component = PMFComponent(configuration: configuration, template: survey.template, onSelection: self.onSelection)
        }

        component.translatesAutoresizingMaskIntoConstraints = false

        return component
    }()

    private lazy var commentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = theme.primaryTextColor.color
        label.font = configuration.font(ofSize: 16)

        label.alpha = 0
        label.isHidden = true

        return label
    }()

    private lazy var commentTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false

        textView.layer.borderColor = theme.textarea.borderColor.color.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = SurveyConfiguration.cornerRadius
        textView.font = configuration.font(ofSize: 18)
        textView.textColor = theme.textarea.textColor.color
        textView.backgroundColor = theme.textarea.backgroundColor.color
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = self

        switch configuration.theme.ios.keyboardAppearance {
        case .light?:
            textView.keyboardAppearance = .light
        case .dark?:
            textView.keyboardAppearance = .dark
        case nil:
            ()
        }

        textView.alpha = 0
        textView.isHidden = true

        return textView
    }()

    private lazy var submitButton: Button = {
        let button = Button(surveyConfiguration: configuration, mode: .primary)
        button.translatesAutoresizingMaskIntoConstraints = false

        let buttonTitle = self.survey.template.additionalQuestions.isEmpty ? self.configuration.submitText : self.configuration.nextText
        button.setTitle(buttonTitle, for: .normal)
        button.addTarget(self, action: #selector(onSubmit(sender:)), for: .touchUpInside)

        button.alpha = 0
        button.isHidden = true

        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center

        return button
    }()

    private lazy var poweredByLabel: PoweredBy = {
        let button = PoweredBy(configuration: self.configuration)
        button.isHidden = true
        button.alpha = 0
        return button
    }()

    lazy var hiddenConstraintTop: NSLayoutConstraint = {
        let constraint =  container.topAnchor.constraint(equalTo: view.bottomAnchor)
        constraint.priority = UILayoutPriority.defaultLow
        return constraint
    }()

    lazy var cardConstraintTop: NSLayoutConstraint = {
        let constraint = container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        constraint.priority = UILayoutPriority.defaultHigh
        return constraint
    }()

    lazy var modalConstraintCenter: NSLayoutConstraint = {
        let constraint = container.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        constraint.priority = UILayoutPriority.defaultHigh
        return constraint
    }()

    lazy var fullScreenConstraintTop: NSLayoutConstraint = {
        let constraint = container.topAnchor.constraint(equalTo: view.topAnchor)
        constraint.priority = UILayoutPriority.defaultHigh
        return constraint
    }()

    lazy var closeButtonConstraintTop: NSLayoutConstraint = {
        let constraint = closeButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 0)
        return constraint
    }()

    lazy var questionLabelConstraintTop: NSLayoutConstraint = {
        let constraint = questionLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 55)
        return constraint
    }()

    lazy var fullHeightConstraint: NSLayoutConstraint = {
        let constraint = container.heightAnchor.constraint(equalTo: view.heightAnchor)
        constraint.priority = UILayoutPriority.defaultLow
        return constraint
    }()

    lazy var containerEdgeLeadingConstraint: NSLayoutConstraint = {
        return container.leadingAnchor.constraint(equalTo: view.leadingAnchor)
    }()

    lazy var containerEdgeTrailingConstraint: NSLayoutConstraint = {
        return container.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    }()

    var containerEdgeMargin: CGFloat = 0 {
        didSet {
            containerEdgeLeadingConstraint.constant = containerEdgeMargin
            containerEdgeTrailingConstraint.constant = -containerEdgeMargin
        }
    }

    private lazy var footerBottomConstraint: NSLayoutConstraint = {
        return poweredByLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40)
    }()

    func onSelection(value: Int) {
        session.sendClientTyping()

        // Save survey response on API
        session.surveyResponse.score = value
        session.saveSurveyResponse()

        // Update comment prompt based on answer
        let commentPrompt = survey.template.commentPrompts["\(value)"]
        commentLabel.attributedText = commentPrompt?.setParagraphStyle(lineSpacing: 3, alignment: .center)

        // Update card/modal to full screen
        fullScreenIfNeeded()
    }

    private func sendToCallback() {
        session.callback?(.surveyClosed(session.status))
    }

    @objc func onCloseModal(sender: Any?) {
        view.endEditing(true)
        session.disconnectPusher()

        if isFullScreen {
            dismiss(animated: true) { [weak self] in
                self?.sendToCallback()
            }
        } else {
            hide { [weak self] in
                self?.dismiss(animated: false) { [weak self] in
                    self?.sendToCallback()
                }
            }
        }

    }

    @objc func onCloseNavigationController(sender: Any?) {
        session.disconnectPusher()

        pageViewController.dismiss(animated: true) { [weak self] in
            self?.sendToCallback()
        }
    }

    @objc func onSubmit(sender: Any?) {
        session.sendClientTyping()

        // Update comment text and save to API
        session.surveyResponse.comment = commentTextView.text
        session.saveSurveyResponse()

        // Hide close button on view controll and add on to navigation controller
        // This keeps close button static between view controller pushes
        closeButton.isHidden = true
        let frame = self.closeButton.frame
        closeButtonForNavController.frame = frame
        pageViewController.view.addSubview(closeButtonForNavController)

        let questions = session.surveyRequest.survey.template.additionalQuestions

        if questions.count == 0 {
            pageViewController.state = .thankYou
        } else {
            pageViewController.state = .additionalQuestions
        }
    }

    public func show() {
        switch configuration.theme.display {
        case .card:
            showCard()
        case .modal:
            showModal()
        }
    }

    // Animate in the card looking modal
    public func hide(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.backgroundView.alpha = 0
            self?.closeButtonForNavController.isHidden = true
        }

        // Spring animate in the modal
        hiddenConstraintTop.isActive = true
        cardConstraintTop.isActive = false
        fullScreenConstraintTop.isActive = false
        modalConstraintCenter.isActive = false

        UIView.animate(withDuration: 0.7,
                       delay: 0.0,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 0.15,
                       options: [],
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
            }, completion: { (_: Bool) in
                completion?()
        })
    }
}

private extension SurveyViewController {
    func registerNotifications() {
        #if swift(>=4.2)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        #else
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        #endif
    }

    func unregisterNotifications() {
        #if swift(>=4.2)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        #else
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        #endif
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        #if swift(>=4.2)
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        #else
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        #endif

        let height = self.view.convert(keyboardFrame.cgRectValue, from: nil).size.height
        KeyboardHeightHistory.lastHeight = height
        footerBottomConstraint.constant = -(height + footerBottomMarging)
    }

    @objc func keyboardWillHide(notification: NSNotification) {

    }
}

extension SurveyViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        session.sendClientTyping()
    }
}

extension SurveyViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
}

private extension SurveyViewController {
    func setupView() {
        self.view.addSubview(backgroundView)
        self.view.addSubview(container)
        container.addSubview(closeButton)
        container.addSubview(questionLabel)
        container.addSubview(questionComponent)
        container.addSubview(commentLabel)
        container.addSubview(commentTextView)
        container.addSubview(submitButton)
        container.addSubview(poweredByLabel)

        // 40px for components with labels below
        // 60px for everything else
        let componentBottomMargin: CGFloat = {
            switch questionComponent {
            case is CESComponent, is CSATComponent, is NPSComponent:
                return 40
            default:
                return 60
            }
        }()

        let verticalSpacing: CGFloat = 20
        let sidePadding: CGFloat = 25

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            containerEdgeLeadingConstraint,
            containerEdgeTrailingConstraint,
            hiddenConstraintTop,

            closeButtonConstraintTop,
            closeButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 0),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 50),

            questionLabelConstraintTop,
            questionLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: sidePadding),
            questionLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -sidePadding),

            questionComponent.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: verticalSpacing),
            questionComponent.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            questionComponent.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: sidePadding),
            questionComponent.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -sidePadding),

            commentLabel.topAnchor.constraint(equalTo: questionComponent.bottomAnchor, constant: verticalSpacing),
            commentLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: sidePadding),
            commentLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -sidePadding),

            commentTextView.topAnchor.constraint(equalTo: commentLabel.bottomAnchor, constant: verticalSpacing),
            commentTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: sidePadding),
            commentTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -sidePadding),

            submitButton.topAnchor.constraint(equalTo: commentTextView.bottomAnchor, constant: verticalSpacing),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sidePadding),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sidePadding),
            submitButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            poweredByLabel.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: verticalSpacing),
            poweredByLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            container.bottomAnchor.constraint(greaterThanOrEqualTo: questionComponent.bottomAnchor, constant: componentBottomMargin)
        ])

        containerEdgeMargin = 0
        view.layoutIfNeeded()
    }
}

private extension SurveyViewController {
    // Animate in the card looking modal
    func showCard(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.backgroundView.alpha = 1
        }

        // Spring animate in the modal
        hiddenConstraintTop.isActive = false
        cardConstraintTop.isActive = true
        fullScreenConstraintTop.isActive = false

        UIView.animate(withDuration: 0.6,
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.75,
                       options: [],
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
            }, completion: { [weak self] (_: Bool) in
                self?.questionComponent.adjustForInitialDisplay()
        })
    }

    // Animate in the card looking modal
    func showModal(completion: (() -> Void)? = nil) {
        containerEdgeMargin = configuration.modalMargin
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.backgroundView.alpha = 1
        }

        // Spring animate in the modal
        hiddenConstraintTop.isActive = false
        modalConstraintCenter.isActive = true
        fullScreenConstraintTop.isActive = false

        UIView.animate(withDuration: 0.6,
                       delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.75,
                       options: [],
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
            }, completion: { [weak self] (_: Bool) in
                self?.questionComponent.adjustForInitialDisplay()
        })
    }

    // Expand view from modal to full screen
    func fullScreenIfNeeded() {
        guard !isFullScreen else { return }

        commentTextView.becomeFirstResponder()
        commentTextView.resignFirstResponder()

        // This constants gets set in the keyboard notifications
        // We turn it on here when going full screen so the view gets properly
        // placed above the keyboard
        footerBottomConstraint.isActive = true

        commentLabel.isHidden = false
        commentTextView.isHidden = false
        submitButton.isHidden = false
        poweredByLabel.isHidden = false

        // Hide the original question
        questionLabel.height(constant: 0)

        closeButtonConstraintTop.constant = 35
        questionLabelConstraintTop.constant = 70
        hiddenConstraintTop.isActive = false
        cardConstraintTop.isActive = false

        fullScreenConstraintTop.isActive = true
        fullHeightConstraint.isActive = true

        questionComponent.adjustForFullScreen()
        containerEdgeMargin = 0

        // Expand animate to full screen
        // Show the text area and text area label
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            self?.view.layoutIfNeeded()

            self?.view.layer.cornerRadius = 0

            self?.commentLabel.alpha = 1
            self?.commentTextView.alpha = 1
            self?.submitButton.alpha = 1
            self?.poweredByLabel.alpha = 1
        }, completion: { [weak self] (_: Bool) in
            self?.isFullScreen = true
            self?.commentTextView.becomeFirstResponder()

            Delighted.window?.backgroundColor = self?.configuration.theme.backgroundColor.color

            // This is a work around for the cursor not appear and/or not
            // appearing with the right textContainerInset set
            // Adding a new line and removing it resets the textContainerInset from not
            // showing which may be from some animation issues
            self?.commentTextView.text = "\n"
            self?.commentTextView.text = ""
        })
    }
}
