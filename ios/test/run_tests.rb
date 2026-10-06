# Builds a hostless simulator XCTest bundle from the real plugin sources.
# Usage: FLUTTER_ROOT=/path/to/flutter ruby ios/test/run_tests.rb OUTPUT_DIR DEVICE_ID
require 'xcodeproj'
require 'fileutils'
root = File.expand_path('../..', __dir__)
out = File.expand_path(ARGV.fetch(0))
device = ARGV.fetch(1)
flutter = File.join(ENV.fetch('FLUTTER_ROOT'), 'bin/cache/artifacts/engine/ios/Flutter.xcframework/ios-arm64_x86_64-simulator')
FileUtils.mkdir_p(out)
project = Xcodeproj::Project.new(File.join(out, 'GridTests.xcodeproj'))
target = project.new_target(:unit_test_bundle, 'GridTests', :ios, '14.0')
Dir.glob(File.join(root, 'ios/flutter_carplay/Sources/flutter_carplay/**/*.swift')).each do |file|
  target.source_build_phase.add_file_reference(project.main_group.new_file(file))
end
(Dir.glob(File.join(__dir__, '*Tests.swift')) +
 Dir.glob(File.join(root, 'ios/flutter_carplay/Tests/*Tests.swift'))).each do |file|
  target.source_build_phase.add_file_reference(project.main_group.new_file(file))
end
target.frameworks_build_phase.add_file_reference(project.main_group.new_file(File.join(flutter, 'Flutter.framework')))
target.build_configurations.each do |config|
  config.build_settings.merge!({
    'SWIFT_VERSION' => '5.0', 'GENERATE_INFOPLIST_FILE' => 'YES',
    'PRODUCT_BUNDLE_IDENTIFIER' => 'org.example.GridTests', 'CODE_SIGNING_ALLOWED' => 'NO',
    'FRAMEWORK_SEARCH_PATHS' => ['$(inherited)', flutter],
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', flutter, '@executable_path/Frameworks', '@loader_path/Frameworks']
  })
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.add_test_target(target)
scheme.save_as(project.path, 'GridTests')
exec('xcodebuild', '-project', project.path.to_s, '-scheme', 'GridTests', '-destination', "platform=iOS Simulator,id=#{device}", '-derivedDataPath', File.join(out, 'DerivedData'), 'test')
