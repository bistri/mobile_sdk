Pod::Spec.new do |s|
  s.name         = "bistriSDK"
  s.version      = "2.0.6"
  s.summary      = "Bistri SDK"
  s.homepage     = "https://developers.bistri.com"
  s.author       = "Bistri"
  s.description  = "Bistri software development kits (SDKs) for building video/audio call functionality in iOS applications."
  s.description  = <<-DESC
Bistri software development kits (SDKs) for building video/audio call functionality in iOS applications.
DESC
  s.source       = { :http => "https://github.com/bistri/mobile_sdk/raw/master/ios/releases/bistriAPI2.framework-#{s.version}.zip" }
  s.vendored_frameworks = 'api2.framework'
  s.dependency 'SocketRocket', '~> 7.2'
  s.dependency 'JSONValueRX', '~> 0.6'
  s.dependency 'WebRTC-lib', '~> 106.0'
end
