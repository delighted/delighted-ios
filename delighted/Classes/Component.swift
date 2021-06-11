import UIKit

protocol Component where Self: UIView {
    func adjustForInitialDisplay()
    func adjustForFullScreen()
}

extension Component {
    func adjustForInitialDisplay() {

    }

    func adjustForFullScreen() {

    }
}
