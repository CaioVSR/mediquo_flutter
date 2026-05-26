Pod::Spec.new do |s|
  s.name             = 'mediquo_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin bridging the native MediQuo iOS SDK.'
  s.description      = <<-DESC
A federated Flutter plugin that bridges the native MediQuo iOS SDK
(chat, video calls and the professional list).
                       DESC
  s.homepage         = 'https://mediquo.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'MediQuo' => 'support@mediquo.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'mediquo_flutter/Sources/mediquo_flutter/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '17.0'

  # The MediQuo iOS SDK is distributed only as a binary XCFramework (via Swift
  # Package Manager). Fetching and vendoring it here lets CocoaPods-based apps
  # use the plugin without enabling Flutter SPM. The archive is pinned to the
  # same version as Package.swift, checksum-verified, and skipped once present.
  s.prepare_command = <<-CMD
    set -e
    ARCHIVE="MediQuoSDK.xcframework.zip"
    URL="https://github.com/mediquo/mediquo-ios-sdk/releases/download/26.1.2/MediQuoSDK.xcframework.zip"
    CHECKSUM="c998ca327e181ab488563e6f0cecf2eca83b62eba35044e03d4e5c750c3710f6"
    if [ ! -f "MediQuoSDK.xcframework/Info.plist" ]; then
      curl -fL --retry 3 -o "${ARCHIVE}" "${URL}"
      echo "${CHECKSUM}  ${ARCHIVE}" | shasum -a 256 -c -
      rm -rf "MediQuoSDK.xcframework"
      unzip -q -o "${ARCHIVE}"
      rm -f "${ARCHIVE}"
    fi
  CMD
  s.vendored_frameworks = 'MediQuoSDK.xcframework'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_VERSION' => '5.0'
  }
end
