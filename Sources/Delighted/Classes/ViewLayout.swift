import UIKit

struct KeyboardHeightHistory {
    static var lastHeight: CGFloat?
}

struct ViewLayout {
    static func createCenterVerticalStackView(subviews: [UIView], spacing: CGFloat = 10) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }

    static func createCenterHorizontalStackView(subviews: [UIView], alignment: UIStackView.Alignment = .center, distribution: UIStackView.Distribution = .fillEqually, spacing: CGFloat = 5) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.axis = .horizontal
        stackView.distribution = distribution
        stackView.alignment = alignment
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }
}

extension UIView {
    func pintToEdges(view: UIView, edges: UIEdgeInsets?) {
        NSLayoutConstraint.activate([
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(edges?.right ?? 0)),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: edges?.left ?? 0),
            self.topAnchor.constraint(equalTo: view.topAnchor, constant: edges?.top ?? 0),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(edges?.bottom ?? 0))
        ])
    }
}

extension UIView {
    func height(constant: CGFloat) {
        let constraint = NSLayoutConstraint(item: self,
                           attribute: .height,
                           relatedBy: NSLayoutConstraint.Relation.equal,
                           toItem: nil,
                           attribute: .notAnAttribute,
                           multiplier: 1,
                           constant: constant)
        setConstraint(constraint: constraint)
    }

    func width(constant: CGFloat) {
        let constraint = NSLayoutConstraint(item: self,
                                            attribute: .width,
                                            relatedBy: NSLayoutConstraint.Relation.equal,
                                            toItem: nil,
                                            attribute: .notAnAttribute,
                                            multiplier: 1,
                                            constant: constant)
        constraint.priority = .defaultHigh
        setConstraint(constraint: constraint)
    }

    func heightEqualWidth() {
        let constraint = NSLayoutConstraint(item: self,
                                            attribute: .height,
                                            relatedBy: NSLayoutConstraint.Relation.equal,
                                            toItem: self,
                                            attribute: .width,
                                            multiplier: 1,
                                            constant: 0)
        constraint.priority = .defaultHigh
        setConstraint(constraint: constraint)
    }

    private func removeConstraint(attribute: NSLayoutConstraint.Attribute) {
        constraints.forEach {
            if $0.firstAttribute == attribute {
                removeConstraint($0)
            }
        }
    }

    private func setConstraint(constraint: NSLayoutConstraint) {
        removeConstraint(attribute: constraint.firstAttribute)
        self.addConstraint(constraint)
    }
}
