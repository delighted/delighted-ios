import UIKit

extension String {
    func setParagraphStyle(lineSpacing: CGFloat, alignment: NSTextAlignment) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.alignment = alignment

        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

        return attributedString
    }
}
