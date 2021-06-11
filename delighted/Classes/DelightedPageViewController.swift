import UIKit

protocol DelightedPageViewControllerPage {
    var pageViewController: DelightedPageViewController { get }
}

/// Custom navigation controller that forces portrait
/// and overrides dismiss by animating out the window
class DelightedPageViewController: UIPageViewController {
    enum State {
        case survey, additionalQuestions, thankYou
    }

    let session: SurveySession
    var state: State {
        didSet {
            updateViewController()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return session.configuration.theme.ios.statusBarHidden ?? false
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch session.configuration.theme.ios.statusBarMode {
        case .darkContent?:
            if #available(iOS 13.0, *) {
                return .darkContent
            } else {
                return .default
            }
        case .lightContent?:
            return .lightContent
        case nil:
            return .default
        }
    }

    lazy var surveyViewController: SurveyViewController = {
       return SurveyViewController(pageViewController: self, session: session)
    }()

    lazy var additionalQuestionViewControllers: [UIViewController] = {
        let surveyGroup = session.surveyRequest.survey.type.groups.first(where: { (group) -> Bool in
            return group.scoreMin...group.scoreMax ~= session.surveyResponse.score!
        })

        let additionalQuestions = session.surveyRequest.survey.template.additionalQuestions.filter({ question in
            guard let targetAudienceGroups = question.targetAudienceGroups else {
                return true
            }
            guard let targetGroup = surveyGroup else {
                return true
            }
            return targetAudienceGroups.contains(targetGroup.name)
        })

        let viewControllers = additionalQuestions.enumerated().map({ (arg) -> AdditionalQuestionViewController in
            let (index, question) = arg
            return AdditionalQuestionViewController(
                pageViewController: self,
                session: session,
                question: question,
                isFirstQuestion: index == 0,
                isLastQuestion: index == (additionalQuestions.count - 1)
            )
        })

        return viewControllers
    }()

    lazy var thankYouViewController: ThankYouViewController = {
        return ThankYouViewController(
            pageViewController: self,
            session: session
        )
    }()

    init(session: SurveySession) {
        self.session = session
        self.state = .survey

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)

        self.setViewControllers([surveyViewController], direction: .forward, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let edgePanLeft = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenLeftEdgeSwiped))
        edgePanLeft.edges = .left
        let edgePanRight = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenRightEdgeSwiped))
        edgePanRight.edges = .right

        view.addGestureRecognizer(edgePanLeft)
        view.addGestureRecognizer(edgePanRight)
    }

    @objc func screenLeftEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            previousPage()
        }
    }

    @objc func screenRightEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .recognized {
            nextPage()
        }
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard let window = Delighted.window else {
            return
        }

        if flag {
            // Animates the
            let windowFrame = window.frame
            let newFrame = CGRect(
                x: windowFrame.minX,
                y: windowFrame.maxY,
                width: windowFrame.width,
                height: windowFrame.height)

            UIView.animate(withDuration: 0.35, animations: {
                window.frame = newFrame
            }, completion: { (_) in
                // Releases the window
                Delighted.window = nil
                Delighted.surveying = false
                completion?()
            })
        } else {
            // Releases the window
            Delighted.window = nil
            Delighted.surveying = false
            completion?()
        }
    }
}

private extension DelightedPageViewController {
    func updateViewController() {
        switch state {
        case .survey:
            self.setViewControllers([surveyViewController], direction: .forward, animated: true)
        case .additionalQuestions:
            // Go to the first additional question
            if let firstAdditionalQuestionViewController = additionalQuestionViewControllers.first {
                self.setViewControllers([firstAdditionalQuestionViewController], direction: .forward, animated: true)
            } else {
                Logger.log(.error, "Couldn't find an additional question to navigate to - going to thank you screen")
                self.state = .thankYou
            }
        case .thankYou:
            self.setViewControllers([thankYouViewController], direction: .forward, animated: true)
        }
    }
}

extension DelightedPageViewController {
    func previousPage() {
        guard let viewController = viewControllers?.first else {
            return
        }

        switch state {
        case .survey, .thankYou:
            return
        case .additionalQuestions:
            guard let index = additionalQuestionViewControllers.firstIndex(of: viewController), index > 0 else {
                return
            }

            let previousViewController = additionalQuestionViewControllers[index - 1]
            self.setViewControllers([previousViewController], direction: .reverse, animated: true)

            return
        }
    }

    func nextPage() {
        guard let viewController = viewControllers?.first else {
            return
        }

        switch state {
        case .survey, .thankYou:
            return
        case .additionalQuestions:
            guard let index = additionalQuestionViewControllers.firstIndex(of: viewController), index < (additionalQuestionViewControllers.count - 1) else {
                return
            }

            let previousViewController = additionalQuestionViewControllers[index + 1]
            self.setViewControllers([previousViewController], direction: .forward, animated: true)

            return
        }
    }
}
