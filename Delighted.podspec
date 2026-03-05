# coding: utf-8

Pod::Spec.new do |spec|
  spec.name                  = "Delighted"
  spec.version               = "1.5.0"
  spec.summary               = "[DEPRECATED] Build native mobile app surveys for iOS using the Delighted SDK."
  spec.description           = "[DEPRECATED] Delighted is being sunset on June 30, 2026. This SDK is deprecated and will no longer be maintained. For more information, visit the Delighted Sunset FAQ: https://help.delighted.com/article/840-delighted-sunset-faq"
  spec.homepage              = "https://github.com/delighted/delighted-ios"
  spec.author                = { "Delighted" => "hello@delighted.com" }
  spec.license               = { file: "LICENSE" }
  spec.ios.deployment_target = "15.0"
  spec.source                = { git: "https://github.com/delighted/delighted-ios.git", tag: "#{spec.version}" }
  spec.module_name           = "Delighted"
  spec.swift_version         = "5.0"
  spec.ios.source_files      = "Sources/Delighted/Classes/*.swift"
  spec.resource_bundles      = { "Delighted_Delighted" => ["Sources/Delighted/Assets/*.xcassets"] }
  spec.deprecated            = true

  spec.dependency "Starscream", "~> 4.0" # Support for Swift 5
end
