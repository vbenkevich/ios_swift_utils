
Pod::Spec.new do |s|

  s.name         = "JetLib"
  s.version      = "0.2.0"
  s.summary      = "Toolkit for fast development iOS apps"
  s.homepage     = "https://github.com/vbenkevich/ios_swift_utils"

  s.license      = "MIT"
  s.author       = { "Vladimir Benkevich" => "vladimir.benkevich@gmail.com" }

  s.platform     = :ios, "10.0"
  s.swift_version = "4.2"

  s.source       =  { path: "." }
  s.source_files  = "JetLib/**/*.swift"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #
  # s.frameworks = "SomeFramework", "AnotherFramework"

end
