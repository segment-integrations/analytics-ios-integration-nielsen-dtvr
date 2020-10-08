Pod::Spec.new do |s|
    s.name          = 'Segment-Nielsen-DTVR'
    s.version       = '0.0.6'
    s.summary       = 'Nielsen DTVR Integration for Segment'
    s.description   = <<-DESC
    Analytics for iOS. This is the Nielsen DTVR integration for the iOS library.
                        DESC
    s.homepage      = 'http://segment.com/'
    s.author        = { 'Segment' => 'friends@segment.com' }
    s.license       = { :type => 'MIT', :file => 'LICENSE' }
    s.source        = { :git => 'https://github.com/segment-integrations/analytics-ios-integration-nielsen-dtvr.git', :tag => s.version.to_s }
    s.social_media_url  = 'https://twitter.com/segment'
    s.ios.deployment_target = '8.0'
    s.preserve_paths = 'Segment-Nielsen-DTVR/Classes/**/*'
    s.dependency 'Analytics'
end
