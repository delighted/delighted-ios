# coding: utf-8

Pod::Spec.new do |spec|
  spec.name                  = "Delighted"
  spec.version               = "1.3.0"
  spec.summary               = "Delighted uses the Net Promoter System® to gather real feedback from your customers"
  spec.description           = <<~DESC
    Delighted uses the Net Promoter System® to gather real feedback from your customers
  DESC
  spec.homepage              = "https://github.com/delighted/delighted-ios"
  spec.author                = { "Delighted": "hello@delighted.com" }
  spec.license               = { file: "LICENSE" }
  spec.ios.deployment_target = "12.1"
  spec.source                = { git: "https://github.com/delighted/delighted-ios.git", tag: "#{spec.version}" }
  spec.module_name           = "Delighted"
  spec.swift_version         = "5.0"
  spec.ios.source_files      = "delighted/Classes/*.swift"
  spec.resources             = "delighted/Assets/*.xcassets"

  spec.dependency "Starscream", "~> 4.0" # Support for Swift 5
end
