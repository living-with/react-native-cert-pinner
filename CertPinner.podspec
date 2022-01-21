require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "CertPinner"
  s.version      = package["version"]
  s.summary      = "CertPinner"
  s.description  = <<-DESC
                  CertPinner
                   DESC
  s.homepage     = "https://github.com/approov/react-native-cert-pinner"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "author" => "author@domain.cn" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/author/CertPinner.git", :tag => "master" }

  s.source_files = "ios/**/*.{h,m,swift}"
  s.requires_arc = true

  s.dependency "React"
  s.dependency "TrustKit"
  s.dependency "Sentry", "7.9.0"
end
