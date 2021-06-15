import UIKit

class NPSComponent: UIView, Component {
    let configuration: SurveyConfiguration
    let minLabel: String
    let maxLabel: String

    var theme: Theme {
        return configuration.theme
    }

    typealias OnSelection = (Int) -> Void
    let onSelection: OnSelection

    private let minNumber: Int
    private let numberOfTicks: Int

    private var adjustedForInitialDisplay = false

    // Tick views and constraints (used for snapping the thumb to a tick)
    private var tickViews = [Int: UIView]()
    private var tickViewSnapConstraints = [Int: [NSLayoutConstraint]]()

    // Used for sliding
    private var startingConstant: CGFloat  = 0.0
    private var lastPercent: CGFloat = 0
    private var lastValue: CGFloat = 0
    private var lastWholeNumber: CGFloat = 0

    // Used for shrinking either on touch end or pan end
    private var panGestureStarted = false

    // Constants for growing/shrinking of thumb size
    private let thumbNormalSize: CGFloat = 40
    private let thumbSelectedSize: CGFloat = 50

    init(configuration: SurveyConfiguration, minLabel: String, maxLabel: String, minNumber: Int, maxNumber: Int, onSelection: @escaping OnSelection) {
        self.configuration = configuration
        self.minLabel = minLabel
        self.maxLabel = maxLabel

        self.minNumber = minNumber
        self.numberOfTicks = maxNumber - minNumber

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

    private lazy var trackView: UIView = {
        let view = UIView()
        view.backgroundColor = theme.slider.trackInactiveColor.color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var filledTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = theme.slider.trackActiveColor.color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var touchableTrackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var touchableThumbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.clear
        return view
    }()

    private lazy var thumbViewLabel: UILabel = {
        let label = UILabel()
        label.textColor = theme.slider.knobTextColor.color
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = configuration.font(ofSize: 18)

        label.backgroundColor = theme.slider.knobBackgroundColor.color

        return label
    }()

    private lazy var thumbView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false

        view.layer.cornerRadius = thumbNormalSize / 2
        view.layer.backgroundColor = theme.slider.knobBackgroundColor.color.cgColor
        view.layer.borderWidth = 2
        view.layer.borderColor = theme.slider.knobBorderColor.color.cgColor

        return view
    }()

    private lazy var hoverView: UILabel = {
        let label = UILabel()
        label.textColor = theme.slider.hoverTextColor.color
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = configuration.font(ofSize: 18)

        label.layer.cornerRadius = 20
        label.layer.backgroundColor = theme.slider.hoverBackgroundColor.color.cgColor
        label.isHidden = true

        label.layer.borderColor = theme.slider.hoverBorderColor.color.cgColor
        label.layer.borderWidth = 2

        return label
    }()

