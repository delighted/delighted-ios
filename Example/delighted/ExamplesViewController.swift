import UIKit
import Delighted

struct Example {
    let label: String
    let delightedID: String
    var person: Person?
    var properties: Properties?
    var options: Options?
}

enum Section: Int {
    case surveyTypes = 0, additionalScales, other

    var title: String {
        switch self {
        case .surveyTypes:
            return "Survey Types"
        case .additionalScales:
            return "Additional Scales"
        case .other:
            return "Other"
        }
    }
}

class ExamplesViewController: UITableViewController {
    @IBAction func unwindToExamples(segue: UIStoryboardSegue) { }

    @IBOutlet var examplesTableView: UITableView!

    public var selectedExample: Example?

    let examples: [Section: [Example]] = [
        .surveyTypes: [
            Example(
                label: "NPS",
                delightedID: "mobile-sdk-MZI7JiItaVEhcDOz"
            ),
            Example(
                label: "CSAT",
                delightedID: "mobile-sdk-on3ADzMqczZP2V2O"
            ),
            Example(
                label: "CES",
                delightedID: "mobile-sdk-knM3lJ5zGBEraZG8"
            ),
            Example(
                label: "5-star",
                delightedID: "mobile-sdk-KOXlnq0hBwViN9Nu"
            ),
            Example(
                label: "PMF",
                delightedID: "mobile-sdk-Tk5WTarzkYd5uCTG"
            ),
            Example(
                label: "Smileys",
                delightedID: "mobile-sdk-WFdiU1PF6b3AuMB4"
            ),
            Example(
                label: "Thumbs",
                delightedID: "mobile-sdk-bdN0fT9GZpXsMqxI"
            ),
            Example(
                label: "eNPS",
                delightedID: "mobile-sdk-cJmG8vTg0CDPazwF"
            )
        ],
        .additionalScales: [
            Example(
                label: "CSAT (3-point scale)",
                delightedID: "mobile-sdk-LCTlXgXo7XAoIKog"
            ),
            Example(
                label: "CES (5-point scale)",
                delightedID: "mobile-sdk-lLP3R1ZrvjLVTBEL"
            )
        ],
        .other: [
            Example(
                label: "Using a custom font",
                delightedID: "mobile-sdk-MZI7JiItaVEhcDOz",
                options: Options(
                    fontFamilyName: "Georgia"
                )
            ),
            Example(label: "Local theme",
                    delightedID: "mobile-sdk-MZI7JiItaVEhcDOz",
                    options: Options(
                        nextText: "Next 👉",
                        prevText: "👈 Previous",
                        selectOneText: "Select one",
                        selectManyText: "Select many",
                        submitText: "Submit 👌",
                        doneText: "Done ✅",
                        notLikelyText: "Not likely",
                        veryLikelyText: "Very likely",
                        theme: Theme(
                            display: .card,
                            containerCornerRadius: 20.0,
                            primaryColor: LocalThemeColors.primaryColor,
                            buttonStyle: .outline,
                            buttonShape: .roundRect,
                            backgroundColor: LocalThemeColors.grayDarkest,
                            primaryTextColor: LocalThemeColors.white,
                            secondaryTextColor: LocalThemeColors.white,
                            textarea: Theme.TextArea(
                                backgroundColor: LocalThemeColors.grayDark,
                                textColor: LocalThemeColors.white,
                                borderColor: LocalThemeColors.grayDark),
                            primaryButton: Theme.PrimaryButton(
                                backgroundColor: LocalThemeColors.primaryColor,
                                textColor: LocalThemeColors.grayDarkest,
                                borderColor: LocalThemeColors.primaryColor),
                            secondaryButton: Theme.SecondaryButton(
                                backgroundColor: LocalThemeColors.grayDarkest,
                                textColor: LocalThemeColors.primaryColor,
                                borderColor: LocalThemeColors.primaryColor),
                            button: Theme.Button(
                                activeBackgroundColor: LocalThemeColors.primaryColor,
                                activeTextColor: LocalThemeColors.grayDarkest,
                                activeBorderColor: LocalThemeColors.primaryColor,
                                inactiveBackgroundColor: LocalThemeColors.grayDarkest,
                                inactiveTextColor: LocalThemeColors.primaryColor,
                                inactiveBorderColor: LocalThemeColors.primaryColor),
                            stars: Theme.Stars(
                                activeBackgroundColor: LocalThemeColors.primaryColor,
                                inactiveBackgroundColor: LocalThemeColors.gray),
                            icon: Theme.Icon(
                                activeBackgroundColor: LocalThemeColors.primaryColor,
                                inactiveBackgroundColor: LocalThemeColors.gray),
                            scale: Theme.Scale(
                                activeBackgroundColor: LocalThemeColors.primaryColor,
                                activeTextColor: LocalThemeColors.grayDarkest,
                                activeBorderColor: LocalThemeColors.primaryColor,
                                inactiveBackgroundColor: LocalThemeColors.grayDarkest,
                                inactiveTextColor: LocalThemeColors.primaryColor,
                                inactiveBorderColor: LocalThemeColors.primaryColor),
                            slider: Theme.Slider(
                                knobBackgroundColor: LocalThemeColors.primaryColor,
                                knobTextColor: LocalThemeColors.white,
                                knobBorderColor: LocalThemeColors.primaryColor,
                                trackActiveColor: LocalThemeColors.primaryColor,
                                trackInactiveColor: LocalThemeColors.white,
                                hoverBackgroundColor: LocalThemeColors.grayDarkest,
                                hoverTextColor: LocalThemeColors.primaryColor,
                                hoverBorderColor: LocalThemeColors.primaryColor),
                            closeButton: Theme.CloseButton(
                                normalBackgroundColor: LocalThemeColors.gray,
                                normalTextColor: LocalThemeColors.grayDark,
                                normalBorderColor: LocalThemeColors.gray,
                                highlightedBackgroundColor: LocalThemeColors.gray,
                                highlightedTextColor: LocalThemeColors.grayDarker,
                                highlightedBorderColor: LocalThemeColors.gray),
                            ios: Theme.IOS(keyboardAppearance: .dark,
                                statusBarMode: .lightContent,
                                statusBarHidden: false)
                        ),
                        thankYouAutoCloseDelay: 10
                )
            )
        ]
    ]

    func getExample(indexPath: IndexPath) -> Example {
        return examples[Section(rawValue: indexPath.section)!]![indexPath.row]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return examples.count
    }

    // Section label
    override func tableView(_ tableView: UITableView, titleForHeaderInSection
                                section: Int) -> String? {
        return Section(rawValue: section)!.title
    }

    // Number of examples in section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples[Section(rawValue: section)!]!.count
    }

    // Given an indexPath (section, row), construct a cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = examplesTableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath)
        cell.textLabel?.text = getExample(indexPath: indexPath).label
        return cell
    }

    // Section header height
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 50 : 30
    }

    // When a cell is touched, trigger the demo
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedExample = getExample(indexPath: indexPath)
        self.performSegue(withIdentifier: "demoSurvey", sender: examplesTableView.cellForRow(at: indexPath))
    }

    // Before transitioning, set the example that'll be demo'd
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "demoSurvey" {
            let demoView = segue.destination as! DemoViewController
            demoView.setExample(example: selectedExample!)
        }
    }
}
