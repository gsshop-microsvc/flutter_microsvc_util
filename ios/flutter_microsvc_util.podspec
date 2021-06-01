#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_microsvc_util.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_microsvc_util'
  s.version          = '0.3.1'
  s.summary          = 'microsvc flutter util'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/reactspring/flutter_microsvc_util.git'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TeaHeun Lee' => 'nixstrory@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'FBSDKCoreKit', '~> 9.1.0'
  s.dependency 'FBSDKShareKit'

  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
