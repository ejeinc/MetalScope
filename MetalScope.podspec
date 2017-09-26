Pod::Spec.new do |s|
  s.name = 'MetalScope'
  s.version = '0.16.0'
  s.summary = 'Metal-backed 360° panorama view for iOS'

  s.homepage = 'https://github.com/ejeinc/MetalScope'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = 'eje Inc.'
  s.source = { :git => 'https://github.com/ejeinc/MetalScope.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'Sources/**/*.swift'
  s.resources = 'Sources/**/*.xcassets'
end
