Pod::Spec.new do |s|
  s.name         = "bistriSDK"
  s.version      = "2.0.6"
  s.summary      = "Bistri SDK"
  s.homepage     = "https://developers.bistri.com"
  s.author       = "Bistri"
  s.description  = "Bistri software development kits (SDKs) for building video/audio call functionality in iOS applications."
  s.source       = { :http => "git@github.com:bistri/mobile_sdk/ios/releases/bistri_api2-#{s.version}.framework.zip" }
  s.vendored_frameworks = 'api2.framework'
end