    private lazy var labelRow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var lowerLabel: UILabel = {
        let label = UILabel()
        label.text = minLabel
        label.textColor = theme.secondaryTextColor.color
        label.font = configuration.font(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private lazy var higherLabel: UILabel = {
        let label = UILabel()
        label.text = maxLabel
        label.textColor = theme.secondaryTextColor.color
        label.font = configuration.font(ofSize: 15)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()

    private lazy var touchableThumbConstraint: NSLayoutConstraint = {
        let constraint = NSLayoutConstraint(item: touchableThumbView, attribute: .centerX, relatedBy: .equal, toItem: trackView, attribute: .left, multiplier: 1, constant: 0)
        constraint.priority = UILayoutPriority.defaultLow
        return constraint
    }()
    private lazy var thumbConstraint: NSLayoutConstraint = {
        let constraint = NSLayoutConstraint(item: thumbView, attribute: .centerX, relatedBy: .equal, toItem: trackView, attribute: .left, multiplier: 1, constant: 0)
        constraint.priority = UILayoutPriority.defaultLow
        return constraint
    }()
    private lazy var hoverConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint(item: hoverView, attribute: .centerX, relatedBy: .equal, toItem: thumbView, attribute: .centerX, multiplier: 1, constant: 0)
    }()
    private lazy var filledTrackViewConstraint: NSLayoutConstraint = {
        return filledTrackView.trailingAnchor.constraint(equalTo: thumbView.centerXAnchor, constant: 0)
    }()
    private lazy var thumbViewDiameterConstraint: NSLayoutConstraint = {
        return thumbView.heightAnchor.constraint(equalToConstant: thumbNormalSize)
    }()

    func setThumbConstant(_ constant: CGFloat) {
        touchableThumbConstraint.constant = constant
        thumbConstraint.constant = constant
    }

    func adjustForInitialDisplay() {
        guard !adjustedForInitialDisplay else {
            return
        }
        adjustedForInitialDisplay = true
        thumbViewLabel.isHidden = true
        moveThumbToPercent(percent: 0.5)
    }

    func moveThumbToPercent(percent: CGFloat, finished: (() -> Void)? = nil) {
        let value = CGFloat(numberOfTicks) * percent

        let stepDuration: TimeInterval = 0.05

        // Get starting step number and ending step number
        let startingWholeNumber = Int(lastWholeNumber)
        lastWholeNumber = floor(value)

        // Calculate total duration based upon number of steps
        let numberOfSteps = abs(Int(lastWholeNumber) - startingWholeNumber)
        let duration = Double(numberOfSteps) * stepDuration

        self.layoutIfNeeded()
        UIView.animate(withDuration: duration, animations: { [unowned self] in
            self.setThumbConstant(self.trackView.frame.width * percent)
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: { (_) in
            finished?()
        })

        // Determine if  stepping up or down in the stride
        let isSteppingUp = startingWholeNumber < Int(self.lastWholeNumber)
        let steppingValue = isSteppingUp ? 1 : -1

        // Calculate time per tick step
        // Schedule tick background changes as the thumb animates over
        for i in stride(from: startingWholeNumber, through: Int(lastWholeNumber), by: steppingValue) {
            // Increment deplay based upon number of steps animated
            let stepNumber = abs(i - startingWholeNumber)
            let dealyOffset = isSteppingUp ? 0 : -1
            let delay: Double = Double(stepNumber + dealyOffset) * Double(stepDuration)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [unowned self] in
                let color: UIColor
                if isSteppingUp {
                    color = self.theme.slider.trackActiveColor.color
                } else {
                    color = self.theme.slider.trackInactiveColor.color
                }

                self.tickViews[i]?.backgroundColor = color
            }
        }

        thumbViewLabel.text = formatNumber(number: lastWholeNumber)
    }

    func adjustForFullScreen() {
        labelRow.isHidden = true

        NSLayoutConstraint.activate([
            labelRow.heightAnchor.constraint(equalToConstant: 0)
            ])

        snapToNearest()
    }

    private func setupView() {
        makeTicks()

        self.addSubview(trackView)
        self.addSubview(filledTrackView)
        self.addSubview(touchableTrackView)
        self.addSubview(touchableThumbView)
        self.addSubview(thumbView)
        self.addSubview(thumbViewLabel)
        self.addSubview(hoverView)
        self.addSubview(labelRow)
        labelRow.addSubview(lowerLabel)
        labelRow.addSubview(higherLabel)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        touchableThumbView.isUserInteractionEnabled = true
        touchableThumbView.addGestureRecognizer(panGesture)

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            trackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            trackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5),
            trackView.heightAnchor.constraint(equalToConstant: 2),

            filledTrackView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
            filledTrackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            filledTrackView.heightAnchor.constraint(equalTo: trackView.heightAnchor),

            touchableTrackView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            touchableTrackView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor),
            touchableTrackView.heightAnchor.constraint(equalToConstant: 30),

            touchableThumbView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
            touchableThumbView.widthAnchor.constraint(equalToConstant: 70),
            touchableThumbView.widthAnchor.constraint(equalTo: touchableThumbView.heightAnchor),

            thumbView.centerXAnchor.constraint(equalTo: touchableThumbView.centerXAnchor),
            thumbView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor),
            thumbViewDiameterConstraint,
            thumbView.widthAnchor.constraint(equalTo: thumbView.heightAnchor),

            thumbViewLabel.centerXAnchor.constraint(equalTo: touchableThumbView.centerXAnchor),
            thumbViewLabel.centerYAnchor.constraint(equalTo: touchableThumbView.centerYAnchor),

            hoverView.bottomAnchor.constraint(equalTo: trackView.topAnchor, constant: (thumbSelectedSize / -2) - 5),
            hoverView.heightAnchor.constraint(equalToConstant: 40),
            hoverView.widthAnchor.constraint(equalToConstant: 40),

