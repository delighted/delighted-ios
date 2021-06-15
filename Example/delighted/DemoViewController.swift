import UIKit
import Delighted

class DemoViewController: UIViewController {
    var example: Example?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let delightedID = example!.delightedID
        let person = example!.person
        let properties = example!.properties
        let options = example!.options
        let eligibilityOverrides = EligibilityOverrides(
            testMode: true,
            createdAt: nil,
            initialDelay: nil,
            recurringPeriod: nil
        )

        Delighted.survey(delightedID: delightedID, person: person, properties: properties, options: options, eligibilityOverrides: eligibilityOverrides, inViewController: nil, callback: { [unowned self] (status) in

            switch status {
            case let .failedClientEligibility(error):
                print("failedClientEligibility: \(error)")
            case let .error(error):
                print("error: \(error)")
            case let .surveyClosed(status):
                print("surveyClosed - \(status)")
            }
            self.performSegue(withIdentifier: "unwindToExamples", sender: self)
        })
    }

    func setExample(example: Example) {
        print("Showing example of \(example.label)")
        self.example = example
    }
}
