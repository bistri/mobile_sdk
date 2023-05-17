Pod::Spec.new do |spec|
  spec.name         = "bistriSDK"
  spec.version      = "2.0.6"
  spec.summary      = "Bistri SDK"
  spec.homepage     = "https://developers.bistri.com"
  spec.author       = "Bistri"
  spec.description  = "Bistri software development kits (SDKs) for building video/audio call functionality in iOS applications."
  spec.source       = { :http => "git@github.com:bistri/mobile_sdk/ios/releases/bistri_api2-#{spec.version}.framework.zip" }
  spec.vendored_frameworks = 'api2.framework'
end
