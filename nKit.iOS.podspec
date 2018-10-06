
Pod::Spec.new do |s|

  s.name         = "nKit.iOS"
  s.version      = "0.0.1"
  s.summary      = "Toolkit for quick building iOS apps"
  s.homepage     = "https://github.com/vbenkevich/ios_swift_utils"

  s.license      = "MIT"
  s.author       = { "Vladimir Benkevich" => "vladimir.benkevich@gmail.com" }

  s.platform     = :ios, "10.0"
  s.swift_version = "4.0"

  s.source       =  { :git => "https://github.com/vbenkevich/ios_swift_utils.git", branch: "develop" }
  s.source_files  = "src/Utils/Utils/**/*.swift"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #
  # s.frameworks = "SomeFramework", "AnotherFramework"

end
