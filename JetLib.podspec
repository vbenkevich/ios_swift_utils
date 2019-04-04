
Pod::Spec.new do |spec|

  spec.name         = "JetLib"
  spec.version      = "0.5.0"
  spec.summary      = "Toolkit for fast development iOS apps"
  spec.homepage     = "https://github.com/vbenkevich/ios_swift_utils"

  spec.license      = "MIT"
  spec.author       = { "Vladimir Benkevich" => "vladimir.benkevich@gmail.com" }

  spec.platform     = :ios, "10.0"
  spec.swift_version = "5.0"

  spec.source       =  { :git => "https://github.com/vbenkevich/ios_swift_utils.git", branch: "develop" }
  
  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #
  # s.frameworks = "SomeFramework", "AnotherFramework"

  spec.subspec 'Core' do |core|
      core.source_files  = "src/JetLib/JetLib/Core/**/*.swift"
  end

  spec.subspec 'Controllers' do |controllers|
    controllers.source_files  = "src/JetLib/JetLib/Controllers/**/*.swift"
    controllers.dependency 'JetLib/UIKitExtensions'
  end

  spec.subspec 'Pincode' do |pincode|
    pincode.source_files  = "src/JetLib/JetLib/Pincode/**/*.swift"
    pincode.dependency 'JetLib/UIKitExtensions'
    pincode.dependency 'JetLib/Core'
  end

  spec.subspec 'Http' do |http|
      http.source_files  = "src/JetLib/JetLib/Http/**/*.swift"
      http.dependency 'JetLib/Core'
  end

  spec.subspec 'UIKitExtensions' do |extensions|
      extensions.source_files  = "src/JetLib/JetLib/UIKitExtensions/**/*.swift"
  end
end
