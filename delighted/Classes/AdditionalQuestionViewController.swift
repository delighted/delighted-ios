import UIKit

public class AdditionalQuestionViewController: UIViewController, DelightedPageViewControllerPage {
    let pageViewController: DelightedPageViewController
    var session: SurveySession

    let question: Survey.Template.AdditionalQuestion
    let isFirstQuestion: Bool
    let isLastQuestion: Bool

    var survey: Survey {
        return session.surveyRequest.survey
    }

    var configuration: SurveyConfiguration {
        return session.configuration
    }

    var theme: Theme {
        return configuration.theme
    }

    let footerBottomMarging: CGFloat = 20

    init(pageViewController: DelightedPageViewController, session: SurveySession, question: Survey.Template.AdditionalQuestion, isFirstQuestion: Bool, isLastQuestion: Bool) {
        self.pageViewController = pageViewController
        self.session = session
        self.question = question
        self.isFirstQuestion = isFirstQuestion
        self.isLastQuestion = isLastQuestion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if componentHasKeyboard {
            registerNotifications()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if componentHasKeyboard {
            // Needs to async due to page view controller transitions
            DispatchQueue.main.async {
                self.textArea.becomeFirstResponder()
            }
        }

        switch question.type {
        case .scale:
            scale.adjustForInitialDisplay()
        default:
            ()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        textArea.endEditing(true)
        super.viewWillDisappear(animated)
    }

    override public func viewDidDisappear(_ animated: Bool) {
        unregisterNotifications()
        super.viewDidDisappear(animated)
    }

    private lazy var questionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = configuration.font(ofSize: 18)
        label.textColor = theme.primaryTextColor.color
        return label
    }()

    private lazy var footerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var singleSelect: OptionSelect = {
        let view = OptionSelect(
            configuration: configuration,
            question: question,
            mode: .single) { [weak self] (options) in
                self?.addAnswer(options: options)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var multiSelect: OptionSelect = {
        let view = OptionSelect(
            configuration: configuration,
            question: question,
            mode: .multi) { [weak self] (options) in
                self?.addAnswer(options: options)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var textArea: TextArea = {
        let view = TextArea(configuration: configuration, onSelection: { [weak self] (text) in
            self?.addAnswer(value: text)
        })
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var scale: Scale = {
        let view = Scale(
            configuration: configuration,
            minLabel: question.scaleMinLabel ?? "",
            maxLabel: question.scaleMaxLabel ?? "",
            minNumber: question.scaleMin ?? 1,
            maxNumber: question.scaleMax ?? 5
        ) { [weak self] (value) in
            self?.addAnswer(value: "\(value)")
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var component: UIView = {
        let component: UIView
        switch question.type {
        case .selectOne:
            component = singleSelect
        case .selectMany:
            component = multiSelect
        case .freeResponse:
            component = textArea
        case .scale:
            component = scale
        }
        return component
    }()

    private lazy var nextButton: UIButton = {
        let button = Button(surveyConfiguration: configuration, mode: .primary)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.setTitle(configuration.nextText, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

        button.layer.masksToBounds = true
        button.layer.cornerRadius = SurveyConfiguration.cornerRadius
        button.addTarget(self, action: #selector(onNext(sender:)), for: .touchUpInside)

        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center

        return button
    }()

    private lazy var previousButton: UIButton = {
        let button = Button(surveyConfiguration: configuration, mode: .secondary)
        button.translatesAutoresizingMaskIntoConstraints = false

        button.setTitle(configuration.prevText, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

        button.layer.masksToBounds = true
        button.layer.cornerRadius = SurveyConfiguration.cornerRadius
        button.addTarget(self, action: #selector(onPrevious(sender:)), for: .touchUpInside)

        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center

        return button
    }()

    private lazy var poweredByLabel: PoweredBy = {
        let button = PoweredBy(configuration: self.configuration)
        return button
    }()

    private lazy var footerBottomConstraint: NSLayoutConstraint = {
        let constant = componentHasKeyboard ? KeyboardHeightHistory.lastHeight ?? 0 : 0

       return footerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(constant + footerBottomMarging))
    }()

    private lazy var componentHasKeyboard: Bool = {
        switch question.type {
        case .freeResponse: return true
        case .selectOne, .selectMany, .scale: return false
        }
    }()

    @objc func onNext(sender: Any?) {
        session.sendClientTyping()
        session.saveSurveyResponse()

        if isLastQuestion {
            pageViewController.state = .thankYou
        } else {
            pageViewController.nextPage()
        }
    }

    @objc func onPrevious(sender: Any?) {
        session.sendClientTyping()

        pageViewController.previousPage()
    }

    @objc func onClose(sender: Any?) {
        dismiss(animated: true)
    }
}

private extension AdditionalQuestionViewController {
    private func addAnswer(options: [Survey.Template.AdditionalQuestion.Option]) {
        let value = options.map({ $0.id }).joined(separator: ",")
        addAnswer(value: value)

        session.sendClientTyping()
    }

    private func addAnswer(value: String) {
        session.surveyResponse.addAnswer(id: question.id, value: value)
    }
}

private extension AdditionalQuestionViewController {
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

private extension AdditionalQuestionViewController {
    func setupView() {
        view.backgroundColor = theme.backgroundColor.color

        view.addSubview(questionLabel)
        view.addSubview(footerContainer)
        footerContainer.addSubview(previousButton)
        footerContainer.addSubview(nextButton)
        footerContainer.addSubview(poweredByLabel)

        let text = question.text
        questionLabel.attributedText = text.setParagraphStyle(lineSpacing: 3, alignment: .center)

        if isLastQuestion {
            nextButton.setTitle(configuration.doneText, for: .normal)
        }

        NSLayoutConstraint.activate([
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            questionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 90),

            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            footerBottomConstraint
        ])

        if isFirstQuestion {
            previousButton.isHidden = true
            NSLayoutConstraint.activate([
                nextButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
                nextButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
                nextButton.topAnchor.constraint(equalTo: footerContainer.topAnchor),
                nextButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
            ])
        } else {
            NSLayoutConstraint.activate([
                previousButton.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
                previousButton.trailingAnchor.constraint(equalTo: footerContainer.centerXAnchor, constant: -10),
                previousButton.topAnchor.constraint(equalTo: footerContainer.topAnchor),
                previousButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

                nextButton.leadingAnchor.constraint(equalTo: footerContainer.centerXAnchor, constant: 10),
                nextButton.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
                nextButton.topAnchor.constraint(equalTo: footerContainer.topAnchor),
                nextButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

                previousButton.heightAnchor.constraint(equalTo: nextButton.heightAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            poweredByLabel.leadingAnchor.constraint(equalTo: footerContainer.leadingAnchor),
            poweredByLabel.trailingAnchor.constraint(equalTo: footerContainer.trailingAnchor),
            poweredByLabel.topAnchor.constraint(equalTo: nextButton.bottomAnchor, constant: 20),
            poweredByLabel.bottomAnchor.constraint(equalTo: footerContainer.bottomAnchor)
        ])

        setupComponent()
    }

    func setupComponent() {
        view.addSubview(component)

        let bottomConstraint: NSLayoutConstraint = {
            switch component {
            case is OptionSelect:
                return component.bottomAnchor.constraint(equalTo: footerContainer.topAnchor, constant: -20)
            default:
                return component.bottomAnchor.constraint(lessThanOrEqualTo: footerContainer.topAnchor, constant: -20)
            }
        }()

        NSLayoutConstraint.activate([
            component.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            component.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            component.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 20),
            bottomConstraint
        ])
    }
}
