Pod::Spec.new do |s|

 s.name             = "ADManager"
 s.version           = "0.0.1"
 s.summary         = "ADManager for Ads Factory"
 s.homepage        = "https://github.com/my1325/GeSwift.git"
 s.license            = "MIT"
 s.platform          = :ios, "10.0"
 s.authors           = { "mayong" => "1173962595@qq.com" }
 s.source             = { :git => "https://github.com/my1325/ADManager.git", :tag => "#{s.version}" }
 s.swift_version = '5.1'
 s.source_files = 'Source/**/*.{swift}'
end