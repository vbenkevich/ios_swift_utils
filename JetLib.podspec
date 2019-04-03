
Pod::Spec.new do |spec|

  spec.name         = "JetLib"
  spec.version      = "0.3.0"
  spec.summary      = "Toolkit for fast development iOS apps"
  spec.homepage     = "https://github.com/vbenkevich/ios_swift_utils"

  spec.license      = "MIT"
  spec.author       = { "Vladimir Benkevich" => "vladimir.benkevich@gmail.com"

  spec.platform     = :ios, "10.0"
  spec.swift_version = "4.2"

  spec.source       =  { :git => "https://github.com/vbenkevich/ios_swift_utils.git", branch: "develop" }
  spec.source_files  = "src/JetLib/JetLib/**/*.swift"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #
  # s.frameworks = "SomeFramework", "AnotherFramework"

  spec.subspec 'Views' do |views|
    spec.source_files  = "src/JetUI/JetUI/**/*.swift"
  end

  spec.subspec 'Pincode' do |pincode|
    spec.source_files  = "src/JetPincode/JetPincode/**/*.swift"
  end
end
