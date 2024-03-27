# Delighted iOS SDK

The [Delighted](https://delighted.com) iOS SDK makes it quick and easy to gather
customer feedback directly in your iOS app. 

## Requirements

The Delighted iOS SDK requires Xcode 10.2 or later and is compatible with apps
targeting iOS 12.1 or above. Please note that the SDK is designed for iPhone’s
portrait mode. Support for other iOS devices, notably iPad, is not available at
this time.

### Swift versions

* Swift 4
* Swift 4.2
* Swift 5

### Dependencies

The SDK has a dependency on
[Starscream](https://github.com/daltoniam/Starscream) for WebSocket support.

## Installation

We recommend installing the Delighted iOS SDK using a package manager such as
[CocoaPods](https://cocoapods.org),
[Carthage](https://github.com/Carthage/Carthage), or [Swift Package
Manager](https://www.swift.org/package-manager/).

### CocoaPods

To use Delighted in your project add the following `Podfile` to your project.

``` ruby
source "https://github.com/CocoaPods/Specs.git"
platform :ios, "12.1"
use_frameworks!

pod "Delighted", "~> 1.4.0"
```

Then run:

``` bash
pod install
```

### Carthage

Check out the [Carthage](https://github.com/Carthage/Carthage) docs on how to
add an install. The `Delighted` framework is already setup with shared schemes.

To integrate Delighted into your Xcode project using Carthage, specify it in
your `Cartfile`:

```
github "delighted/delighted-ios" >= 1.4.0
```

### Swift Package Manager

[Add a package
dependency](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app)
to your XCode project using the URL of this repository
(`https://github.com/delighted/delighted-ios`).

## Getting started

Initialize the SDK when your application is activated by a user. Once the SDK
has been initialized you can call `survey(...)` anywhere you want to present a
survey. 

Before showing a survey we’ll confirm that the Mobile SDK platform is enabled
for your project and check that the person hasn’t been recently surveyed, among
other things. We also automatically manage your survey’s sampling to ensure you
receive a steady flow of feedback, as opposed to going through your entire plan
volume in one day. Consequently, a call to `survey(...)` will not always result
in showing a survey.

### Swift

Add the initialization code in the `applicationDidBecomeActive(_:)` method of
your `AppDelegate`.

```swift
import UIKit
import Delighted

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    return true
  }
    
  func applicationDidBecomeActive(_ application: UIApplication) {
    Delighted.initializeSDK()
  }
}
```

Call `Delighted.survey(...)` anywhere you want to show a survey. For example,
to trigger a survey when the view loads, you might do something like this:

```swift
import UIKit
import Delighted

class SomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx")
    }
}
```

### Objective-C

The initialization in Objective-C is similar.

```objective-c
#import "AppDelegate.h"
#import <Delighted/Delighted-Swift.h>

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [Delighted initializeSDK];
}

@end
```

In a view where you want to show the survey, update your view controller
definition in the header file so that it references `DelightedDelegate`.

```objective-c
#import <UIKit/UIKit.h>
#import <Delighted/Delighted-Swift.h>

@interface ViewController : UIViewController<DelightedDelegate>

@end
```

Then update the implementation to call survey and add an implementation of
`onStatusWithError` to handle the callback:

```objective-c
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)Survey:(id)sender {
    Delighted.delegate = self;
    [Delighted surveyWithDelightedID:@"mobile-sdk-xxxxxxxx"
                               token:nil
                              person:nil
                          properties:nil
                             options:nil
                eligibilityOverrides: [[EligibilityOverrides alloc] initWithTestMode:YES createdAt:nil]
                    inViewController:nil];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)onStatusWithError:(NSError * _Nullable)error surveyResponseStatus:(enum DelightedSurveyResponseStatus)surveyResponseStatus {
    NSLog(@"Survey complete");
}

@end
```

### Delighted ID

When your code calls the `survey` function it needs to pass in a `delightedID`.
You can find your Delighted ID at https://delighted.com/integrations/mobile_sdk.
The Delighted ID is considered public and can be treated like any other
configuration setting in your app. 

If you have multiple projects, each project will have its own unique ID. This
allows you to include multiple surveys in your app.

### Examples

The only required parameter is the Delighted ID.

```swift
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx")
```

A survey can also be linked to an individual by passing in a `Person`.

```swift
let person = Person(
    name: "Lauren Ipsum", 
    email: "laurenipsum@example.com", 
    phoneNumber: "+14155551212"
)
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", person: person)
```

Like other Delighted platforms, you can associate properties with a survey
to provide context and segment responses.

``` swift
var properties: Properties = [
    "customerId": "123",
    "location": "USA"
]
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", properties: properties)
```

Delighted [special
properties](https://help.delighted.com/article/285-special-properties-guide-overview) 
can be used to further customize the survey experience. For example, to change 
the survey to appear in German you might use something like this:

```swift
var properties: Properties = [
    "locale": "de"
]
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", properties: properties)
```

In some cases, you may need to override some of the settings that are used to
decide whether to show a survey. The most common one will be to use `testMode`
during development to bypass all checks and force the survey to appear.

```swift
let eligibilityOverrides = EligibilityOverrides(
    testMode: true
)
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", eligibilityOverrides: eligibilityOverrides)
```

The `initialDelay` can be passed to specify the number of seconds to wait before
showing a person their first survey. This is useful in cases where you want a user
to have been using your app at least some amount of time before they would be
eligible to be surveyed. 

```swift
let eligibilityOverrides = EligibilityOverrides(
    initialDelay: 86400
)
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", eligibilityOverrides: eligibilityOverrides)
```

When `Delighted.initialize()` is called for the very first time a
timestamp is stored on the device. The `initialDelay` is based on that value.
If you would like to use a different reference point for the initial delay, you
can set `createdAt`.

The `recurringPeriod` applies when you want to control how frequently to survey
a person.

```swift
let eligibilityOverrides = EligibilityOverrides(
    createdAt: yourUserModel.createdAt,
    initialDelay: 86400,
    recurringPeriod: 1036800
)
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", eligibilityOverrides: eligibilityOverrides)
```

### Handling status and errors

A callback can be passed in those cases where you need to monitor the status of
a survey or trigger an event.

```swift
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", callback: { (status) in
    switch status {
    case let .failedClientEligibility(status):
        // Maybe log this?
        // Do any view/screen changes that you need
    case let .error(status):
        // Maybe log this?
    case let .surveyClosed(status):
        // Re-register for keyboard notifications if unregistered
        // Do any view/screen changes that you need
    }
})
```

### Presentation

The Delighted SDK offers a number of settings to control the survey’s
appearance. 
* The background, border, and text color of every component can be
changed. 
* You can choose whether to prompt the user with a centered modal or a card
  popping up from the bottom of the screen.
* Buttons shapes can be circles, squares, or squares with rounded corners.
* Buttons can also be filled or outlined.
* You can control whether the Thank You page should remain open until a person
  explicitly closes it or to automatically close it after some period (the
  default is to close it after two seconds).
* The iOS keyboard can be set to light mode, dark mode, or it can use the system default.
* The status bar (where the clock and carrier info are displayed) can be hidden or shown.
* The font can be overridden.
* If needed, you can even override text labels. 

The most common settings can be updated by browsing to the Mobile SDK’s [Customize
appearance](https://delighted.com/platforms/preview_mobile_sdk) page.
Please reach out to Delighted’s [Customer Concierge](hello@delighted.com) team
if you would like to change any of the other settings.

Alternatively, you can control the appearance of the survey in your own code.
The values you provide take precedence over your Delighted project’s
configuration. If you opt to describe the settings through code you will need to
provide values for all theme settings. We encourage you to reach out to
Delighted’s [Customer Concierge](hello@delighted.com) team to help you evaluate
the trade-offs and make the best choice for your app.

```swift
let options = Options(
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
    fontFamilyName: "MarkerFelt-Wide",
    thankYouAutoCloseDelay: 10
)

Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", options: options)
```

### Troubleshooting

You can change the log level to print details to the console.

```swift
Delighted.logLevel = .debug
```

The callback can also be used to get more information and explore behavior.

```swift
Delighted.survey(delightedID: "mobile-sdk-xxxxxxxxx", callback: { (status) in
  switch status {
  case let .failedClientEligibility(status):
    print("Eligibility check failed")     
  case let .error(status):
    print("An error occurred")     
  case let .surveyClosed(status):
    print("Survey closed")     
  }
})
```

## Billing

Like Delighted’s web platform, the SDK bases usage on the number of people shown
your survey. When your account exceeds its plan limits the survey won’t appear
in your iOS app until the next billing period or you switch to a plan with a higher
limit.

## Support

Please contact the [Delighted Concierge](mailto:hello@delighted.com?subject=Question%20about%20Delighted%27s%20iOS%20SDK)
team with any questions or to report an issue.

## Example App

The Example App included in the SDK shows examples of each type of survey as
well as some common use cases. This is a fully working app using Delighted’s
[Demo](https://demo.delighted.com) for the source of questions.

### Setup instructions

1. Clone/fork this repository
1. Install Fastlane and CocoaPods with `bundle install`
1. Run `cd Example` and then `pod install`
1. Open `Example/delighted.xcworkspace` in Xcode

After building, fire up the iOS Simulator.

### Tests

The tests are located in the Example app. They can be run by either:

1. Running `fastlane ios test`
1. Opening `Example/delighted.xcworkspace` and running the tests
