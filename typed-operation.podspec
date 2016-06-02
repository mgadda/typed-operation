#
#  Be sure to run `pod spec lint typed-operation.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "typed-operation"
  s.version      = "0.0.1"
  s.summary      = "TypedOperation implements type-safe chainable, nestable composition of NSOperations."
  # s.description  = <<-DESC
  #   TypedOperation implements type-safe chainable, nestable composition of NSOperations.
  #                  DESC

  s.homepage     = "https://github.com/mgadda/typed-operation"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author             = { "Matt Gadda" => "mgadda@gmail.com" }
  s.social_media_url   = "http://twitter.com/mgadda"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  # s.platform     = :ios, "5.0"

  #  When using multiple platforms
  s.ios.deployment_target = "8.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "https://github.com/mgadda/typed-operation.git", :tag => s.version.to_s }
  s.source_files  = "Sources"
  s.requires_arc = true
  s.xcconfig = { "OS_OBJECT_USE_OBJC" => 1 }
end
