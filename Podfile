# Uncomment the next line to define a global platform for your project
# platform :ios, '18.0'

target 'WorldAuth' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for WorldAuth
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseRemoteConfig'
  pod 'LibTorch-Lite'
#  pod 'MyLibtorch', :path => 'MyLibtorch.podspec'

  
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      if target.name == 'MyLibtorch'
        target.build_configurations.each do |config|
          config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++17'
          config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
          config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
      end
    end
  end

end
