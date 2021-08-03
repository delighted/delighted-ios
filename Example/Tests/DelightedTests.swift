import XCTest
@testable import Delighted

final class DelightedTests: XCTestCase {
    func loadJSONData(filename: String) -> Data? {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            XCTFail("Missing file: \(filename).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            XCTFail("Cannot load data: \(filename).json")
            return nil
        }
    }

    func testNPS() {
        let data = loadJSONData(filename: "sample_nps")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "zx5K98i5YcbKqFXirpEnt5N2")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 3)
            XCTAssertEqual(surveyRequest.survey.type.id, .nps)
            let promoter = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "promoter"
            }
            let passive = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "passive"
            }
            let detractor = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "detractor"
            }

            XCTAssertEqual(promoter!.name, "promoter")
            XCTAssertEqual(promoter!.scoreMin, 9)
            XCTAssertEqual(promoter!.scoreMax, 10)

            XCTAssertEqual(passive!.name, "passive")
            XCTAssertEqual(passive!.scoreMin, 7)
            XCTAssertEqual(passive!.scoreMax, 8)

            XCTAssertEqual(detractor!.name, "detractor")
            XCTAssertEqual(detractor!.scoreMin, 0)
            XCTAssertEqual(detractor!.scoreMax, 6)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/mobile_sdk?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Not likely")
            XCTAssertEqual(configuration.veryLikelyText, "Very likely")

            // Pusher
            let pusher = configuration.pusher
            XCTAssertEqual(pusher.webSocketUrl, "wss://example.com/ws")
            XCTAssertEqual(pusher.enabled, false)
            XCTAssertEqual(pusher.channelName, "private-channel")

            // Theme
            let theme = configuration.theme
            XCTAssertNotNil(theme)

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How likely are you to recommend Hem & Stitch NPS to a friend?")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 11)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 6)

            let question1 = additionalQuestions[0]
            XCTAssertEqual(question1.id, "271")
            XCTAssertEqual(question1.type, .selectOne)
            XCTAssertEqual(question1.text, "Have you made a purchase decision based on your experience shopping at Hem & Stitch?")
            XCTAssertNil(question1.scaleMin)
            XCTAssertNil(question1.scaleMax)
            XCTAssertNil(question1.scaleMinLabel)
            XCTAssertNil(question1.scaleMaxLabel)

            let question1Options = question1.options
            XCTAssertEqual(question1Options?.count, 2)
            XCTAssertEqual(question1Options?[0].id, "512")
            XCTAssertEqual(question1Options?[0].text, "Yes")
            XCTAssertEqual(question1Options?[1].id, "513")
            XCTAssertEqual(question1Options?[1].text, "No")

            let question2 = additionalQuestions[1]
            XCTAssertEqual(question2.id, "272")
            XCTAssertEqual(question2.type, .selectMany)
            XCTAssertEqual(question2.text, "Help us help you. What can we do better?")
            XCTAssertNil(question2.scaleMin)
            XCTAssertNil(question2.scaleMax)
            XCTAssertNil(question2.scaleMinLabel)
            XCTAssertNil(question2.scaleMaxLabel)

            let question2Options = question2.options
            XCTAssertEqual(question2Options?.count, 4)

            let question3 = additionalQuestions[2]
            XCTAssertEqual(question3.id, "273")
            XCTAssertEqual(question3.type, .freeResponse)
            XCTAssertEqual(question3.text, "How easy was the shopping experience?")
            XCTAssertNil(question3.scaleMin)
            XCTAssertNil(question3.scaleMax)
            XCTAssertNil(question3.scaleMinLabel)
            XCTAssertNil(question3.scaleMaxLabel)

            let question3Options = question3.options
            XCTAssertNil(question3Options)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 3)
            let thankYouPromoter = surveyRequest.thankYou.groups.first { (group) -> Bool in
                return group.name == "promoter"
            }
            let thankYouPassive = surveyRequest.thankYou.groups.first { (group) -> Bool in
                return group.name == "passive"
            }
            let thankYouDetractor = surveyRequest.thankYou.groups.first { (group) -> Bool in
                return group.name == "detractor"
            }

            XCTAssertEqual(thankYouPromoter!.name, "promoter")
            XCTAssertEqual(thankYouPromoter!.messageText, "PROMOTERS: Please take a moment and share your experience on Yelp.")
            XCTAssertEqual(thankYouPromoter!.linkText, "Review us on Yelp!")
            XCTAssertEqual(thankYouPromoter!.linkURL, "https://yelp.com")

            XCTAssertEqual(thankYouPassive!.name, "passive")
            XCTAssertEqual(thankYouPassive!.messageText, "PASSIVES: Please take a moment and share your experience on Yelp.")
            XCTAssertEqual(thankYouPassive!.linkText, "Review us on Yelp!")
            XCTAssertEqual(thankYouPassive!.linkURL, "https://yelp.com")

            XCTAssertEqual(thankYouDetractor!.name, "detractor")
            XCTAssertEqual(thankYouDetractor!.messageText, "DETRACTORS: Please take a moment and share your experience on Yelp.")
            XCTAssertEqual(thankYouDetractor!.linkText, "Review us on Yelp!")
            XCTAssertEqual(thankYouDetractor!.linkURL, "https://yelp.com")

        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testTheme() {
        let data = loadJSONData(filename: "sample_nps")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)
            let configuration = surveyRequest.survey.configuration

            // Theme
            let theme = configuration.theme
            XCTAssertEqual(theme.primaryColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(theme.buttonStyle, .outline)
            XCTAssertEqual(theme.buttonShape, .circle)
            XCTAssertEqual(theme.display, .card)
            XCTAssertEqual(theme.containerCornerRadius, 20)
            XCTAssertEqual(theme.backgroundColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(theme.primaryTextColor.color, UIColor(hex: "#1D1D1D"))
            XCTAssertEqual(theme.secondaryTextColor.color, UIColor(hex: "#999999"))

            let textArea = theme.textarea
            XCTAssertEqual(textArea.backgroundColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(textArea.textColor.color, UIColor(hex: "#1D1D1D"))
            XCTAssertEqual(textArea.borderColor.color, UIColor(hex: "#999999"))

            let primaryButton = theme.primaryButton
            XCTAssertEqual(primaryButton.backgroundColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(primaryButton.textColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(primaryButton.borderColor.color, UIColor(hex: "#1DA2F1"))

            let secondaryButton = theme.secondaryButton
            XCTAssertEqual(secondaryButton.backgroundColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(secondaryButton.textColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(secondaryButton.borderColor.color, UIColor(hex: "#1DA2F1"))

            let button = theme.button
            XCTAssertEqual(button.activeBackgroundColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(button.activeTextColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(button.activeBorderColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(button.inactiveBackgroundColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(button.inactiveTextColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(button.inactiveBorderColor.color, UIColor(hex: "#1DA2F1"))

            let stars = theme.stars
            XCTAssertEqual(stars.activeBackgroundColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(stars.inactiveBackgroundColor.color, UIColor(hex: "#FFFFFF"))

            let icon = theme.icon
            XCTAssertEqual(icon.activeBackgroundColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(icon.inactiveBackgroundColor.color, UIColor(hex: "#DDDDDD"))

            let scale = theme.scale
            XCTAssertEqual(scale.activeBackgroundColor.color, UIColor(hex: "#00faff"))
            XCTAssertEqual(scale.activeTextColor.color, UIColor(hex: "#000000"))
            XCTAssertEqual(scale.activeBorderColor.color, UIColor(hex: "#47c66d"))
            XCTAssertEqual(scale.inactiveBackgroundColor.color, UIColor(hex: "#ffee00"))
            XCTAssertEqual(scale.inactiveTextColor.color, UIColor(hex: "#000000"))
            XCTAssertEqual(scale.inactiveBorderColor.color, UIColor(hex: "#f21d1d"))

            let slider = theme.slider
            XCTAssertEqual(slider.knobBackgroundColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(slider.knobTextColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(slider.knobBorderColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(slider.trackActiveColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(slider.trackInactiveColor.color, UIColor(hex: "#DDDDDD"))
            XCTAssertEqual(slider.hoverBackgroundColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(slider.hoverTextColor.color, UIColor(hex: "#1DA2F1"))
            XCTAssertEqual(slider.hoverBorderColor.color, UIColor(hex: "#1DA2F1"))

            let closeButton = theme.closeButton
            XCTAssertEqual(closeButton.normalBackgroundColor.color, UIColor(hex: "#1D1D1D"))
            XCTAssertEqual(closeButton.normalTextColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(closeButton.normalBorderColor.color, UIColor(hex: "#1D1D1D"))
            XCTAssertEqual(closeButton.highlightedBackgroundColor.color, UIColor(hex: "#999999"))
            XCTAssertEqual(closeButton.highlightedTextColor.color, UIColor(hex: "#FFFFFF"))
            XCTAssertEqual(closeButton.highlightedBorderColor.color, UIColor(hex: "#999999"))

            let ios = theme.ios
            XCTAssertEqual(ios.keyboardAppearance, nil)
            XCTAssertEqual(ios.statusBarMode, .darkContent)
            XCTAssertEqual(ios.statusBarHidden, false)
        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testFiveStar() {
        let data = loadJSONData(filename: "sample_five_star")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "IvDpINRwBfWxy8vreolJVAdI")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 5)
            XCTAssertEqual(surveyRequest.survey.type.id, .starsFive)
            let star5 = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "star_5"
            }
            let star4 = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "star_4"
            }
            let star3 = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "star_3"
            }
            let star2 = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "star_2"
            }
            let star1 = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "star_1"
            }

            XCTAssertEqual(star5!.name, "star_5")
            XCTAssertEqual(star5!.scoreMin, 5)
            XCTAssertEqual(star5!.scoreMax, 5)

            XCTAssertEqual(star4!.name, "star_4")
            XCTAssertEqual(star4!.scoreMin, 4)
            XCTAssertEqual(star4!.scoreMax, 4)

            XCTAssertEqual(star3!.name, "star_3")
            XCTAssertEqual(star3!.scoreMin, 3)
            XCTAssertEqual(star3!.scoreMax, 3)

            XCTAssertEqual(star2!.name, "star_2")
            XCTAssertEqual(star2!.scoreMin, 2)
            XCTAssertEqual(star2!.scoreMax, 2)

            XCTAssertEqual(star1!.name, "star_1")
            XCTAssertEqual(star1!.scoreMin, 1)
            XCTAssertEqual(star1!.scoreMax, 1)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/mobile_sdk?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "1 star")
            XCTAssertEqual(configuration.veryLikelyText, "5 stars")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How would you rate your experience with Hem & Stitch 5-star?")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 5)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 6)

            let question1 = additionalQuestions[0]
            XCTAssertEqual(question1.id, "199")
            XCTAssertEqual(question1.type, .selectOne)
            XCTAssertEqual(question1.text, "Have you made a purchase decision based on your experience shopping at Hem & Stitch?")
            XCTAssertNil(question1.scaleMin)
            XCTAssertNil(question1.scaleMax)
            XCTAssertNil(question1.scaleMinLabel)
            XCTAssertNil(question1.scaleMaxLabel)

            let question2 = additionalQuestions[1]
            XCTAssertEqual(question2.id, "200")
            XCTAssertEqual(question2.type, .selectMany)
            XCTAssertEqual(question2.text, "Help us help you. What can we do better?")
            XCTAssertNil(question2.scaleMin)
            XCTAssertNil(question2.scaleMax)
            XCTAssertNil(question2.scaleMinLabel)
            XCTAssertNil(question2.scaleMaxLabel)

            let question3 = additionalQuestions[2]
            XCTAssertEqual(question3.id, "201")
            XCTAssertEqual(question3.type, .scale)
            XCTAssertEqual(question3.text, "How easy was the shopping experience?")
            XCTAssertEqual(question3.scaleMin, 0)
            XCTAssertEqual(question3.scaleMax, 10)
            XCTAssertEqual(question3.scaleMinLabel, "Very difficult")
            XCTAssertEqual(question3.scaleMaxLabel, "Very easy")

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)

        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testCSAT() {
        let data = loadJSONData(filename: "sample_csat")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "A5s1Cq1Al339fs1KU46JelCL")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 3)
            XCTAssertEqual(surveyRequest.survey.type.id, .csat)
            let satisfied = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "satisfied"
            }
            let neutral = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "neutral"
            }
            let dissatisfied = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "dissatisfied"
            }

            XCTAssertEqual(satisfied!.name, "satisfied")
            XCTAssertEqual(satisfied!.scoreMin, 4)
            XCTAssertEqual(satisfied!.scoreMax, 5)

            XCTAssertEqual(neutral!.name, "neutral")
            XCTAssertEqual(neutral!.scoreMin, 3)
            XCTAssertEqual(neutral!.scoreMax, 3)

            XCTAssertEqual(dissatisfied!.name, "dissatisfied")
            XCTAssertEqual(dissatisfied!.scoreMin, 1)
            XCTAssertEqual(dissatisfied!.scoreMax, 2)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/mobile_sdk?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Very dissatisfied")
            XCTAssertEqual(configuration.veryLikelyText, "Very satisfied")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How satisfied were you with Hem & Stitch CSAT?")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 5)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 3)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)

        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testCES() {
        let data = loadJSONData(filename: "sample_ces")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "q8PSgeqqIJYlcDx2NBEU9UNe")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 3)
            XCTAssertEqual(surveyRequest.survey.type.id, .ces)
            let agree = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "agree"
            }
            let neutral = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "neutral"
            }
            let disagree = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "disagree"
            }

            XCTAssertEqual(agree!.name, "agree")
            XCTAssertEqual(agree!.scoreMin, 4)
            XCTAssertEqual(agree!.scoreMax, 5)

            XCTAssertEqual(neutral!.name, "neutral")
            XCTAssertEqual(neutral!.scoreMin, 3)
            XCTAssertEqual(neutral!.scoreMax, 3)

            XCTAssertEqual(disagree!.name, "disagree")
            XCTAssertEqual(disagree!.scoreMin, 1)
            XCTAssertEqual(disagree!.scoreMax, 2)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/mobile_sdk?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Strongly disagree")
            XCTAssertEqual(configuration.veryLikelyText, "Strongly agree")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "Hem & Stitch CES made it easy for me to handle my issue.")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 5)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 3)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)

        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testSmileys() {
        let data = loadJSONData(filename: "sample_smileys")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "yGRn3MLbgVAIF6HlMQ37j3tl")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 5)
            XCTAssertEqual(surveyRequest.survey.type.id, .smileys)
            let veryHappy = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "very_happy"
            }
            let happy = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "happy"
            }
            let neutral = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "neutral"
            }
            let unhappy = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "unhappy"
            }
            let veryUnhappy = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "very_unhappy"
            }

            XCTAssertEqual(veryHappy!.name, "very_happy")
            XCTAssertEqual(veryHappy!.scoreMin, 5)
            XCTAssertEqual(veryHappy!.scoreMax, 5)

            XCTAssertEqual(happy!.name, "happy")
            XCTAssertEqual(happy!.scoreMin, 4)
            XCTAssertEqual(happy!.scoreMax, 4)

            XCTAssertEqual(neutral!.name, "neutral")
            XCTAssertEqual(neutral!.scoreMin, 3)
            XCTAssertEqual(neutral!.scoreMax, 3)

            XCTAssertEqual(unhappy!.name, "unhappy")
            XCTAssertEqual(unhappy!.scoreMin, 2)
            XCTAssertEqual(unhappy!.scoreMax, 2)

            XCTAssertEqual(veryUnhappy!.name, "very_unhappy")
            XCTAssertEqual(veryUnhappy!.scoreMin, 1)
            XCTAssertEqual(veryUnhappy!.scoreMax, 1)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/mobile_sdk?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Very unhappy")
            XCTAssertEqual(configuration.veryLikelyText, "Very happy")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How happy were you with Hem & Stitch Smileys?")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 5)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 6)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)

        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testThumbs() {
        let data = loadJSONData(filename: "sample_thumbs")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "vGFlRckNlivGCUeFdmNVoJlB")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 2)
            XCTAssertEqual(surveyRequest.survey.type.id, .thumbs)
            let thumbsUp = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "thumbs_up"
            }
            let thumbsDown = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "thumbs_down"
            }

            XCTAssertEqual(thumbsUp!.name, "thumbs_up")
            XCTAssertEqual(thumbsUp!.scoreMin, 1)
            XCTAssertEqual(thumbsUp!.scoreMax, 1)

            XCTAssertEqual(thumbsDown!.name, "thumbs_down")
            XCTAssertEqual(thumbsDown!.scoreMin, 0)
            XCTAssertEqual(thumbsDown!.scoreMax, 0)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/mobile_sdk?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Thumbs down")
            XCTAssertEqual(configuration.veryLikelyText, "Thumbs up")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How was your experience with Hem & Stitch Thumbs?")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 2)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 0)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)

        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testENPS() {
        let data = loadJSONData(filename: "sample_enps")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "h0H9InsLQO0Rqs3dfW4qoNue")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 3)
            XCTAssertEqual(surveyRequest.survey.type.id, .enps)
            let promoter = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "promoter"
            }
            let passive = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "passive"
            }
            let detractor = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "detractor"
            }

            XCTAssertEqual(promoter!.name, "promoter")
            XCTAssertEqual(promoter!.scoreMin, 9)
            XCTAssertEqual(promoter!.scoreMax, 10)

            XCTAssertEqual(passive!.name, "passive")
            XCTAssertEqual(passive!.scoreMin, 7)
            XCTAssertEqual(passive!.scoreMax, 8)

            XCTAssertEqual(detractor!.name, "detractor")
            XCTAssertEqual(detractor!.scoreMin, 0)
            XCTAssertEqual(detractor!.scoreMax, 6)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Not likely")
            XCTAssertEqual(configuration.veryLikelyText, "Very likely")

            // Pusher
            let pusher = configuration.pusher
            XCTAssertEqual(pusher.webSocketUrl, "wss://example.com/ws")
            XCTAssertEqual(pusher.enabled, false)
            XCTAssertEqual(pusher.channelName, "private-channel")

            // Theme
            let theme = configuration.theme
            XCTAssertNotNil(theme)

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How likely are you to recommend working at Hem & Stitch to a friend or colleague?")
            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 11)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 0)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")
        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testPMF() {
        let data = loadJSONData(filename: "sample_pmf")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "test-144092")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 3)
            XCTAssertEqual(surveyRequest.survey.type.id, .pmf)

            let veryDisappointed = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "very_disappointed"
            }
            let mildlyDisappointed = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "mildly_disappointed"
            }
            let notDisappointed = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "not_disappointed"
            }

            XCTAssertEqual(veryDisappointed!.name, "very_disappointed")
            XCTAssertEqual(veryDisappointed!.scoreMin, 3)
            XCTAssertEqual(veryDisappointed!.scoreMax, 3)

            XCTAssertEqual(mildlyDisappointed!.name, "mildly_disappointed")
            XCTAssertEqual(mildlyDisappointed!.scoreMin, 2)
            XCTAssertEqual(mildlyDisappointed!.scoreMax, 2)

            XCTAssertEqual(notDisappointed!.name, "not_disappointed")
            XCTAssertEqual(notDisappointed!.scoreMin, 1)
            XCTAssertEqual(notDisappointed!.scoreMax, 1)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Not disappointed")
            XCTAssertEqual(configuration.veryLikelyText, "Very disappointed")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How would you feel if you could no longer use Hem & Stitch for iOS?")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 3)

            let scoreText = surveyRequest.survey.template.scoreText
            XCTAssertEqual(scoreText!.count, 3)
            XCTAssertEqual(scoreText!["1"], "Not disappointed")
            XCTAssertEqual(scoreText!["2"], "Mildly disappointed")
            XCTAssertEqual(scoreText!["3"], "Very disappointed")

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 0)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)
        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testCSAT3() {
        let data = loadJSONData(filename: "sample_csat3")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "test-261775")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 3)
            XCTAssertEqual(surveyRequest.survey.type.id, .csat3)

            let satisfied = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "satisfied"
            }
            let neutral = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "neutral"
            }
            let dissatisfied = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "dissatisfied"
            }

            XCTAssertEqual(satisfied!.name, "satisfied")
            XCTAssertEqual(satisfied!.scoreMin, 3)
            XCTAssertEqual(satisfied!.scoreMax, 3)

            XCTAssertEqual(neutral!.name, "neutral")
            XCTAssertEqual(neutral!.scoreMin, 2)
            XCTAssertEqual(neutral!.scoreMax, 2)

            XCTAssertEqual(dissatisfied!.name, "dissatisfied")
            XCTAssertEqual(dissatisfied!.scoreMin, 1)
            XCTAssertEqual(dissatisfied!.scoreMax, 1)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Dissatisfied")
            XCTAssertEqual(configuration.veryLikelyText, "Satisfied")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "How satisfied were you with Hem & Stitch?")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 3)

            let scoreText = surveyRequest.survey.template.scoreText
            XCTAssertEqual(scoreText!.count, 3)
            XCTAssertEqual(scoreText!["1"], "Dissatisfied")
            XCTAssertEqual(scoreText!["2"], "Neither satisfied nor dissatisfied")
            XCTAssertEqual(scoreText!["3"], "Satisfied")

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 0)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)
        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }

    func testCES7() {
        let data = loadJSONData(filename: "sample_ces7")!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let surveyRequest = try decoder.decode(SurveyRequest.self, from: data)

            // Token
            XCTAssertNotNil(surveyRequest)
            XCTAssertNotNil(surveyRequest.token)
            XCTAssertEqual(surveyRequest.token, "test-261777")

            // Survey type
            XCTAssertEqual(surveyRequest.survey.type.groups.count, 3)
            XCTAssertEqual(surveyRequest.survey.type.id, .ces7)
            let agree = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "agree"
            }
            let neutral = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "neutral"
            }
            let disagree = surveyRequest.survey.type.groups.first { (group) -> Bool in
                return group.name == "disagree"
            }

            XCTAssertEqual(agree!.name, "agree")
            XCTAssertEqual(agree!.scoreMin, 5)
            XCTAssertEqual(agree!.scoreMax, 7)

            XCTAssertEqual(neutral!.name, "neutral")
            XCTAssertEqual(neutral!.scoreMin, 4)
            XCTAssertEqual(neutral!.scoreMax, 4)

            XCTAssertEqual(disagree!.name, "disagree")
            XCTAssertEqual(disagree!.scoreMin, 1)
            XCTAssertEqual(disagree!.scoreMax, 3)

            // Survey configuration
            let configuration = surveyRequest.survey.configuration
            XCTAssertEqual(configuration.textBaseDirection, .ltr)
            XCTAssertEqual(configuration.poweredByLinkText, "Powered by Delighted")
            XCTAssertEqual(configuration.poweredByLinkURL, "https://delighted.com/?utm_campaign=mobile_sdk_powered1&utm_content=badge&utm_medium=web&utm_source=delighted_mobile_sdk")
            XCTAssertEqual(configuration.nextText, "Next")
            XCTAssertEqual(configuration.prevText, "Previous")
            XCTAssertEqual(configuration.selectOneText, "Select one option")
            XCTAssertEqual(configuration.selectManyText, "Select one or more options")
            XCTAssertEqual(configuration.submitText, "Submit")
            XCTAssertEqual(configuration.doneText, "Done")
            XCTAssertEqual(configuration.notLikelyText, "Strongly disagree")
            XCTAssertEqual(configuration.veryLikelyText, "Strongly agree")

            // Survey template
            let template = surveyRequest.survey.template
            XCTAssertEqual(template.questionText, "Hem & Stitch made it easy for me to handle my issue.")

            let commentPrompts = surveyRequest.survey.template.commentPrompts
            XCTAssertEqual(commentPrompts.count, 7)

            let additionalQuestions = template.additionalQuestions
            XCTAssertEqual(additionalQuestions.count, 0)

            // Thank you
            let thankYou = surveyRequest.thankYou
            XCTAssertEqual(thankYou.text, "Thanks, we really appreciate your feedback.")

            XCTAssertEqual(surveyRequest.thankYou.groups.count, 0)

        } catch {
            print(error.localizedDescription)
            XCTFail("Failed to create surveyRequest")
        }
    }


    static var allTests = [
        ("testNPS", testNPS),
        ("testFiveStar", testFiveStar),
        ("testCSAT", testCSAT),
        ("testCES", testCES),
        ("testSmileys", testSmileys),
        ("testThumbs", testThumbs),
        ("testENPS", testENPS),
        ("testPMF", testPMF),
        ("testCSAT3", testCSAT3),
        ("testCES7", testCES7)
    ]
}