            labelRow.topAnchor.constraint(equalTo: trackView.bottomAnchor, constant: 40),
            labelRow.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            labelRow.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            labelRow.trailingAnchor.constraint(equalTo: trackView.trailingAnchor),

            lowerLabel.topAnchor.constraint(equalTo: labelRow.topAnchor),
            lowerLabel.leadingAnchor.constraint(equalTo: labelRow.leadingAnchor),
            lowerLabel.trailingAnchor.constraint(equalTo: labelRow.centerXAnchor, constant: -8),
            lowerLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelRow.bottomAnchor),

            higherLabel.topAnchor.constraint(equalTo: labelRow.topAnchor),
            higherLabel.leadingAnchor.constraint(equalTo: labelRow.centerXAnchor, constant: 8),
            higherLabel.trailingAnchor.constraint(equalTo: labelRow.trailingAnchor),
            higherLabel.bottomAnchor.constraint(lessThanOrEqualTo: labelRow.bottomAnchor)
            ])

        thumbConstraint.isActive = true
        touchableThumbConstraint.isActive = true
        hoverConstraint.isActive = true
        filledTrackViewConstraint.isActive = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch touches.first?.view {
        case touchableThumbView:
            handlePanBegin()
        case touchableTrackView:
            guard let location = touches.first?.location(in: touchableTrackView) else {
                return
            }

            handleTouchBegin()

            let percent = location.x / touchableTrackView.frame.width
            let tick = percent * CGFloat(numberOfTicks)
            let nearestTick = round(tick)
            let nearestPercent = nearestTick / CGFloat(numberOfTicks)

            moveThumbToPercent(percent: nearestPercent) { [weak self] in
                self?.handleTouchEnd()
            }
        default:
            ()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch touches.first?.view {
        case touchableThumbView:
            if !panGestureStarted {
                handleTouchEnd()
            }
        case touchableTrackView:
            // handleTouchEnd() is called after the moveThumbToPercent() is done in the callback
            ()
        default:
            ()
        }

        guard touches.first?.view == touchableThumbView else {
            return
        }

        if !panGestureStarted {
            handleTouchEnd()
        }
    }

    @objc func draggedView(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            panGestureStarted = true
            startingConstant = self.touchableThumbConstraint.constant
            thumbViewLabel.isHidden = true
        case .changed:
            // Make sure we stay within the bounds of the track
            let translation = recognizer.translation(in: trackView)
            var constant = startingConstant + translation.x
            if constant < 0 {
                constant = 0
            } else if constant > trackView.frame.width {
                constant = trackView.frame.width
            }
            self.setThumbConstant(constant)

            // Get percentage of
            let percent = touchableThumbConstraint.constant / trackView.frame.width
            let value = determineValue(percent: percent)
            let wholeNumber = determineWholeNumber(percent: percent)

            // Update label and haptic feedback if value changed
            // Label and value changes are calculated using rounding
            if wholeNumber != lastWholeNumber {
                hoverView.text = formatNumber(number: wholeNumber)
                Haptic.medium.generate()
            }

            // Update ticks are calculated using floor
            if floor(value) != floor(lastValue) {
                updateTicks(newValue: Int(floor(value)))
            }

            // Save for later use in subsequent changes
            lastPercent = percent
            lastValue = value
            lastWholeNumber = wholeNumber
        case .ended:
            handleTouchEnd()
            snapToNearest()
        default:
            break
        }
    }

}

extension NPSComponent {
    func updateThumbDiameter(size: CGFloat, hideLabel: Bool, completion: (() -> Void)? = nil) {
        self.layoutIfNeeded()

        // Animates size and radius changes
        UIView.animate(withDuration: 0.1, animations: { [unowned self] in
            self.thumbViewDiameterConstraint.constant = size
            self.thumbView.layer.cornerRadius = size / 2

            self.setNeedsLayout()
            self.layoutIfNeeded()
        }, completion: { [unowned self] finished in
            self.thumbViewLabel.isHidden = hideLabel
            if finished {
                completion?()
            }
        })
    }

    func handleTouchBegin() {
        // Adjusting thumb constant to where thumb was snapped to
        let constant = (lastWholeNumber / CGFloat(numberOfTicks)) * trackView.frame.width
        self.setThumbConstant(constant)

        // Disabling snap constant so we can drag
        disableSnaps()

        // Click when touching
        Haptic.medium.generate()

        // Remove animations (if there are any)
        thumbView.layer.removeAllAnimations()
    }

