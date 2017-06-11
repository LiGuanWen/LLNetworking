#
#  Be sure to run `pod spec lint LLNetworking.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "LLNetworking"
  s.version      = "1.0.0"
  s.summary      = "use for LLNetworking module."
  s.description  = <<-DESC
		   use for LLNetworking module.
		   It’s awesome!!
                   DESC

  s.homepage     = "https://github.com/LiGuanWen/LLNetworking"
  s.license      = "MIT"
  s.author       = { "diqidaimu" => "diqidaimu@qq.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/LiGuanWen/LLNetworking.git", :branch => "#{s.version}" }
  s.source_files  = "LLNetworking/**/*.{h,m,mm,a}"
  s.resources = "LLNetworking/**/*.xib"
  # s.prefix_header_file = 'LLNetworking/LLNetworkingPrefixHeader.pch'    #PCH文件
  s.dependency 'YTKNetwork'

end
