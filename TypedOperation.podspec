Pod::Spec.new do |s|
  s.name         = "TypedOperation"
  s.version      = "0.0.5"
  s.summary      = "TypedOperation implements type-safe chainable, nestable composition of NSOperations."
  s.homepage     = "https://github.com/mgadda/typed-operation"
  s.license      = { :type => "Apache License Version 2.0", :file => "LICENSE.txt" }
  s.author             = { "Matt Gadda" => "mgadda@gmail.com" }
  s.social_media_url   = "http://twitter.com/mgadda"
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.source       = { :git => "https://github.com/mgadda/typed-operation.git", :tag => s.version.to_s }
  s.source_files  = "Sources"
  s.requires_arc = true
  s.xcconfig = { "OS_OBJECT_USE_OBJC" => 1 }
end