    func handlePanBegin() {
        // Touch happens before pan
        // Resetting to false here
        panGestureStarted = false

        handleTouchBegin()

        // Remove text from thumb and show hover
        hoverView.text = formatNumber(number: lastWholeNumber)
        hoverView.isHidden = false

        updateThumbDiameter(size: thumbSelectedSize, hideLabel: true)
    }

    func handleTouchEnd() {
        let text = formatNumber(number: lastWholeNumber)
        hoverView.text = text
        hoverView.isHidden = true

        thumbViewLabel.text = text

        // Set value on thumb text and call selection callback after thumb shrinks
        updateThumbDiameter(size: thumbNormalSize, hideLabel: false) { [unowned self] in
            let value = Int(self.lastWholeNumber) + self.minNumber
            self.onSelection(value)
        }

        Haptic.medium.generate()
    }

    func snapToNearest() {
        // Snapping to nearest tick via a high priority constraint
        // This is needed from when we transition from a non-full width modal
        // to a full width screen. Without this high priority snap, the thumb view
        // will animate to an incorrect value
        let value = Int(floor(lastWholeNumber))
        if value <= tickViews.count {
            for constraint in (tickViewSnapConstraints[value] ?? []) {
                constraint.isActive = true
            }
        }
    }

    func disableSnaps() {
        // Loop through all snap constraints and disable
        for (_, constraints) in tickViewSnapConstraints {
            for constraint in constraints {
                constraint.isActive = false
            }
        }
    }

    func updateTicks(newValue: Int) {
        for (val, view) in tickViews {
            view.backgroundColor = val <= newValue ? theme.slider.trackActiveColor.color : theme.slider.trackInactiveColor.color
        }
    }

    func determineValue(percent: CGFloat) -> CGFloat {
        return percent * CGFloat(numberOfTicks)
    }

    func determineWholeNumber(percent: CGFloat) -> CGFloat {
        return round(percent * CGFloat(numberOfTicks))
    }

    func formatNumber(number: CGFloat) -> String {
        return "\(Int(number) + minNumber)"
    }
}

private extension NPSComponent {
    func makeTicks() {
        // Place first tick on anchored on left
        let firstTick = makeTick()
        firstTick.backgroundColor = theme.slider.trackActiveColor.color
        NSLayoutConstraint(item: firstTick, attribute: .centerX, relatedBy: .equal, toItem: trackView, attribute: .left, multiplier: 1, constant: 0).isActive = true

        // Place all other ticks anchored on right with multiplier to space evenly
        for i in 1...numberOfTicks {
            let tick = makeTick()
            let multiplier = CGFloat(i) / CGFloat(numberOfTicks)
            NSLayoutConstraint(item: tick, attribute: .centerX, relatedBy: .equal, toItem: trackView, attribute: .right, multiplier: multiplier, constant: 0).isActive = true

            tickViews[i] = tick

            // Generate tick constraints to snap to after pan end
            let touchableConstraint = NSLayoutConstraint(item: touchableThumbView, attribute: .centerX, relatedBy: .equal, toItem: tick, attribute: .centerX, multiplier: 1, constant: 0)
            touchableConstraint.priority = UILayoutPriority.defaultHigh
            touchableConstraint.isActive = false

            let constraint = NSLayoutConstraint(item: thumbView, attribute: .centerX, relatedBy: .equal, toItem: tick, attribute: .centerX, multiplier: 1, constant: 0)
            constraint.priority = UILayoutPriority.defaultHigh
            constraint.isActive = false

            tickViewSnapConstraints[i] = [touchableConstraint, constraint]
        }
    }

    func makeTick() -> UIView {
        let tickView = UIView()
        tickView.backgroundColor = theme.slider.trackInactiveColor.color
        tickView.translatesAutoresizingMaskIntoConstraints = false
        tickView.layer.cornerRadius = 3
        tickView.width(constant: 6)
        tickView.height(constant: 6)

        trackView.addSubview(tickView)
        NSLayoutConstraint(item: tickView, attribute: .centerY, relatedBy: .equal, toItem: trackView, attribute: .centerY, multiplier: 1, constant: 0).isActive = true

        return tickView
    }
}
