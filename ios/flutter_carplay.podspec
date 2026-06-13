#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_carplay.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_carplay'
  s.version          = '1.1.0'
  s.summary          = 'Flutter Apps are now on Apple CarPlay.'
  s.description      = <<-DESC
Flutter Apps are now on Apple CarPlay. This package aims to make it safe to use iPhone apps made with Flutter in the car by integrating with CarPlay.
                       DESC
  s.homepage         = 'https://github.com/oguzhnatly/flutter_carplay'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Oğuzhan Atalay' => 'info@oguzhanatalay.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'flutter_carplay/Sources/flutter_carplay/**/*.swift',
                        'flutter_carplay/Sources/flutter_carplay/**/*.m',
                        'flutter_carplay/Sources/flutter_carplay/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
