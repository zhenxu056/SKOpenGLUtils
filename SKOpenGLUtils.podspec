#
# Be sure to run `pod lib lint MGMediaPlay.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SKOpenGLUtils'
  s.version          = '1.0.0'
  s.summary          = 'A short description of SKOpenGLUtils.'
 
  s.description      = <<-DESC
TODO: Add long description of the pod here. 
                       DESC

  s.homepage         = 'https://github.com/zhenxu056/SKOpenGLUtils'
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sunflower' => '737860916@qq.com' }
  s.source           = { :git => 'https://github.com/zhenxu056/SKOpenGLUtils.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '9.0'
  s.source_files = 'SKOpenGLUtils/Classes/**/*'
  s.public_header_files = 'SKOpenGLUtils/Classes/**/*.h'
#  s.resources = "SKOpenGLUtils/Assets/*"
  
  s.resource_bundles = {
      'MGTEDAsset' => ['SKOpenGLUtils/Assets/*']
  }
  
  
end



