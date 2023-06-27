platform :ios, '13.0'

target 'SealdSDK demo app ios swift' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for go-sdk-demo-app-ios-swift
  pod 'SealdSdk', '0.1.0-beta.52543'
  pod 'JWT', '3.0.0-beta.3'
  pod 'Base64'

  target 'SealdSDK demo app ios swiftTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'SealdSDK demo app ios swiftUITests' do
    # Pods for testing
  end

  post_install do |installer|
    installer.generated_projects.each do |project|
      project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        end
      end
    end
  end
end
