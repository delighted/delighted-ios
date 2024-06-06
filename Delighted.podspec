# coding: utf-8

Pod::Spec.new do |spec|
  spec.name                  = "Delighted"
  spec.version               = "1.4.1"
  spec.summary               = "Build native mobile app surveys for iOS using the Delighted SDK."
  spec.description           = "Build your feedback program directly into your iOS apps using Delighted’s iOS SDK. Delighted’s seamless, user-focused survey experience, reimagined for iPhone."
  spec.homepage              = "https://github.com/delighted/delighted-ios"
  spec.author                = { "Delighted" => "hello@delighted.com" }
  spec.license               = { file: "LICENSE" }
  spec.ios.deployment_target = "15.0"
  spec.source                = { git: "https://github.com/delighted/delighted-ios.git", tag: "#{spec.version}" }
  spec.module_name           = "Delighted"
  spec.swift_version         = "5.0"
  spec.ios.source_files      = "Sources/Delighted/Classes/*.swift"
  spec.resource_bundles      = { "Delighted_Delighted" => ["Sources/Delighted/Assets/*.xcassets"] }

  spec.dependency "Starscream", "~> 4.0" # Support for Swift 5
end
